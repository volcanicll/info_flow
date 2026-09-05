import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:info_flow/features/market/presentation/controllers/fear_greed_controller.dart';
import 'package:info_flow/features/onchain_radar/data/onchain_radar_repository.dart';
import 'package:info_flow/features/onchain_radar/presentation/controllers/onchain_radar_controller.dart';
import 'package:info_flow/features/signal_hub/presentation/controllers/pulse_controller.dart';
import 'package:info_flow/features/signal_hub/presentation/pages/pulse_page.dart';

void main() {
  testWidgets('文章为空时显示空态文案', (tester) async {
    final container = ProviderContainer(overrides: [
      pulseControllerProvider.overrideWith(() => _EmptyPulseController()),
      fearGreedIndexProvider.overrideWith((ref) async => null),
      onChainRadarProvider.overrideWith(() => _FakeOnChainRadarNotifier()),
    ]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
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

class _FakeOnChainRadarNotifier extends OnChainRadarNotifier {
  @override
  OnChainRadarState build() =>
      OnChainRadarState(snapshot: RadarSnapshot.empty());
}
