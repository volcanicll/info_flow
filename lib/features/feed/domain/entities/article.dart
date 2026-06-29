import 'dart:ui';

class Article {
  final String id;
  final String feedId;
  final String feedName;
  final String? feedIconUrl;
  /// 来源主题色（用于头像渐变背景）
  final int? feedColor;
  final String title;
  final String url;
  final String? content;
  final String? summary;
  final List<String>? keyPoints;
  final String? sentiment;
  final String? coverImageUrl;
  final DateTime? publishedAt;
  final int? likeCount;
  final bool isLiked;
  final bool isBookmarked;
  final bool isRead;
  /// 是否标记为「稍后阅读」
  final bool isReadLater;

  const Article({
    required this.id,
    required this.feedId,
    required this.feedName,
    this.feedIconUrl,
    this.feedColor,
    required this.title,
    required this.url,
    this.content,
    this.summary,
    this.keyPoints,
    this.sentiment,
    this.coverImageUrl,
    this.publishedAt,
    this.likeCount,
    this.isLiked = false,
    this.isBookmarked = false,
    this.isRead = false,
    this.isReadLater = false,
  });

  /// 来源颜色的 Color 对象
  Color? get feedColorValue =>
      feedColor == null ? null : Color(feedColor!);

  Article copyWith({
    bool? isLiked,
    bool? isBookmarked,
    bool? isRead,
    bool? isReadLater,
    String? summary,
    List<String>? keyPoints,
  }) {
    return Article(
      id: id,
      feedId: feedId,
      feedName: feedName,
      feedIconUrl: feedIconUrl,
      feedColor: feedColor,
      title: title,
      url: url,
      content: content,
      summary: summary ?? this.summary,
      keyPoints: keyPoints ?? this.keyPoints,
      sentiment: sentiment,
      coverImageUrl: coverImageUrl,
      publishedAt: publishedAt,
      likeCount: likeCount,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      isRead: isRead ?? this.isRead,
      isReadLater: isReadLater ?? this.isReadLater,
    );
  }

  /// 序列化为 JSON（用于收藏持久化）
  Map<String, dynamic> toJson() => {
        'id': id,
        'feedId': feedId,
        'feedName': feedName,
        'feedIconUrl': feedIconUrl,
        'feedColor': feedColor,
        'title': title,
        'url': url,
        'summary': summary,
        'coverImageUrl': coverImageUrl,
        'publishedAt': publishedAt?.toIso8601String(),
        'likeCount': likeCount,
        'isReadLater': isReadLater,
      };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: json['id'] as String,
        feedId: json['feedId'] as String,
        feedName: json['feedName'] as String,
        feedIconUrl: json['feedIconUrl'] as String?,
        feedColor: json['feedColor'] as int?,
        title: json['title'] as String,
        url: json['url'] as String,
        summary: json['summary'] as String?,
        coverImageUrl: json['coverImageUrl'] as String?,
        publishedAt: json['publishedAt'] != null
            ? DateTime.tryParse(json['publishedAt'] as String)
            : null,
        likeCount: json['likeCount'] as int?,
        isReadLater: json['isReadLater'] as bool? ?? false,
      );
}
