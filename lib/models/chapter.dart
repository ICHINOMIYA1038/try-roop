class Chapter {
  final String id;
  final String videoId;
  final String title;
  final int startTime; // seconds
  final int order;

  Chapter({
    required this.id,
    required this.videoId,
    required this.title,
    required this.startTime,
    required this.order,
  });

  factory Chapter.fromMap(Map<String, dynamic> map, String id) {
    return Chapter(
      id: id,
      videoId: map['videoId'] ?? '',
      title: map['title'] ?? '',
      startTime: map['startTime'] ?? 0,
      order: map['order'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'videoId': videoId,
      'title': title,
      'startTime': startTime,
      'order': order,
    };
  }

  String get startTimeFormatted {
    final minutes = startTime ~/ 60;
    final seconds = startTime % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
