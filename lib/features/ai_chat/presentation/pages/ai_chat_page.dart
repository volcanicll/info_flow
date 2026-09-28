import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../data/ai_config.dart';
import '../../data/ai_models.dart';
import '../../../feed/presentation/controllers/article_cache.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../../shared/widgets/icon_btn.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../controllers/chat_controller.dart';
import '../widgets/chat_input_bar.dart';
import '../widgets/chat_message_view.dart';

/// AI 助手页（访谈排版）：受访者引述块 + 提问者右对齐，会话状态托管于
/// [ChatController]，本页仅负责编排与滚动。
class AiChatPage extends ConsumerStatefulWidget {
  const AiChatPage({super.key});

  @override
  ConsumerState<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends ConsumerState<AiChatPage> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send(String text) {
    ref.read(chatControllerProvider.notifier).send(text);
    _scrollToBottom();
  }

  void _sendCurrent() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    _inputController.clear();
    _send(text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(chatControllerProvider);
    final articleCount = ref.watch(articleCacheProvider).length;
    final aiCfg = ref.watch(aiConfigProvider);

    // 消息增减后滚到底部。
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev == null || next.messages.length != prev.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Masthead(
              theme: theme,
              kicker: _aiKicker(aiCfg),
              articleCount: articleCount,
              onSettings: () => _showSettings(context),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                itemCount: state.messages.length + (state.sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == state.messages.length) {
                    return const ChatTypingIndicator();
                  }
                  return ChatMessageView(message: state.messages[index]);
                },
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
                children: [
                  _QuickTag(label: '每日播报', onTap: () => _send('每日播报')),
                  _QuickTag(label: '聪明钱情报', onTap: () => _send('解读一下当前聪明钱（大户钱包）的动向和值得关注的信号')),
                  _QuickTag(label: '今日要闻', onTap: () => _send('今日要闻有哪些？')),
                  _QuickTag(label: '推荐订阅源', onTap: () => _send('推荐一些优质订阅源')),
                  _QuickTag(label: '趋势洞察', onTap: () => _send('总结一下今日趋势洞察')),
                  _QuickTag(label: '加密市场异动', onTap: () => _send('加密市场有什么异动？')),
                ],
              ),
            ),
            ChatInputBar(
              controller: _inputController,
              focusNode: _focusNode,
              sending: state.sending,
              onSend: _sendCurrent,
            ),
          ],
        ),
      ),
    );
  }

  /// 报头 kicker：反映当前 AI 接入方式（未配置 Key 时为本地规则）。
  String _aiKicker(AiConfigState cfg) {
    if (cfg.apiKey.trim().isEmpty) return 'AI 访谈 · 本地规则';
    return switch (cfg.provider) {
      AiProviderKind.openai => 'AI 访谈 · OpenAI 兼容',
      AiProviderKind.opencode => 'AI 访谈 · OpenCode Go',
    };
  }

  void _showSettings(BuildContext context) {
    final config = ref.read(aiConfigProvider);
    var provider = config.provider;
    final keyCtrl = TextEditingController(text: config.apiKey);
    final urlCtrl = TextEditingController(text: config.baseUrl);
    final modelCtrl = TextEditingController(text: config.model);
    bool fetchingModels = false;

    /// 切换 provider：字段值等于上一个 provider 的出厂默认（或为空）时，
    /// 回填新 provider 默认值；用户自定义值保留不动。
    void switchProvider(AiProviderKind next) {
      if (next == provider) return;
      final prevDefaults = aiProviderDefaults[provider]!;
      final nextDefaults = aiProviderDefaults[next]!;
      final curUrl = urlCtrl.text.trim();
      final curModel = modelCtrl.text.trim();
      provider = next;
      urlCtrl.text = (curUrl.isEmpty || curUrl == prevDefaults.baseUrl)
          ? nextDefaults.baseUrl
          : urlCtrl.text;
      modelCtrl.text = (curModel.isEmpty || curModel == prevDefaults.model)
          ? nextDefaults.model
          : modelCtrl.text;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          final isOpencode = provider == AiProviderKind.opencode;
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(sheetCtx).viewInsets.bottom + 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI 设置',
                      style: Theme.of(sheetCtx).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('配置后 AI 助手将接入真实大模型；留空 Key 则使用本地模式。',
                      style: Theme.of(sheetCtx).textTheme.bodyMedium),
                  const SizedBox(height: 14),
                  // 接入方式：文本 + 编辑红下划线（与全局切换控件同语言）
                  Row(
                    children: [
                      for (final (kind, label) in const [
                        (AiProviderKind.openai, 'OpenAI 兼容'),
                        (AiProviderKind.opencode, 'OpenCode Go'),
                      ])
                        PressScale(
                          pressedScale: 0.94,
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setSheetState(() => switchProvider(kind));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 22),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: Theme.of(sheetCtx)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: provider == kind
                                            ? sheetCtx.colors.ink
                                            : sheetCtx.colors.inkTertiary,
                                        fontWeight: provider == kind
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  width: 20,
                                  height: 2,
                                  color: provider == kind
                                      ? sheetCtx.colors.accent
                                      : Colors.transparent,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: urlCtrl,
                    decoration: InputDecoration(
                      labelText: isOpencode ? '网关地址' : 'API Base URL',
                      hintText: isOpencode
                          ? 'https://opencode.ai/zen/go/v1'
                          : 'https://api.openai.com/v1',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: keyCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText:
                          isOpencode ? 'OpenCode Go API Key' : 'API Key',
                      hintText:
                          isOpencode ? 'opencode.ai/auth 获取' : 'sk-...',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: modelCtrl,
                    decoration: InputDecoration(
                      labelText: isOpencode ? '模型' : '模型名称',
                      hintText: isOpencode ? 'glm-5.3-flash' : 'gpt-4o-mini',
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton.icon(
                    onPressed: fetchingModels
                        ? null
                        : () async {
                            setSheetState(() => fetchingModels = true);
                            try {
                              final models = await fetchAvailableModels(
                                ref.read(dioProvider),
                                baseUrl: urlCtrl.text.trim().isNotEmpty
                                    ? urlCtrl.text.trim()
                                    : aiProviderDefaults[provider]!.baseUrl,
                                apiKey: keyCtrl.text.trim(),
                              );
                              if (!sheetCtx.mounted) return;
                              _showModelPicker(sheetCtx, models, modelCtrl);
                            } catch (e) {
                              if (!sheetCtx.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('获取模型列表失败：$e')),
                              );
                            } finally {
                              if (sheetCtx.mounted) {
                                setSheetState(() => fetchingModels = false);
                              }
                            }
                          },
                    icon: fetchingModels
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.list_rounded, size: 18),
                    label: const Text('获取模型列表'),
                  ),
                  Text(
                    isOpencode
                        ? 'OpenCode Go 官方接入（云端网关，App 可直连）：'
                            '在 opencode.ai/auth 订阅后复制 API Key；'
                            '推荐 GLM / Kimi / DeepSeek / MiMo / LongCat 系列。'
                        : '任意 OpenAI 兼容服务（OpenAI / DeepSeek / 中转站等）均可接入。',
                    style: Theme.of(sheetCtx).textTheme.labelSmall?.copyWith(
                          color: sheetCtx.colors.inkTertiary,
                        ),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    TextButton(
                      onPressed: () async {
                        await ref.read(aiConfigProvider.notifier).clear();
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      },
                      child: const Text('清除 Key'),
                    ),
                    const Spacer(),
                    TextButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        child: const Text('取消')),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        await ref.read(aiConfigProvider.notifier).setConfig(
                          provider: provider,
                          apiKey: keyCtrl.text.trim(),
                          baseUrl: urlCtrl.text.trim().isNotEmpty
                              ? urlCtrl.text.trim()
                              : null,
                          model: modelCtrl.text.trim().isNotEmpty
                              ? modelCtrl.text.trim()
                              : null,
                        );
                        if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                      },
                      child: const Text('保存'),
                    ),
                  ]),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 模型选择器：列出网关返回的模型 id，点击回填到模型输入框。
  void _showModelPicker(
    BuildContext sheetCtx,
    List<String> models,
    TextEditingController modelCtrl,
  ) {
    final current = modelCtrl.text.trim();
    showModalBottomSheet(
      context: sheetCtx,
      showDragHandle: true,
      builder: (pickerCtx) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: models.length,
          itemBuilder: (ctx, i) {
            final id = models[i];
            return ListTile(
              dense: true,
              title:
                  Text(id, style: AppTheme.mono(const TextStyle(fontSize: 13))),
              trailing: id == current
                  ? Icon(Icons.check_rounded,
                      color: ctx.colors.accent, size: 18)
                  : null,
              onTap: () {
                modelCtrl.text = id;
                Navigator.pop(pickerCtx);
              },
            );
          },
        ),
      ),
    );
  }
}

/// 报头：kicker + 衬线标题 + 检索到的文章数 + 设置入口。
class _Masthead extends StatelessWidget {
  final ThemeData theme;
  final String kicker;
  final int articleCount;
  final VoidCallback onSettings;
  const _Masthead({
    required this.theme,
    required this.kicker,
    required this.articleCount,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(kicker,
                        style: theme.textTheme.labelMedium?.copyWith(color: c.accent)),
                    const SizedBox(height: 2),
                    Text('AI 助手', style: theme.textTheme.displayMedium),
                    const SizedBox(height: 2),
                    Text('$articleCount 篇文章可检索',
                        style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary)),
                  ],
                ),
              ),
              IconBtn(icon: Icons.tune_rounded, onTap: onSettings),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Hairline(color: c.hairlineStrong),
        ),
      ],
    );
  }
}

/// 快捷提问：铅字标签样式（细线描边，无底色）。
class _QuickTag extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _QuickTag({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: PressScale(
        pressedScale: 0.94,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            border: Border.all(color: c.hairlineStrong, width: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(label,
              style: theme.textTheme.labelLarge?.copyWith(color: c.inkSecondary)),
        ),
      ),
    );
  }
}
