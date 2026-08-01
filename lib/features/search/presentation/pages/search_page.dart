import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme.dart';
import '../../../../shared/widgets/hairline.dart';
import '../../../feed/presentation/widgets/article_row.dart';
import '../controllers/search_controller.dart';

/// 检索页（铅字风）：极简大输入行（无边框，仅底部粗墨线）+ 历史词铅字标签。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  static const _hotKeywords = [
    'GPT-5',
    '比亚迪财报',
    'Rust 异步闭包',
    'Vision Pro 2',
    'DeepMind',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String text) {
    setState(() {}); // 刷新清除按钮
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      ref.read(searchControllerProvider.notifier).query(text);
    });
  }

  void _submit([String? keyword]) {
    final text = (keyword ?? _controller.text).trim();
    if (text.isEmpty) return;
    _controller.text = text;
    _focusNode.unfocus();
    ref.read(searchControllerProvider.notifier).submit(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _SearchField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: _onChanged,
              onSubmit: _submit,
              onClear: () {
                _controller.clear();
                ref.read(searchControllerProvider.notifier).clear();
                setState(() {});
              },
              onCancel: () => context.pop(),
            ),
            if (state.hasSearched) _FilterRow(active: state.filter),
            Expanded(
              child: state.hasSearched
                  ? _ResultList(state: state)
                  : _Suggestions(hot: _hotKeywords, onTap: _submit),
            ),
          ],
        ),
      ),
    );
  }
}

/// 极简大输入行：无边框，仅底部粗墨线。
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;
  final VoidCallback onClear;
  final VoidCallback onCancel;
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmit,
    required this.onClear,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: c.ink, width: 2)),
              ),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: onChanged,
                onSubmitted: onSubmit,
                style: theme.textTheme.headlineMedium,
                cursorColor: c.accent,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '检索',
                  hintStyle: theme.textTheme.headlineMedium?.copyWith(
                    color: c.inkTertiary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                  suffixIcon: controller.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: c.inkTertiary,
                          ),
                          onPressed: onClear,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: onCancel,
              child: Text(
                '取消',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: c.inkSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 过滤范围：铅字标签行。
class _FilterRow extends ConsumerWidget {
  final SearchFilter active;
  const _FilterRow({required this.active});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: SearchFilter.values.map((f) {
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: _Letterpress(
              label: f.label,
              active: f == active,
              onTap: () =>
                  ref.read(searchControllerProvider.notifier).setFilter(f),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// 结果列表：复用信息流目录行，发丝线分隔。
class _ResultList extends StatelessWidget {
  final SearchState state;
  const _ResultList({required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    if (state.results.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 44, color: c.hairlineStrong),
              const SizedBox(height: 14),
              Text(
                '未找到「${state.query.trim()}」',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text('换个关键词试试', style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: Text(
            '找到 ${state.results.length} 篇相关内容',
            style: theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Hairline(color: c.hairlineStrong),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: state.results.length,
            separatorBuilder: (_, _) => const Hairline(),
            itemBuilder: (context, index) {
              final a = state.results[index];
              final query = state.query.trim();
              return ArticleRow(
                article: a,
                highlightQuery: query.isEmpty ? null : query,
                onTap: () => context.push('/reader/${a.id}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// 建议态：热门 + 历史，均以铅字标签排布。
class _Suggestions extends ConsumerWidget {
  final List<String> hot;
  final ValueChanged<String> onTap;
  const _Suggestions({required this.hot, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final c = context.colors;
    final history = ref.watch(searchHistoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Text(
          '热门检索',
          style: theme.textTheme.labelMedium?.copyWith(color: c.accent),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 18,
          runSpacing: 14,
          children: [
            for (var i = 0; i < hot.length; i++)
              _RankTag(rank: i + 1, label: hot[i], onTap: () => onTap(hot[i])),
          ],
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Text(
              '检索历史',
              style: theme.textTheme.labelMedium?.copyWith(
                color: c.inkTertiary,
              ),
            ),
            const Spacer(),
            if (history.isNotEmpty)
              GestureDetector(
                onTap: () => ref.read(searchHistoryProvider.notifier).clear(),
                child: Text(
                  '清空',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: c.inkTertiary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),
        if (history.isEmpty)
          Text(
            '还没有检索记录',
            style: theme.textTheme.bodyMedium?.copyWith(color: c.inkTertiary),
          )
        else
          Wrap(
            spacing: 18,
            runSpacing: 14,
            children: history
                .map(
                  (h) => _Letterpress(
                    label: h,
                    active: false,
                    onTap: () => onTap(h),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }
}

/// 铅字标签：字距拉开的纯文字，激活态加墨色下划线。
class _Letterpress extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _Letterpress({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? c.ink : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 2),
        child: Text(
          label,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: active ? c.ink : c.inkSecondary,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// 排名热词：序号（编辑红）+ 铅字词。
class _RankTag extends StatelessWidget {
  final int rank;
  final String label;
  final VoidCallback onTap;
  const _RankTag({
    required this.rank,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rank',
            style: AppTheme.mono(
              theme.textTheme.labelLarge!.copyWith(
                color: rank <= 3 ? c.accent : c.inkTertiary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: c.ink,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
