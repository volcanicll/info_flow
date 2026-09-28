import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/market_repository.dart';
import '../../data/price_alert_store.dart';
import '../../domain/models/price_alert.dart';

/// 价格提醒管理：按指定价格或自基线涨跌幅监控代币行情，命中即推送。
///
/// 行情源为 Binance 现货（{symbol}USDT），触发语义一次性：
/// 命中后自动停用，可重新启用（涨跌幅类以当时现价重建基线）。
/// 查询参数 symbol 用于币详情页带币种直达。
class PriceAlertsPage extends ConsumerStatefulWidget {
  final String? initialSymbol;

  const PriceAlertsPage({super.key, this.initialSymbol});

  @override
  ConsumerState<PriceAlertsPage> createState() => _PriceAlertsPageState();
}

class _PriceAlertsPageState extends ConsumerState<PriceAlertsPage> {
  late final TextEditingController _symbolCtrl;
  final _valueCtrl = TextEditingController();
  PriceAlertKind _kind = PriceAlertKind.priceAbove;
  bool _submitting = false;

  static const _kinds = [
    (PriceAlertKind.priceAbove, '涨破'),
    (PriceAlertKind.priceBelow, '跌破'),
    (PriceAlertKind.changeUp, '涨幅≥'),
    (PriceAlertKind.changeDown, '跌幅≥'),
  ];

  @override
  void initState() {
    super.initState();
    _symbolCtrl = TextEditingController(text: widget.initialSymbol ?? '');
  }

  @override
  void dispose() {
    _symbolCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  bool get _isPriceKind =>
      _kind == PriceAlertKind.priceAbove ||
      _kind == PriceAlertKind.priceBelow;

  Future<void> _submit() async {
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    final value = double.tryParse(_valueCtrl.text.trim());
    final error = validatePriceAlertDraft(
      symbol: symbol,
      kind: _kind,
      targetPrice: _isPriceKind ? value : null,
      changePct: _isPriceKind ? null : value,
    );
    if (error != null) {
      _toast(error);
      return;
    }
    setState(() => _submitting = true);
    try {
      // 现价两个用途：校验 Binance 是否收录（否则规则永远不会触发），
      // 以及涨跌幅类的基线
      final prices =
          await ref.read(marketRepositoryProvider).fetchLastPrices([symbol]);
      final price = prices[symbol];
      if (price == null) {
        _toast('Binance 未收录 $symbol 现货，暂无法监控');
        return;
      }
      final alert = ref.read(priceAlertStoreProvider.notifier).add(
            symbol: symbol,
            kind: _kind,
            targetPrice: _isPriceKind ? value : null,
            changePct: _isPriceKind ? null : value,
            baselinePrice: price,
          );
      if (alert == null) {
        _toast('创建失败，请检查输入');
        return;
      }
      _valueCtrl.clear();
      _toast('已创建：${priceAlertDescription(alert)}');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  /// 重新启用：涨跌幅类需现价重建基线；拿不到现价时不启用，避免以
  /// 过期基线瞬间误触发。
  Future<void> _reArm(PriceAlert alert) async {
    double? price;
    if (alert.kind == PriceAlertKind.changeUp ||
        alert.kind == PriceAlertKind.changeDown) {
      final prices =
          await ref.read(marketRepositoryProvider).fetchLastPrices([
        alert.symbol,
      ]);
      price = prices[alert.symbol];
      if (price == null) {
        _toast('获取 ${alert.symbol} 现价失败，请稍后再试');
        return;
      }
    }
    await ref.read(priceAlertStoreProvider.notifier).reArm(
          alert.id,
          currentPrice: price,
        );
    _toast('已重新启用：${priceAlertDescription(alert)}');
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final alerts = ref.watch(priceAlertStoreProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
              child: Row(
                children: [
                  IconBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRICE ALERT · 价格监控',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: c.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text('价格提醒', style: theme.textTheme.displayMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Hairline(color: c.hairlineStrong),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  const SectionHeader(
                    kicker: 'NEW RULE · 新建',
                    title: '新建提醒',
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: _buildForm(theme, c),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Text(
                      '仅支持 Binance 现货上架币种；触发一次后自动停用，'
                      '涨跌幅以创建/重新启用时的现价为基线。',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: c.inkTertiary,
                      ),
                    ),
                  ),
                  const SectionHeader(
                    kicker: 'RULES · 我的规则',
                    title: '提醒规则',
                  ),
                  if (alerts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Text(
                        '暂无规则，先在上方新建一条',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: c.inkTertiary),
                      ),
                    )
                  else
                    for (final a in alerts)
                      _AlertRow(
                        alert: a,
                        onToggle: (on) => on ? _reArm(a) : _pause(a),
                        onDelete: () async {
                          await ref
                              .read(priceAlertStoreProvider.notifier)
                              .remove(a.id);
                        },
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pause(PriceAlert alert) async {
    await ref
        .read(priceAlertStoreProvider.notifier)
        .setEnabled(alert.id, enabled: false);
  }

  Widget _buildForm(ThemeData theme, AppColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: c.hairlineStrong, width: 0.6),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _symbolCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTheme.mono(theme.textTheme.bodyLarge!),
                  decoration: const InputDecoration(
                    isDense: true,
                    labelText: '币种',
                    hintText: 'BTC',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _valueCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: AppTheme.mono(theme.textTheme.bodyLarge!),
                  decoration: InputDecoration(
                    isDense: true,
                    labelText: _isPriceKind ? '目标价格 (USDT)' : '幅度 (%)',
                    hintText: _isPriceKind ? '如 65000' : '如 5',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              for (final (kind, label) in _kinds)
                _KindTab(
                  label: label,
                  active: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_alarm_rounded, size: 18),
              label: const Text('添加提醒'),
            ),
          ),
        ],
      ),
    );
  }
}

/// 触发方式选择：文本 + 编辑红下划线（与全局主题切换控件同语言）。
class _KindTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _KindTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return PressScale(
      pressedScale: 0.94,
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: active ? c.ink : c.inkTertiary,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            width: 18,
            height: 2,
            color: active ? c.accent : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

/// 单条规则行：描述 + 状态说明 + 暂停开关 + 删除。
class _AlertRow extends StatelessWidget {
  final PriceAlert alert;
  final ValueChanged<bool> onToggle;
  final Future<void> Function() onDelete;

  const _AlertRow({
    required this.alert,
    required this.onToggle,
    required this.onDelete,
  });

  String get _status {
    if (alert.enabled) return '监控中';
    if (alert.triggeredAt != null) return '已触发，打开开关可重新启用';
    return '已暂停';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final createdAt =
        '${alert.createdAt.month.toString().padLeft(2, '0')}-'
        '${alert.createdAt.day.toString().padLeft(2, '0')} '
        '${alert.createdAt.hour.toString().padLeft(2, '0')}:'
        '${alert.createdAt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        priceAlertDescription(alert),
                        style: AppTheme.mono(
                          theme.textTheme.titleSmall!.copyWith(
                            color: alert.enabled ? c.ink : c.inkTertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '$createdAt · $_status',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: alert.enabled ? c.inkSecondary : c.inkTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(value: alert.enabled, onChanged: onToggle),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: c.inkTertiary,
                  tooltip: '删除',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
          Hairline(color: c.hairline),
        ],
      ),
    );
  }
}
