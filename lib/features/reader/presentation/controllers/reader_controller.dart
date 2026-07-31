import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:info_flow/core/storage/kv_storage.dart';

part 'reader_controller.g.dart';

/// 阅读视图状态：模式（阅读/原文）、字号、行高、纸底、滚动进度。
class ReaderViewState {
  /// true = 原生阅读模式，false = 网页原文。
  final bool isNativeMode;
  final double fontSize;
  final double lineHeight;

  /// 纸底配色索引（0=纸白，其余见阅读设置面板的纸底选项）。
  final int paperIndex;

  /// 滚动阅读进度 0~1。
  final double progress;

  const ReaderViewState({
    this.isNativeMode = true,
    this.fontSize = 17,
    this.lineHeight = 1.75,
    this.paperIndex = 0,
    this.progress = 0,
  });

  ReaderViewState copyWith({
    bool? isNativeMode,
    double? fontSize,
    double? lineHeight,
    int? paperIndex,
    double? progress,
  }) {
    return ReaderViewState(
      isNativeMode: isNativeMode ?? this.isNativeMode,
      fontSize: fontSize ?? this.fontSize,
      lineHeight: lineHeight ?? this.lineHeight,
      paperIndex: paperIndex ?? this.paperIndex,
      progress: progress ?? this.progress,
    );
  }
}

/// 阅读页视图控制器：集中管理正文页的模式/排版/进度状态。
///
/// 字号初始值取全局 [fontSizeProvider]（用户偏好），调整时回写持久化。
@riverpod
class ReaderController extends _$ReaderController {
  @override
  ReaderViewState build() {
    final fontSize = ref.read(fontSizeProvider);
    return ReaderViewState(fontSize: fontSize);
  }

  void setNativeMode(bool isNative) {
    state = state.copyWith(isNativeMode: isNative);
  }

  void setFontSize(double size) {
    final clamped = size.clamp(12.0, 24.0);
    state = state.copyWith(fontSize: clamped);
    ref.read(fontSizeProvider.notifier).setFontSize(clamped);
  }

  void setLineHeight(double h) {
    state = state.copyWith(lineHeight: h.clamp(1.3, 2.2));
  }

  void setPaperIndex(int index) {
    state = state.copyWith(paperIndex: index);
  }

  void setProgress(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    if ((state.progress - clamped).abs() > 0.005) {
      state = state.copyWith(progress: clamped);
    }
  }
}
