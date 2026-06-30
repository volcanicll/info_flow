import '../../features/feed/domain/entities/article.dart';

class NewsNormalizer {

  static Set<String> _tokenize(String text) {
    final cleaned = text
        .replaceAll(RegExp(r'[!?.,。！？，：:、\[\]【】]'), ' ')
        .trim();
    final tokens = <String>{};
    for (final part in cleaned.split(RegExp(r'\s+'))) {
      if (part.isEmpty) continue;
      if (RegExp(r'[一-龥]').hasMatch(part)) {
        for (final ch in part.runes) {
          final char = String.fromCharCode(ch);
          if (RegExp(r'[一-龥]').hasMatch(char)) tokens.add(char);
        }
      } else {
        tokens.add(part.toLowerCase());
      }
    }
    return tokens;
  }

  static double jaccardSimilarity(String a, String b) {
    final sa = _tokenize(a);
    final sb = _tokenize(b);
    if (sa.isEmpty || sb.isEmpty) return 0;
    double inter = 0;
    for (final t in sa) {
      if (sb.contains(t)) inter++;
    }
    final union = sa.length + sb.length - inter;
    return union == 0 ? 0 : inter / union;
  }

  static List<Article> dedupe(List<Article> items, {double threshold = 0.7}) {
    final result = <Article>[];
    final seenUrls = <String>{};
    final seenTitles = <String>[];

    for (final a in items) {
      final urlKey = a.url.isEmpty ? a.title : a.url;
      if (urlKey.isNotEmpty && seenUrls.contains(urlKey)) continue;
      seenUrls.add(urlKey);
      bool isDup = false;
      for (final t in seenTitles) {
        if (jaccardSimilarity(a.title, t) >= threshold) {
          isDup = true;
          break;
        }
      }
      if (!isDup) {
        seenTitles.add(a.title);
        result.add(a);
      }
    }
    return result;
  }
}
