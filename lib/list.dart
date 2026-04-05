import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/bannerAd.dart';
import 'package:hello_flutter/dto/song.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum ListMode { ranking, singer, search, favorite }

const String baseUrl = String.fromEnvironment('API_BASE_URL');
const String apiPort = "8080";

class LoadSongList {
  static Future<List<Song>> loadBestSongList() async {
    final url = Uri.parse("$baseUrl:$apiPort/song/chart100");

    final response = await http.get(url).timeout(
          Duration(seconds: 30),
          onTimeout: () => throw TimeoutException("요청 시간이 초과되었습니다."),
        );

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      List<Song> songs = jsonData.map((json) => Song.fromJson(json)).toList();

      return syncFavorites(songs);
    }
    return Future.error("fail:load");
  }

  static Future<List<Song>> loadSingerSongList(String singerId) async {
    final url = Uri.parse("$baseUrl:$apiPort/singer/$singerId/song");
    final response = await http.get(url).timeout(
          Duration(seconds: 30),
          onTimeout: () => throw TimeoutException("요청 시간이 초과되었습니다."),
        );

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      List<Song> songs = jsonData.map((json) => Song.fromJson(json)).toList();

      return syncFavorites(songs);
    }
    return Future.error("fail:load");
  }

  static Future<List<Song>> loadSearchSongList(String query) async {
    final url = Uri.parse("$baseUrl:$apiPort/song").replace(queryParameters: {
      'q': query,
    });
    final response = await http.get(url).timeout(
          Duration(seconds: 30),
          onTimeout: () => throw TimeoutException("요청 시간이 초과되었습니다."),
        );

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      List<Song> songs = jsonData.map((json) => Song.fromJson(json)).toList();

      return syncFavorites(songs);
    }
    return Future.error("fail:load");
  }

  // 저장된 즐겨찾기 불러오기
  static Future<List<Song>> syncFavorites(List<Song> songs) async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
    ]);

    SharedPreferences prefs = results[0];

    List<String>? jsonList = prefs.getStringList('favorites');

    if (jsonList != null && jsonList.isNotEmpty) {
      // 저장된 즐겨찾기 리스트 생성
      List<Song> favoriteSongs =
          jsonList.map((item) => Song.fromString(item)).toList();

      // 노래 목록을 돌며 즐겨찾기 여부 표시
      for (var song in songs) {
        song.favorite = favoriteSongs.any((fav) => fav.id == song.id);
      }
    }
    return songs;
  }
}

class SongListPageWithAppBar extends StatelessWidget {
  SongListPageWithAppBar(
      {super.key,
      required this.title,
      required this.mode,
      required this.modeValue}) {
    if (mode == ListMode.singer) {
      songList = LoadSongList.loadSingerSongList(modeValue);
    } else if (mode == ListMode.search) {
      songList = LoadSongList.loadSearchSongList(modeValue);
    } else {
      songList = LoadSongList.loadBestSongList();
    }
  }

  final String title;
  final ListMode mode;
  final String modeValue;
  late final Future<List<Song>> songList;
  List<Song> favoriteSongs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: FutureBuilder<List<Song>>(
            future: songList, // API 호출 함수 연결
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('불러오는데 실패했습니다.'));
              } else if (snapshot.hasData) {
                return SongListBody(
                    songList: snapshot.data!, mode: mode, modeValue: modeValue);
              } else {
                return Center(child: Text('불러오는데 실패했습니다.'));
              }
            }));
  }
}

class SongListPage extends StatelessWidget {
  const SongListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: FutureBuilder<List<Song>>(
            future: LoadSongList.loadBestSongList(), // API 호출 함수 연결
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('불러오는데 실패했습니다.(1)'));
              } else if (snapshot.hasData) {
                return SongListBody(
                    songList: snapshot.data!, mode: ListMode.ranking);
              } else {
                return Center(child: Text('불러오는데 실패했습니다.(2)'));
              }
            }));
  }
}

class SongListWidget extends State<SongListBody> {
  SongListWidget({required this.songList});

  late List<Song> songList;
  final int adCount = 10;
  bool isSelected = false;

  Future<List<Song>> loadSongList() async {
    if (widget.mode == ListMode.singer) {
      songList = await LoadSongList.loadSingerSongList(widget.modeValue);
    } else if (widget.mode == ListMode.search) {
      songList = await LoadSongList.loadSearchSongList(widget.modeValue);
    } else {
      songList = await LoadSongList.loadBestSongList();
    }
    return songList;
  }

  Future<void> _handleRefresh() async {
    if (widget.mode == ListMode.favorite) {
      return;
    }
    List<Song> freshSongList = await loadSongList();

    setState(() {
      songList = freshSongList;
    });
  }

  Future<void> addFavorite(int songIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedSong = songList[songIndex];

    setState(() {
      selectedSong.favorite = !selectedSong.favorite;
    });

    List<String> favoriteJsonList = prefs.getStringList('favorites') ?? [];

    if (selectedSong.favorite) {
      // 3. 즐겨찾기 추가 시: 객체를 JSON 문자열로 변환하여 리스트에 추가
      // 중복 체크 (이미 같은 번호의 노래가 있는지 확인)
      bool isAlreadyIn = favoriteJsonList.any((item) {
        final s = Song.fromJson(jsonDecode(item));
        return s.id == selectedSong.id;
      });

      if (!isAlreadyIn) {
        favoriteJsonList.add(jsonEncode(selectedSong.toJson()));
      }
    } else {
      // 4. 즐겨찾기 해제 시: 리스트에서 제거
      favoriteJsonList.removeWhere((item) {
        final s = Song.fromJson(jsonDecode(item));
        return s.title == selectedSong.title && s.singer == selectedSong.singer;
      });
    }

    // 5. 최종 리스트를 기기에 저장
    await prefs.setStringList('favorites', favoriteJsonList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      children: [
        // 1. 고정 헤더
        Container(
          padding: const EdgeInsets.all(10),
          color: Colors.grey[300],
          child: Row(
            children: [
              const SizedBox(
                  width: 30,
                  child: Text("순위",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              // 인덱스
              const SizedBox(
                  width: 30,
                  child: Text("찜",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold))),
              // 이미지
              Expanded(
                flex: 2,
                child: Text("금영",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 2,
                child: Text("TJ",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              Expanded(
                flex: 4,
                child: Text("노래명 / 가수",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

        // 2. 리스트뷰
        Expanded(
            child: RefreshIndicator(
          onRefresh: _handleRefresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: songList.length + (songList.length ~/ adCount),
            itemBuilder: (context, index) {
              if ((index + 1) % (adCount + 1) == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AdWidgetContainer(adHeight: -1),
                );
              }
              var songIndex = index - ((index) ~/ (adCount + 1));
              var song = songList[songIndex];

              return InkWell(
                onTap: () {
                  // 상세 페이지 현재 미구현
                  /*Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(song: song),
                        ),
                      );*/
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: Row(
                    children: [
                      // 인덱스
                      SizedBox(
                        width: 30,
                        child: Text((songIndex + 1).toString(),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14)),
                      ),
                      // 찜
                      SizedBox(
                        width: 30,
                        child: GestureDetector(
                          onTap: () => addFavorite(songIndex),
                          // 아이콘을 클릭하면 색상 변경
                          child: Icon(
                            Icons.favorite, // 사용할 아이콘
                            color: song.favorite
                                ? Colors.red
                                : Colors.grey, // 클릭 여부에 따라 색상 변경
                            size: 20.0, // 아이콘 크기
                          ),
                        ),
                      ),
                      // 번호1 (금영)
                      Expanded(
                        flex: 2,
                        child: Center(
                            child: Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (song.ky.toString().isNotEmpty)
                                ? song.ky.toString()
                                : "미지원",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        )),
                      ),
                      // 번호2 (TJ)
                      Expanded(
                        flex: 2,
                        child: Center(
                            child: Container(
                          width: 60,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            (song.tj.toString().isNotEmpty)
                                ? song.tj.toString()
                                : "미지원",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        )),
                      ),
                      // 제목 & 가수 (2줄)
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AutoSizeText(
                              song.title,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                              maxLines: 2,
                            ),
                            AutoSizeText(
                              song.singer,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        )),
      ],
    ));
  }
}

class SongListBody extends StatefulWidget {
  const SongListBody(
      {super.key,
      required this.songList,
      this.mode = ListMode.ranking, // 기본값은 랭킹
      this.modeValue = ""});

  final List<Song> songList;
  final ListMode mode;
  final String modeValue;

  @override
  SongListWidget createState() => SongListWidget(songList: songList);
}
