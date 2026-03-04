class WpComment {
  const WpComment({
    required this.id,
    required this.authorName,
    required this.content,
    required this.date,
  });

  final int id;
  final String authorName;
  final String content;
  final DateTime date;

  factory WpComment.fromJson(Map<String, dynamic> json) {
    return WpComment(
      id: json['id'] as int? ?? 0,
      authorName: json['author_name'] as String? ?? 'Anonymous',
      content:
          (json['content'] as Map<String, dynamic>?)?['rendered'] as String? ??
          '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
