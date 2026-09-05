import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'datasources/rht_api.dart';
import 'models/rht_models.dart';

/// 实盘 Tape 连接状态。
enum RhtTapeConn { connecting, live, polling, offline }

/// robinhoodtrenches.com 实盘 Tape 流：WS 为主，轮询兜底。
///
/// 完整复刻上游站点的韧性策略（均已在其生产环境验证）：
/// - WS `/ws`：`hello` 携带索引器状态，`fills` 推送新成交，20s 心跳 `'p'`；
/// - WS 4s 未建立或连续断开 ≥2 次 → 降级 2.5s 轮询 `/api/tape?since_id=游标`；
/// - 断线后以 2–6s 随机抖动重试 WS，成功后自动停掉轮询；
/// - [resync] 供 App 回前台时调用：断线期间用 since_id 增量补拉，不丢成交。
class RhtTapeStream {
  RhtTapeStream({
    required RhtApi api,
    required void Function(RhtStatus status) onHello,
    required void Function(List<RhtFill> fills) onFills,
    required void Function(RhtTapeConn conn) onConn,
  })  : _api = api,
        _onHello = onHello,
        _onFills = onFills,
        _onConn = onConn;

  final RhtApi _api;
  final void Function(RhtStatus) _onHello;
  final void Function(List<RhtFill>) _onFills;
  final void Function(RhtTapeConn) _onConn;

  WebSocketChannel? _ws;
  StreamSubscription<dynamic>? _wsSub;
  Timer? _ping;
  Timer? _poll;
  Timer? _retry;
  Timer? _openTimeout;

  int _lastId = 0;
  int _failures = 0;
  bool _openedOnce = false;
  bool _disposed = false;
  RhtTapeConn _conn = RhtTapeConn.connecting;

  static Uri wsUriFor(String baseUrl) {
    final base = Uri.parse(baseUrl);
    return base.replace(
      scheme: base.scheme == 'http' ? 'ws' : 'wss',
      path: '/ws',
    );
  }

  Uri get _wsUri => wsUriFor(_api.baseUrl);

  static const _pollInterval = Duration(milliseconds: 2500);
  static const _pingInterval = Duration(seconds: 20);

  /// 首次连接：REST 回填 400 条建立游标，然后启动 WS。
  Future<void> start() async {
    if (_disposed) return;
    _setConn(RhtTapeConn.connecting);
    try {
      final backfill = await _api.tape(limit: 400);
      if (_disposed) return;
      if (backfill.isNotEmpty) {
        backfill.sort((a, b) => b.id.compareTo(a.id));
        _lastId = backfill.first.id;
        _onFills(backfill);
      }
    } catch (_) {
      // 回填失败不阻塞连接：WS hello / 轮询仍会带数据进来
    }
    if (_disposed) return;
    _connect();
  }

  void _connect() {
    if (_disposed) return;
    _teardownSocket();
    _setConn(_openedOnce ? RhtTapeConn.polling : RhtTapeConn.connecting);
    WebSocketChannel? ws;
    try {
      ws = WebSocketChannel.connect(_wsUri);
    } catch (_) {
      _scheduleRetry();
      return;
    }
    _ws = ws;
    // 4s 未完成升级 → 判定失败走轮询（上游同款超时）
    _openTimeout?.cancel();
    _openTimeout = Timer(const Duration(seconds: 4), () {
      if (!_openedOnce && _conn != RhtTapeConn.live) _startPolling();
    });

    _wsSub = ws.stream.listen(
      (data) {
        if (!_openedOnce) {
          _openedOnce = true;
          _failures = 0;
          _stopPolling();
          _openTimeout?.cancel();
          _setConn(RhtTapeConn.live);
          _startPing();
        }
        _handleMessage(data);
      },
      onError: (_) => _onClosed(),
      onDone: _onClosed,
      cancelOnError: true,
    );
  }

  void _startPing() {
    _ping?.cancel();
    _ping = Timer.periodic(_pingInterval, (_) {
      try {
        _ws?.sink.add('p');
      } catch (_) {}
    });
  }

  void _handleMessage(dynamic data) {
    if (data is! String) return;
    Object? decoded;
    try {
      decoded = jsonDecode(data);
    } catch (_) {
      return;
    }
    if (decoded is! Map) return;
    final map = Map<String, dynamic>.from(decoded);
    switch (map['type']) {
      case 'hello':
        final payload = map['data'];
        if (payload is Map<String, dynamic>) {
          _onHello(RhtStatus.fromJson(payload));
        }
      case 'fills':
        final payload = map['data'];
        if (payload is List) {
          final fills = payload
              .whereType<Map<String, dynamic>>()
              .map(RhtFill.fromJson)
              .toList()
            ..sort((a, b) => b.id.compareTo(a.id));
          if (fills.isEmpty) return;
          if (fills.first.id > _lastId) _lastId = fills.first.id;
          _onFills(fills);
        }
    }
  }

  void _onClosed() {
    _ping?.cancel();
    _ping = null;
    _ws = null;
    _failures++;
    // 未曾成功建立或连续失败过多：轮询兜底，避免 tape 冻结（上游同款策略）
    if (!_openedOnce || _failures >= 2) _startPolling();
    _setConn(_poll != null ? RhtTapeConn.polling : RhtTapeConn.offline);
    _scheduleRetry();
  }

  void _scheduleRetry() {
    if (_disposed || _retry != null) return;
    final jitter = 2000 + Random().nextInt(4000);
    _retry = Timer(Duration(milliseconds: jitter), () {
      _retry = null;
      _connect();
    });
  }

  void _startPolling() {
    if (_disposed || _poll != null) return;
    _setConn(RhtTapeConn.polling);
    _poll = Timer.periodic(_pollInterval, (_) => _pollOnce());
    _pollOnce();
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _pollOnce() async {
    try {
      final rows =
          await _api.tape(limit: 60, sinceId: _lastId > 0 ? _lastId : null);
      if (_disposed) return;
      rows.sort((a, b) => b.id.compareTo(a.id));
      if (rows.isNotEmpty) {
        if (rows.first.id > _lastId) _lastId = rows.first.id;
        _onFills(rows);
      }
      if (_conn == RhtTapeConn.offline) _setConn(RhtTapeConn.polling);
    } catch (_) {
      _setConn(RhtTapeConn.offline);
    }
  }

  void _teardownSocket() {
    _openTimeout?.cancel();
    _ping?.cancel();
    _ping = null;
    _wsSub?.cancel();
    _wsSub = null;
    try {
      _ws?.sink.close();
    } catch (_) {}
    _ws = null;
  }

  void _setConn(RhtTapeConn c) {
    if (_conn == c) return;
    _conn = c;
    _onConn(c);
  }

  /// App 回前台：增量补拉断线期间的成交，必要时重连 WS。
  Future<void> resync() async {
    if (_disposed) return;
    await _pollOnce();
    if (_disposed) return;
    if (_conn != RhtTapeConn.live) {
      _retry?.cancel();
      _retry = null;
      _connect();
    }
  }

  void dispose() {
    _disposed = true;
    _teardownSocket();
    _poll?.cancel();
    _retry?.cancel();
  }
}
