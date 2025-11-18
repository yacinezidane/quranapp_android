class Athkar {
  final int id;
  final String category;
  final String audio;
  final String filename;
  final List<Thikr> array;

  Athkar({
    required this.id,
    required this.category,
    required this.audio,
    required this.filename,
    required this.array,
  });

  factory Athkar.fromJson(Map<String, dynamic> json) {
    return Athkar(
      id: json['id'],
      category: json['category'],
      audio: json['audio'],
      filename: json['filename'],
      array: (json['array'] as List)
          .map((item) => Thikr.fromJson(item))
          .toList(),
    );
  }
}

class Thikr {
  final int id;
  final String text;
  final int count;
  final String audio;
  final String filename;

  Thikr({
    required this.id,
    required this.text,
    required this.count,
    required this.audio,
    required this.filename,
  });

  factory Thikr.fromJson(Map<String, dynamic> json) {
    return Thikr(
      id: json['id'],
      text: json['text'],
      count: json['count'],
      audio: json['audio'],
      filename: json['filename'],
    );
  }
}
