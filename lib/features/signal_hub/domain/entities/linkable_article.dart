import 'ticker_ref.dart';

/// Signal Link 引擎的最小输入：仅保留关联所需的文章字段。
///
/// 刻意不依赖 `Article`（其依赖 `dart:ui`），使引擎保持纯 Dart、
/// 可脱离 Flutter VM 单元测试。
class LinkableArticle {
  final String id;
  final String title;
  final DateTime? publishedAt;
  final List<TickerRef> tickers;

  const LinkableArticle({
    required this.id,
    required this.title,
    this.publishedAt,
    this.tickers = const [],
  });
}
