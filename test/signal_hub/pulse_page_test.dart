import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/signal_hub/presentation/controllers/pulse_controller.dart';
import 'package:info_flow/features/signal_hub/presentation/pages/pulse_page.dart';

void main() {
  testWidgets('文章为空时显示空态文案', (tester) async {
    // 直接 override pulseControllerProvider 返回 empty state，
    // 避免触发 articleCacheProvider → feedControllerProvider 的网络请求。
    final container = ProviderContainer(overrides: [
      pulseControllerProvider.overrideWith(() => _EmptyPulseController()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      // PulsePage 自身已含 Scaffold + RefreshIndicator
      child: const MaterialApp(home: PulsePage()),
    ));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('稍后'), findsWidgets);
  });
}

/// 始终返回 empty PulseState 的测试用控制器。
class _EmptyPulseController extends PulseController {
  @override
  PulseState build() => PulseState.empty;
}
