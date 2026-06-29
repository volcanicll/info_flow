import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/state/ai_config.dart';
import '../../../core/state/article_cache.dart';
import '../../../features/feed/data/rss_sources.dart';
import '../../../features/feed/domain/entities/article.dart';

/// AI 回复服务
///
/// 优先级：配置了 API key → 调用真实 LLM（OpenAI 兼容接口）；
/// 否则 → 本地规则引擎，从已抓取文章检索组织回复。
class AiService {
  AiService(this._ref);
  final Ref _ref;

  /// 生成回复
  Future<String> reply(String userMessage) async {
    final config = _ref.read(aiConfigProvider);
    if (config.apiKey.trim().isNotEmpty) {
      try {
        return await _callLlm(userMessage, config);
      } catch (_) {
        // LLM 调用失败时回退本地规则
        return _localReply(userMessage);
      }
    }
    // 本地规则引擎模拟思考耗时
    await Future.delayed(const Duration(milliseconds: 500));
    return _localReply(userMessage);
  }

  // ============ 本地规则引擎 ============

  String _localReply(String message) {
    final cache = _ref.read(articleCacheProvider);
    final articles = cache.values.toList();
    final lower = message.toLowerCase();

    // 今日要闻 / 最新
    if (RegExp(r'今日|今天|最新|要闻|热点|新闻').hasMatch(message)) {
      if (articles.isEmpty) {
        return '当前还没有加载文章，请先在「信息流」下拉刷新加载内容，我就能为你整理要闻了。';
      }
      final latest = (List<Article>.from(articles)
            ..sort((a, b) {
              final ta = a.publishedAt ?? DateTime(2000);
              final tb = b.publishedAt ?? DateTime(2000);
              return tb.compareTo(ta);
            }))
          .take(5)
          .toList();
      final lines = latest.asMap().entries.map((e) {
        return '${e.key + 1}. 【${e.value.feedName}】${e.value.title}'
            '${e.value.summary != null ? '\n   ${e.value.summary}' : ''}';
      });
      return '基于你已订阅的来源，以下是最新要闻：\n\n${lines.join('\n\n')}\n\n需要我详细展开某一条吗？';
    }

    // 推荐订阅源
    if (RegExp(r'推荐|订阅|源|rss|关注').hasMatch(lower)) {
      final groups = <String, List<String>>{};
      for (final s in RssSources.all) {
        groups.putIfAbsent(s.category.label, () => []).add('${s.name}（${s.description}）');
      }
      final buf = StringBuffer('这里有一些优质订阅源推荐：\n\n');
      groups.forEach((cat, list) {
        buf.writeln('【$cat】');
        for (final l in list) {
          buf.writeln('· $l');
        }
        buf.writeln();
      });
      buf.write('前往「订阅管理」即可添加这些源。');
      return buf.toString();
    }

    // 关键词检索
    final matched = articles.where((a) {
      return a.title.toLowerCase().contains(lower) ||
          (a.summary?.toLowerCase().contains(lower) ?? false) ||
          a.feedName.toLowerCase().contains(lower);
    }).take(3).toList();

    if (matched.isEmpty) {
      return '我在当前已加载的文章中没找到与「$message」直接相关的内容。\n\n'
          '你可以：\n• 换个关键词再试\n• 在信息流下拉加载更多文章\n• 问我「今日要闻」或「推荐订阅源」';
    }

    final lines = matched.map((a) =>
        '【${a.feedName}】${a.title}${a.summary != null ? '\n  ${a.summary}' : ''}');
    return '找到 ${matched.length} 篇与「$message」相关的文章：\n\n${lines.join('\n\n')}';
  }

  // ============ 真实 LLM 调用 ============

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

    // 构造系统提示，附带已抓取文章作为上下文
    final cache = _ref.read(articleCacheProvider);
    final context = cache.values.take(15).map((a) =>
        '- 【${a.feedName}】${a.title}${a.summary != null ? '：${a.summary}' : ''}').join('\n');

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
