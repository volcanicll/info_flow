import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../feed/domain/entities/article.dart';
import '../domain/entities/ticker_ref.dart';
import 'ticker_dictionary.dart';

part 'ticker_resolver.g.dart';

@riverpod
TickerDictionary tickerDictionary(TickerDictionaryRef ref) {
  return TickerDictionary();
}

/// 标的识别引擎：基于本地词典的多模式子串匹配。
///
/// P0 路线：规则匹配（标题 + 正文小写化后逐别名计数）。
/// P1 可在此处增加「规则空命中 + 财经语境 → 调 LLM 回退」分支，不影响外部接口。
class TickerResolver {
  final TickerDictionary _dict;
  TickerResolver([TickerDictionary? dict])
      : _dict = dict ?? TickerDictionary();

  /// 识别文章涉及的所有标的，按 inTitle 优先、mentions 次之降序排列。
  List<TickerRef> resolve(Article article) {
    final title = _normalize(article.title);
    final body = _normalize(article.content ?? '');
    if (title.isEmpty && body.isEmpty) return const [];

    // symbol -> 累计数据
    final mentions = <String, int>{};
    final inTitle = <String, bool>{};
    final assetOf = <String, AssetClass>{};

    for (final e in _dict.entries) {
      final candidates = {
        e.symbol.toLowerCase(),
        ...e.aliases,
      };
      var count = 0;
      var hitTitle = false;
      for (final alias in candidates) {
        count += _countOccur(title, alias);
        if (_countOccur(title, alias) > 0) hitTitle = true;
        count += _countOccur(body, alias);
      }
      if (count > 0) {
        mentions[e.symbol] = (mentions[e.symbol] ?? 0) + count;
        inTitle[e.symbol] = (inTitle[e.symbol] ?? false) || hitTitle;
        assetOf[e.symbol] = e.asset;
      }
    }

    final refs = <TickerRef>[];
    mentions.forEach((sym, c) {
      refs.add(TickerRef(
        symbol: sym,
        asset: assetOf[sym]!,
        mentions: c,
        inTitle: inTitle[sym] ?? false,
      ));
    });
    refs.sort((a, b) {
      if (a.inTitle != b.inTitle) return a.inTitle ? -1 : 1;
      return b.mentions.compareTo(a.mentions);
    });
    return refs;
  }

  /// 批量识别：对一组文章分别 resolve，并返回带 tickers 的新 Article（不可变拷贝）。
  /// 原 Article 的已有 tickers 保留（不重复计算）。
  List<Article> resolveList(List<Article> articles) {
    return articles.map((a) {
      if (a.tickers.isNotEmpty) return a;
      final refs = resolve(a);
      if (refs.isEmpty) return a;
      return a.copyWith(tickers: refs);
    }).toList();
  }

  String _normalize(String s) => s.toLowerCase().trim();

  int _countOccur(String haystack, String needle) {
    if (needle.isEmpty) return 0;
    var count = 0;
    var idx = 0;
    while ((idx = haystack.indexOf(needle, idx)) != -1) {
      count++;
      idx += needle.length;
    }
    return count;
  }
}
