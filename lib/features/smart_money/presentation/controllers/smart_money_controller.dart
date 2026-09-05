import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/network/api_client.dart';
import '../../data/datasources/fomo_api.dart';
import '../../data/models/rht_models.dart';
import '../../data/models/rht_position.dart';
import '../../data/models/rht_token.dart';
import '../../data/models/rht_trader.dart';
import '../../data/rht_tape_stream.dart';
import '../../data/smart_money_repository.dart';

part 'smart_money_controller.g.dart';

/// 页面内分段视图。
enum SmartTab { tape, traders, closed, flow, tokens }

/// 聪明钱页状态：tape 走 WS 实时流，统计/榜单走 15s 轮询。
class SmartMoneyState {
  final RhtTapeConn conn;
  final String? error;

  /// 实盘成交（新→旧），封顶 150 行防止列表无限增长。
  final List<RhtFill> fills;

  /// 最近一批到达的成交 id：UI 对这批行做「新到」高亮，
  /// 下一批到达后自动恢复普通样式。
  final Set<int> freshIds;

  final RhtStatus? status;
  final RhtOverview? overview;
  final SmartTab tab;
  final bool panelsLoading;
  final List<RhtTrader> traders;
  final List<RhtClosedPosition> closed;
  final List<RhtFlowChain> flows;
  final List<RhtTokenFlow> tokenFlows;

  /// 关键字过滤：匹配代币 symbol / 交易员 handle。
  final String filter;

  /// 大户榜时间窗：'24h' 用 robinhoodtrenches 榜（含胜率/仓位状态），
  /// '7d'/'30d'/'all' 用 fomoapi 跨链榜（fomoLeaders 非空即生效）。
  final String leaderboardWindow;
  final List<FomoLeaderEntry>? fomoLeaders;
  final bool fomoLeadersLoading;

  const SmartMoneyState({
    this.conn = RhtTapeConn.connecting,
    this.error,
    this.fills = const [],
    this.freshIds = const {},
    this.status,
    this.overview,
    this.tab = SmartTab.tape,
    this.panelsLoading = false,
    this.traders = const [],
    this.closed = const [],
    this.flows = const [],
    this.tokenFlows = const [],
    this.filter = '',
    this.leaderboardWindow = '24h',
    this.fomoLeaders,
    this.fomoLeadersLoading = false,
  });

  /// tape 是否有数据可展示。
  bool get hasTape => fills.isNotEmpty;

  SmartMoneyState copyWith({
    RhtTapeConn? conn,
    String? error,
    bool clearError = false,
    List<RhtFill>? fills,
    Set<int>? freshIds,
    RhtStatus? status,
    RhtOverview? overview,
    SmartTab? tab,
    bool? panelsLoading,
    List<RhtTrader>? traders,
    List<RhtClosedPosition>? closed,
    List<RhtFlowChain>? flows,
    List<RhtTokenFlow>? tokenFlows,
    String? filter,
    String? leaderboardWindow,
    List<FomoLeaderEntry>? fomoLeaders,
    bool clearFomoLeaders = false,
    bool? fomoLeadersLoading,
  }) {
    return SmartMoneyState(
      conn: conn ?? this.conn,
      error: clearError ? null : (error ?? this.error),
      fills: fills ?? this.fills,
      freshIds: freshIds ?? this.freshIds,
      status: status ?? this.status,
      overview: overview ?? this.overview,
      tab: tab ?? this.tab,
      panelsLoading: panelsLoading ?? this.panelsLoading,
      traders: traders ?? this.traders,
      closed: closed ?? this.closed,
      flows: flows ?? this.flows,
      tokenFlows: tokenFlows ?? this.tokenFlows,
      filter: filter ?? this.filter,
      leaderboardWindow: leaderboardWindow ?? this.leaderboardWindow,
      fomoLeaders: clearFomoLeaders ? null : (fomoLeaders ?? this.fomoLeaders),
      fomoLeadersLoading: fomoLeadersLoading ?? this.fomoLeadersLoading,
    );
  }
}

@riverpod
class SmartMoney extends _$SmartMoney {
  static const _maxRows = 150;

  SmartMoneyRepository get _repo => ref.read(smartMoneyRepositoryProvider);
  RhtTapeStream? _stream;
  Timer? _panelTimer;

  @override
  SmartMoneyState build() {
    ref.onDispose(_teardown);
    // build 返回后才能写 state（Riverpod 3 约束），连接与首拉都推迟一拍
    Future.microtask(() {
      if (!ref.mounted) return;
      _connectTape();
      _refreshPanels();
    });
    // 统计/榜单轻轮询，与上游站点节奏一致
    _panelTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshPanels(silent: true),
    );
    return const SmartMoneyState();
  }

  void _connectTape() {
    _stream?.dispose();
    _stream = RhtTapeStream(
      api: ref.read(rhtApiProvider),
      onHello: (s) {
        if (!ref.mounted) return;
        state = state.copyWith(status: s, clearError: true);
      },
      onFills: _mergeFills,
      onConn: (c) {
        if (!ref.mounted) return;
        state = state.copyWith(conn: c);
      },
    );
    _stream!.start();
  }

  void _mergeFills(List<RhtFill> incoming) {
    if (!ref.mounted) return;
    final merged = <int, RhtFill>{for (final f in state.fills) f.id: f};
    for (final f in incoming) {
      merged[f.id] = f;
    }
    final rows = merged.values.toList()
      ..sort((a, b) => b.id.compareTo(a.id));
    if (rows.length > _maxRows) rows.removeRange(_maxRows, rows.length);
    state = state.copyWith(
      fills: rows,
      freshIds: incoming.map((f) => f.id).toSet(),
      clearError: true,
    );
  }

  Future<void> _refreshPanels({bool silent = false}) async {
    if (!ref.mounted) return;
    if (!silent) state = state.copyWith(panelsLoading: true);
    try {
      // 终端首页常驻展示大户榜与跟单链，随总览一起刷新（与上游站点节奏一致）
      final results = await Future.wait([
        _repo.fetchOverview(),
        _repo.fetchTraders().catchError((_) => <RhtTrader>[]),
        _repo.fetchFlowChains().catchError((_) => <RhtFlowChain>[]),
      ]);
      if (!ref.mounted) return;
      state = state.copyWith(
        overview: results[0] as RhtOverview,
        traders: results[1] as List<RhtTrader>,
        flows: results[2] as List<RhtFlowChain>,
        clearError: true,
      );
    } catch (e) {
      if (!silent && ref.mounted) {
        state = state.copyWith(error: mapToAppException(e).message);
      }
    } finally {
      if (ref.mounted && !silent) {
        state = state.copyWith(panelsLoading: false);
      }
    }
  }

  /// 切换大户榜时间窗：24h 用 robinhoodtrenches 榜，
  /// 更长窗口用 fomoapi 跨链榜（免 key，IP 限流）。
  Future<void> setLeaderboardWindow(String window) async {
    if (state.leaderboardWindow == window) return;
    state = state.copyWith(
      leaderboardWindow: window,
      clearFomoLeaders: window == '24h',
      fomoLeadersLoading: window != '24h',
      clearError: true,
    );
    if (window == '24h') return;
    try {
      final rows = await ref.read(fomoApiProvider).leaderboard(window: window);
      if (ref.mounted) state = state.copyWith(fomoLeaders: rows);
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: mapToAppException(e).message);
    } finally {
      if (ref.mounted) state = state.copyWith(fomoLeadersLoading: false);
    }
  }

  /// 切换分段：目标榜单无数据或已过期 15s 时拉取。
  Future<void> setTab(SmartTab tab) async {
    if (state.tab == tab) return;
    state = state.copyWith(tab: tab, clearError: true);
    await _ensureTabData(tab);
  }

  Future<void> _ensureTabData(SmartTab tab) async {
    // traders / flows 随 _refreshPanels 常驻刷新，这里只补按需数据
    try {
      switch (tab) {
        case SmartTab.tape:
        case SmartTab.traders:
        case SmartTab.flow:
          return;
        case SmartTab.closed:
          if (state.closed.isNotEmpty) return;
          final rows = await _repo.fetchClosed();
          if (ref.mounted) state = state.copyWith(closed: rows);
        case SmartTab.tokens:
          if (state.tokenFlows.isNotEmpty) return;
          final rows = await _repo.fetchTokenFlows();
          if (ref.mounted) state = state.copyWith(tokenFlows: rows);
      }
    } catch (e) {
      if (ref.mounted) state = state.copyWith(error: mapToAppException(e).message);
    }
  }

  /// 下拉刷新 / 手动刷新：面板 + 当前分段数据。
  Future<void> refresh() async {
    await Future.wait([
      _refreshPanels(),
      _ensureTabData(state.tab),
    ]);
  }

  /// App 回前台：增量补拉断线期间成交 + 刷新面板。
  Future<void> resync() async {
    await _stream?.resync();
    await _refreshPanels(silent: true);
  }

  void setFilter(String value) {
    state = state.copyWith(filter: value);
  }

  void _teardown() {
    _panelTimer?.cancel();
    _panelTimer = null;
    _stream?.dispose();
    _stream = null;
  }
}
