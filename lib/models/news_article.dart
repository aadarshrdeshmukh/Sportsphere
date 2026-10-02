class NewsArticle {
  const NewsArticle(
      {required this.id,
      required this.title,
      required this.description,
      required this.publishedAt,
      this.imageUrl,
      this.url,
      this.category = 'Sports',
      this.source = 'ESPN'});
  final String id, title, description, category, source;
  final DateTime publishedAt;
  final String? imageUrl;
  final String? url;

  factory NewsArticle.fromEspn(Map<String, dynamic> json, {String? category}) {
    final images = json['images'] as List?;
    return NewsArticle(
        id: '${json['id'] ?? json['link'] ?? json['headline']}',
        title: '${json['headline'] ?? 'Untitled'}',
        description: '${json['description'] ?? ''}',
        publishedAt:
            DateTime.tryParse('${json['published']}') ?? DateTime.now(),
        imageUrl: images?.isNotEmpty == true
            ? (images!.first as Map)['url'] as String?
            : null,
        url: json['links'] is Map
            ? (json['links'] as Map)['web'] is Map
                ? ((json['links'] as Map)['web'] as Map)['href'] as String?
                : null
            : null,
        category: category ??
            '${json['categories'] is List && (json['categories'] as List).isNotEmpty ? (json['categories'] as List).first['description'] : 'Sports'}',
        source: '${(json['source'] as Map?)?['name'] ?? 'ESPN'}');
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'headline': title,
        'description': description,
        'published': publishedAt.toIso8601String(),
        'images': imageUrl == null
            ? []
            : [
                {'url': imageUrl}
              ],
        'categories': [
          {'description': category}
        ],
        'source': {'name': source},
        'links': url == null
            ? null
            : {
                'web': {'href': url}
              },
      };
}
