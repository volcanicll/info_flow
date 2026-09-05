import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/state/subscription_store.dart';
import '../../data/opml_parser.dart';

/// OPML 导入弹窗：支持粘贴文本或从 URL 拉取，解析后批量订阅。
void showOpmlImportSheet(BuildContext context, WidgetRef ref) {
  final textCtrl = TextEditingController();
  final urlCtrl = TextEditingController();
  var importing = false;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      final c = sheetCtx.colors;
      return StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(
                20, 0, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('IMPORT · OPML',
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: c.accent)),
                const SizedBox(height: 6),
                Text('导入订阅', style: theme.textTheme.headlineMedium),
                const SizedBox(height: 6),
                Text(
                  '粘贴 OPML 内容，或输入 OPML 文件地址。命中内置源的将直接订阅，其余自动创建为自定义源。',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: c.inkTertiary),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: textCtrl,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'OPML 内容',
                    hintText: '<opml version="2.0"> ... </opml>',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: urlCtrl,
                        decoration: const InputDecoration(
                          labelText: '或 OPML 文件 URL',
                          hintText: 'https://example.com/feeds.opml',
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: importing
                          ? null
                          : () async {
                              final url = urlCtrl.text.trim();
                              if (url.isEmpty) return;
                              setSheetState(() => importing = true);
                              try {
                                final resp = await ref
                                    .read(dioProvider)
                                    .get<String>(url, options: Options(
                                  responseType: ResponseType.plain,
                                  sendTimeout: const Duration(seconds: 15),
                                  receiveTimeout: const Duration(seconds: 20),
                                ));
                                if (ctx.mounted) {
                                  textCtrl.text = resp.data ?? '';
                                  setSheetState(() => importing = false);
                                }
                              } catch (e) {
                                setSheetState(() => importing = false);
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(content: Text('拉取失败：$e')),
                                  );
                                }
                              }
                            },
                      icon: importing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download_rounded),
                      tooltip: '拉取',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('取消'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () async {
                        final raw = textCtrl.text.trim();
                        if (raw.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('请粘贴 OPML 内容')),
                          );
                          return;
                        }
                        final List<OpmlSubscription> items;
                        try {
                          items = OpmlParser.parse(raw);
                        } catch (_) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('OPML 解析失败，请检查格式')),
                          );
                          return;
                        }
                        if (items.isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('未在 OPML 中找到订阅源')),
                          );
                          return;
                        }
                        final store = ref
                            .read(subscriptionStoreProvider.notifier);
                        final result = await store.importOpml(items);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                '已订阅 ${result.added + result.alreadySubscribed} 个源'
                                '${result.added > 0 ? '（新增 ${result.added}）' : ''}',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('导入并订阅'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// OPML 导出：生成 OPML 内容后弹出分享/复制选项。
void showOpmlExportSheet(BuildContext context, WidgetRef ref) {
  final store = ref.read(subscriptionStoreProvider.notifier);
  final opml = store.exportOpml();
  final count = ref.read(subscriptionStoreProvider).length;

  Future<String> writeTempFile() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/infoflow-subscriptions.opml');
    await file.writeAsString(opml);
    return file.path;
  }

  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) {
      final theme = Theme.of(sheetCtx);
      final c = sheetCtx.colors;
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('EXPORT · OPML',
                style:
                    theme.textTheme.labelMedium?.copyWith(color: c.accent)),
            const SizedBox(height: 6),
            Text('导出订阅', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              '将当前 $count 个订阅导出为标准 OPML 文件，可迁移至其他阅读器。',
              style:
                  theme.textTheme.bodySmall?.copyWith(color: c.inkTertiary),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final path = await writeTempFile();
                  if (sheetCtx.mounted) {
                    ScaffoldMessenger.of(sheetCtx).showSnackBar(
                      SnackBar(
                        content: Text('已生成 OPML，共 $count 个订阅'),
                        action: SnackBarAction(
                          label: '分享',
                          onPressed: () async {
                            await Share.shareXFiles(
                              [XFile(path, mimeType: 'text/xml')],
                              subject: 'InfoFlow 订阅导出',
                              text: 'InfoFlow 订阅列表（OPML）',
                            );
                          },
                        ),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.save_alt_rounded, size: 18),
                label: const Text('生成 OPML 文件'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final path = await writeTempFile();
                  if (sheetCtx.mounted) {
                    await Share.shareXFiles(
                      [XFile(path, mimeType: 'text/xml')],
                      subject: 'InfoFlow 订阅导出',
                      text: 'InfoFlow 订阅列表（OPML）',
                    );
                  }
                },
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: const Text('分享 OPML 文件'),
              ),
            ),
          ],
        ),
      );
    },
  );
}
