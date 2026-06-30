import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/ai_model_item.dart';

const _huggingfaceApi = 'https://huggingface.co/api/models';

class AiModelsRepository {
  final Dio _dio;

  AiModelsRepository(this._dio);

  Future<List<AiModelItem>> fetchTrendingModels({int limit = 10}) async {
    final resp = await _dio.get<List<dynamic>>(
      _huggingfaceApi,
      queryParameters: {
        'sort': 'trending',
        'limit': limit,
        'filter': 'text-generation',
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; InfoFlow/1.0)',
        },
      ),
    );

    final data = resp.data;
    if (data == null || data.isEmpty) return [];

    return data.map((m) {
      final map = m as Map<String, dynamic>;
      final modelId = map['id'] as String? ?? 'Unknown';
      final author = map['author'] as String?;
      return AiModelItem(
        id: modelId,
        name: modelId,
        author: author,
        description: map['description'] as String? ?? '',
        downloads: (map['downloads'] as num?)?.toInt() ?? 0,
        likes: (map['likes'] as num?)?.toInt() ?? 0,
        pipelineTag: map['pipeline_tag'] as String?,
        url: 'https://huggingface.co/$modelId',
        lastModified: map['lastModified'] != null
            ? DateTime.tryParse(map['lastModified'] as String)
            : null,
      );
    }).toList();
  }
}

final aiModelsRepositoryProvider = Provider<AiModelsRepository>((ref) {
  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
  return AiModelsRepository(dio);
});
