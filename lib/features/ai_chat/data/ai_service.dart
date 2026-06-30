import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/ai_config.dart';
import '../../../core/state/article_cache.dart';
import '../../../features/feed/data/rss_sources.dart';
import '../../../features/feed/domain/entities/article.dart';

class AiService {
  AiService(this._ref);
  final Ref _ref;

  Future<String> reply(String userMessage) async {
    final config = _ref.read(aiConfigProvider);
    if (config.apiKey.trim().isNotEmpty) {
      try {
        return await _callLlm(userMessage, config);
      } catch (_) {
        return _localReply(userMessage);
      }
    }
    await Future.delayed(const Duration(milliseconds: 500));
    return _localReply(userMessage);
  }

  String _localReply(String message) {
    final cache = _ref.read(articleCacheProvider);
    final articles = cache.values.toList();
    final lower = message.toLowerCase();

    if (RegExp(r'今日|今天|最新|要闻|热点|新闻').hasMatch(message)) {
      return _localHighlights(articles);
    }

    if (RegExp(r'推荐|订阅|源|rss|关注').hasMatch(lower)) {
      return _localRecommendSources();
    }

    if (RegExp(r'亮点|头条|精选|重要').hasMatch(message)) {
      return _localHighlights(articles);
    }

    if (RegExp(r'总结|摘要|分析|洞察|趋势|insight|digest').hasMatch(message)) {
      return _localInsight(articles);
    }

    if (RegExp(r'黄金|贵金属|金价|白银|行情|金属|gold|metal').hasMatch(lower)) {
      return '关于贵金属行情，建议前往「市场 → 贵金属行情」查看实时金价和银价数据。';
    }

    if (RegExp(r'模型|API|排行榜|ai模型|hugging').hasMatch(lower)) {
      return '想了解最新 AI 模型排名？前往「市场 → AI 排行」查看 HuggingFace 趋势模型榜单。';
    }

    final matched = articles.where((a) {
      return a.title.toLowerCase().contains(lower) ||
          (a.summary?.toLowerCase().contains(lower) ?? false) ||
          a.feedName.toLowerCase().contains(lower);
    }).take(3).toList();

    if (matched.isEmpty) {
      return '我在当前已加载的文章中没找到与「$message」直接相关的内容。\n\n'
          '你可以：\n'
          '• 换个关键词再试\n'
          '• 在信息流下拉加载更多文章\n'
          '• 问我「今日要闻」或「推荐订阅源」';
    }

    final lines = matched.map((a) =>
        '【${a.feedName}】${a.title}${a.summary != null ? '\n  ${a.summary}' : ''}');
    return '找到 ${matched.length} 篇与「$message」相关的文章：\n\n${lines.join('\n\n')}';
  }

  String _localHighlights(List<Article> articles) {
    if (articles.isEmpty) {
      return '当前还没有加载文章，请先在「信息流」下拉刷新加载内容，我就能为你整理要闻了。';
    }
    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final top = sorted.take(5).toList();
    final buf = StringBuffer('📰 **今日新闻亮点**\n\n');
    for (var i = 0; i < top.length; i++) {
      final a = top[i];
      buf.writeln('${i + 1}. **【${a.feedName}】** ${a.title}');
      if (a.summary != null) {
        buf.writeln('   > ${a.summary}');
      }
      buf.writeln();
    }
    buf.write('---\n需要我详细解读某条新闻吗？或问我「总结趋势」获取今日洞察。');
    return buf.toString();
  }

  String _localInsight(List<Article> articles) {
    if (articles.length < 3) {
      return '文章不足，无法生成洞察。请先在信息流加载更多内容。';
    }
    final bySource = <String, List<Article>>{};
    for (final a in articles) {
      bySource.putIfAbsent(a.feedName, () => []).add(a);
    }
    final activeSources = bySource.entries
        .where((e) => e.value.isNotEmpty)
        .map((e) => '• **${e.key}**（${e.value.length} 篇）')
        .join('\n');

    final sorted = List<Article>.from(articles)
      ..sort((a, b) {
        final ta = a.publishedAt ?? DateTime(2000);
        final tb = b.publishedAt ?? DateTime(2000);
        return tb.compareTo(ta);
      });
    final latest = sorted.take(3).map((a) =>
        '• **${a.feedName}**：${a.title}').join('\n');

    final categories = <String, int>{};
    for (final a in articles) {
      categories[a.feedName] = (categories[a.feedName] ?? 0) + 1;
    }
    final sortedCats = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCat = sortedCats.isNotEmpty ? sortedCats.first.key : '科技';

    return '📊 **今日内容洞察**\n\n'
        '**活跃来源**\n$activeSources\n\n'
        '**最新动态**\n$latest\n\n'
        '**热度分析**\n'
        '• 今日最活跃来源：**$topCat**\n'
        '• 共收录 ${articles.length} 篇文章\n'
        '• 覆盖 ${bySource.length} 个来源\n\n'
        '---\n前往「信息流」查看更多内容，或问我具体话题。';
  }

  String _localRecommendSources() {
    final groups = <String, List<String>>{};
    for (final s in RssSources.all) {
      groups.putIfAbsent(s.category.label, () => [])
          .add('${s.name}（${s.description}）');
    }
    final buf = StringBuffer('这里有一些优质订阅源推荐：\n\n');
    groups.forEach((cat, list) {
      buf.writeln('【$cat】');
      for (final l in list) {
        buf.writeln('· $l');
      }
      buf.writeln();
    });
    buf.write('前往「信息流 → 订阅管理」即可添加这些源。');
    return buf.toString();
  }

  Future<String> _callLlm(String userMessage, AiConfigState config) async {
    final dio = Dio(BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Authorization': 'Bearer ${config.apiKey}',
        'Content-Type': 'application/json',
      },
    ));

    final cache = _ref.read(articleCacheProvider);
    final context = cache.values.take(15).map((a) =>
        '- 【${a.feedName}】${a.title}${a.summary != null ? '：${a.summary}' : ''}')
        .join('\n');

    final resp = await dio.post<Map<String, dynamic>>(
      '/chat/completions',
      data: {
        'model': config.model,
        'messages': [
          {
            'role': 'system',
            'content': '你是 InfoFlow 的 AI 助手，帮用户总结和回答关于订阅内容的问题。'
                '以下是用户最近订阅的文章，回答时可参考：\n$context'
          },
          {'role': 'user', 'content': userMessage},
        ],
        'temperature': 0.7,
      },
    );

    final choices = resp.data?['choices'] as List?;
    if (choices == null || choices.isEmpty) {
      throw Exception('LLM 返回为空');
    }
    final content = choices.first['message']?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('LLM 返回内容为空');
    }
    return content.trim();
  }
}

final aiServiceProvider = Provider<AiService>((ref) => AiService(ref));
