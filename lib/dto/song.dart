class Song {
  final int id;
  final String title;
  final String originalTitle;
  final String albumImg;
  final String singer;
  final String ky;
  final String tj;

  Song(this.originalTitle, this.ky, this.tj, this.singer, this.albumImg, {required this.id, required this.title});

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
        json['originalTitle'], json['ky'].toString(), json['tj'].toString(), json['singer'], json['albumImg'],
        id: json['id'],
        title: json['title']
    );
  }
}