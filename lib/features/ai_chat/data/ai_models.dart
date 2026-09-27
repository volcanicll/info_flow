import 'package:dio/dio.dart';

/// OpenAI 兼容模型目录：`GET {baseUrl}/models` 协议。
///
/// OpenCode Go 官方网关（magpie）与标准 OpenAI 服务均遵循该协议，
/// 用于 AI 设置中的「获取模型列表」选择器。
Future<List<String>> fetchAvailableModels(
  Dio dio, {
  required String baseUrl,
  required String apiKey,
}) async {
  final base = normalizeAiBaseUrl(baseUrl);
  final resp = await dio.get<Map<String, dynamic>>(
    '$base/models',
    options: Options(
      headers: {'Authorization': 'Bearer $apiKey'},
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
  final models = parseOpenAiModelIds(resp.data);
  if (models.isEmpty) {
    throw Exception('网关未返回任何模型');
  }
  return models;
}

/// 解析 `{ "data": [ { "id": "..." }, ... ] }`，返回去重后的模型 id 列表
/// （保持服务端顺序）。脏数据条目跳过而非抛出。
List<String> parseOpenAiModelIds(Object? json) {
  if (json is! Map) return const [];
  final data = json['data'];
  if (data is! List) return const [];
  final out = <String>[];
  for (final item in data) {
    final id = item is Map ? item['id'] : null;
    if (id is String && id.trim().isNotEmpty && !out.contains(id.trim())) {
      out.add(id.trim());
    }
  }
  return out;
}

/// 归一化 base url：去空白与结尾斜杠。
/// 用户习惯性地会把地址填成 `http://host:port/`，拼路径前统一处理。
String normalizeAiBaseUrl(String input) {
  var base = input.trim();
  while (base.endsWith('/')) {
    base = base.substring(0, base.length - 1);
  }
  return base;
}
