import 'package:flutter/material.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../token_screener/domain/models/onchain_token.dart';

/// 链上安全体检卡片 (GoPlus)。
class SecurityCard extends StatelessWidget {
  final TokenSecurity security;
  const SecurityCard({super.key, required this.security});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    final riskColor = Color(security.riskLevel.colorValue);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: riskColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: riskColor),
              const SizedBox(width: 8),
              Text(
                '综合安全评分: ${security.score}/100',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: riskColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  security.riskLevel.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 安全属性网格
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CheckItem(
                label: '貔貅限制',
                value: security.isHoneypot ? '🚨 无法卖出' : '✅ 正常交易',
                isAlert: security.isHoneypot,
              ),
              CheckItem(
                label: '买/卖税率',
                value:
                    '${security.buyTax.toStringAsFixed(1)}% / ${security.sellTax.toStringAsFixed(1)}%',
                isAlert: security.buyTax > 10 || security.sellTax > 10,
              ),
              CheckItem(
                label: '增发权限',
                value: security.isMintable ? '⚠️ 存在增发' : '✅ 已放弃',
                isAlert: security.isMintable,
              ),
              CheckItem(
                label: 'Top10集中度',
                value: '${security.top10HolderPercent.toStringAsFixed(1)}%',
                isAlert: security.top10HolderPercent > 70,
              ),
            ],
          ),
          if (security.warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            Hairline(color: riskColor.withValues(alpha: 0.2)),
            const SizedBox(height: 8),
            for (final w in security.warnings)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  w,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: c.inkSecondary,
                    fontSize: 11.5,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class CheckItem extends StatelessWidget {
  final String label;
  final String value;
  final bool isAlert;

  const CheckItem({
    super.key,
    required this.label,
    required this.value,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: c.inkTertiary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isAlert ? c.down : c.ink,
          ),
        ),
      ],
    );
  }
}

class MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const MetricItem({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTheme.mono(
            theme.textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// 迷你折线图：值序列归一化绘制，端点标色。
class SparklineChart extends StatelessWidget {
  final List<double> values;
  final bool up;
  const SparklineChart({super.key, required this.values, required this.up});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return CustomPaint(
      painter: _SparklinePainter(
        values: values,
        color: up ? c.up : c.down,
        hairline: c.hairline,
      ),
      size: Size.infinite,
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;
  final Color color;
  final Color hairline;

  _SparklinePainter({
    required this.values,
    required this.color,
    required this.hairline,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2 || size.width <= 0 || size.height <= 0) return;

    var minV = values.first, maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }
    if (maxV == minV) {
      maxV = minV + 1;
    }

    final midPaint = Paint()
      ..color = hairline
      ..strokeWidth = 0.5;
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      midPaint,
    );

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = size.width * i / (values.length - 1);
      final y = size.height -
          (values[i] - minV) / (maxV - minV) * (size.height - 8) -
          4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final line = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path, fill);
    canvas.drawPath(path, line);

    final last = values.length - 1;
    canvas.drawCircle(
      Offset(
        size.width * last / (values.length - 1),
        size.height -
            (values[last] - minV) / (maxV - minV) * (size.height - 8) -
            4,
      ),
      2.4,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values || old.color != color;
}

/// 费率柱状图：正负分区着色，首末标注。
class BarChartWidget extends StatelessWidget {
  final List<double> values;
  final String Function(double) format;
  final Color positiveColor;
  final Color negativeColor;
  const BarChartWidget({
    super.key,
    required this.values,
    required this.format,
    required this.positiveColor,
    required this.negativeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    var maxAbs = 0.0;
    for (final v in values) {
      if (v.abs() > maxAbs) maxAbs = v.abs();
    }
    if (maxAbs == 0) maxAbs = 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 60,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < values.length; i++) ...[
                Expanded(
                  child: Container(
                    height: 60,
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      heightFactor: (values[i].abs() / maxAbs).clamp(0.04, 1.0),
                      widthFactor: 0.55,
                      child: Container(
                        decoration: BoxDecoration(
                          color: values[i] >= 0 ? positiveColor : negativeColor,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < values.length - 1) const SizedBox(width: 3),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              format(values.first),
              style: theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary),
            ),
            Text(
              format(values.last),
              style: theme.textTheme.labelSmall?.copyWith(color: c.inkTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
