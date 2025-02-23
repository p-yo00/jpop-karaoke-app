class Singer {
  final int id;
  final String name;
  final String? originalName;
  final String profileImg;
  final int songCount;

  Singer(this.originalName, {required this.id, required this.name, required this.profileImg, required this.songCount});

  factory Singer.fromJson(Map<String, dynamic> json) {
    return Singer(
        json['originalName'],
        id: json['id'],
        name: json['name'],
        profileImg: json['profileImg'],
        songCount: json['songCount'] ?? 0
    );
  }
}