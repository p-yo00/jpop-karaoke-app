class Song {
  final int id;
  final String title;
  final String originalTitle;
  final String albumImg;
  final String singer;
  final int ky;
  final int tj;

  Song(this.originalTitle, this.ky, this.tj, this.singer, this.albumImg, {required this.id, required this.title});
}