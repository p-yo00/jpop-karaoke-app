class Singer {
  final int id;
  final String name;
  final String? originalName;
  final String profileImg;

  Singer(this.originalName, {required this.id, required this.name, required this.profileImg});
}