class AiModelItem {
  final String id;
  final String name;
  final String? author;
  final String description;
  final int downloads;
  final int likes;
  final String? pipelineTag;
  final String url;
  final DateTime? lastModified;

  const AiModelItem({
    required this.id,
    required this.name,
    this.author,
    required this.description,
    required this.downloads,
    required this.likes,
    this.pipelineTag,
    required this.url,
    this.lastModified,
  });

  String get downloadsFormatted {
    if (downloads >= 1000000) {
      return '${(downloads / 1000000).toStringAsFixed(1)}M';
    } else if (downloads >= 1000) {
      return '${(downloads / 1000).toStringAsFixed(1)}K';
    }
    return downloads.toString();
  }
}
