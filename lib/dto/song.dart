import 'dart:convert';

class Song {
  final int id;
  final String title;
  final String originalTitle;
  final String albumImg;
  final String singer;
  final String ky;
  final String tj;
  String youtubeUrl;
  bool favorite;

  Song({
    required this.id,
    required this.title,
    required this.originalTitle,
    required this.albumImg,
    required this.singer,
    required this.ky,
    required this.tj,
    this.youtubeUrl = '',
    this.favorite = false,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      // ?? '' 를 사용하여 데이터가 null일 경우 빈 문자열을 넣어 에러를 방지합니다.
      id: json['id'] ?? 0,
      title: json['title'] ?? '제목 없음',
      originalTitle: json['originalTitle'] ?? '',
      albumImg: json['albumImg'] ?? '',
      singer: json['singer'] ?? '아티스트 미상',
      ky: (json['ky'] ?? '').toString(),
      tj: (json['tj'] ?? '').toString(),
      youtubeUrl: json['youtubeUrl'] ?? '',
      favorite: json['favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'originalTitle': originalTitle,
      'albumImg': albumImg,
      'singer': singer,
      'ky': ky,
      'tj': tj,
      'youtubeUrl': youtubeUrl,
      'favorite': favorite,
    };
  }

  factory Song.fromString(String source) => Song.fromJson(json.decode(source));

  like() {
    favorite = !favorite;
  }
}