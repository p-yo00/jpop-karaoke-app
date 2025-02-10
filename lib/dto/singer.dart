class Singer {
  final int id;
  final String name;
  final String? originalName;
  final String profileImg;

  Singer(this.originalName, {required this.id, required this.name, required this.profileImg});

  factory Singer.fromJson(Map<String, dynamic> json) {
    return Singer(
        json['originalName'],
        id: json['id'],
        name: json['name'],
        profileImg: json['profileImg']
    );
  }
}