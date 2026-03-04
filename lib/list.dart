import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hello_flutter/dto/song.dart';
import 'package:hello_flutter/bannerAd.dart';

enum ListMode { ranking, singer, search, favorite }
const String baseUrl = String.fromEnvironment('API_BASE_URL');
const String apiPort = "8080";

class LoadSongList {

  static Future<List<Song>> loadSingerSongList(String singerId) async {
    final url = Uri.parse("$baseUrl:$apiPort/singer/$singerId/song");
    final response = await http.get(url).timeout(
      Duration(seconds: 30),
      onTimeout: () => throw TimeoutException("요청 시간이 초과되었습니다."),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      return jsonData.map((json) => Song.fromJson(json)).toList();
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

      return jsonData.map((json) => Song.fromJson(json)).toList();
    }
    return Future.error("fail:load");
  }
}

class SongListPageWithAppBar extends StatelessWidget {
  SongListPageWithAppBar({super.key, required this.title, required this.mode, required this.modeValue}) {
    Future<List<Song>> baseList;
    if (mode == ListMode.singer) {
      baseList = LoadSongList.loadSingerSongList(modeValue);
    } else if (mode == ListMode.search) {
      baseList = LoadSongList.loadSearchSongList(modeValue);
    } else {
      baseList = SongListPage().loadBestSongList();
    }
    songList = _loadFavorites(baseList);
  }
  final String title;
  final ListMode mode;
  final String modeValue;
  late final Future<List<Song>> songList;
  List<Song> favoriteSongs = [];

  // 저장된 즐겨찾기 불러오기
  Future<List<Song>> _loadFavorites(Future<List<Song>> songListFuture) async {
    final results = await Future.wait([
      songListFuture,
      SharedPreferences.getInstance(),
    ]);

    List<Song> songs = results[0] as List<Song>;
    SharedPreferences prefs = results[1] as SharedPreferences;

    List<String>? jsonList = prefs.getStringList('favorites');

    if (jsonList != null && jsonList.isNotEmpty) {
      // 저장된 즐겨찾기 리스트 생성
      List<Song> favoriteSongs = jsonList.map((item) => Song.fromString(item)).toList();

      // 노래 목록을 돌며 즐겨찾기 여부 표시
      for (var song in songs) {
        song.favorite = favoriteSongs.any((fav) => fav.id == song.id);
      }
    }
    return songs;
  }

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
                return SongListBody(songList: snapshot.data!);
              } else {
                return Center(child: Text('불러오는데 실패했습니다.'));
              }
            }
        )
    );
  }
}

class SongListPage extends StatelessWidget {
  const SongListPage({super.key});

  // 저장된 즐겨찾기 불러오기
  _loadFavorites(List<Song> songs) async {
    final results = await Future.wait([
      SharedPreferences.getInstance(),
    ]);

    SharedPreferences prefs = results[0];

    List<String>? jsonList = prefs.getStringList('favorites');

    if (jsonList != null && jsonList.isNotEmpty) {
      // 저장된 즐겨찾기 리스트 생성
      List<Song> favoriteSongs = jsonList.map((item) => Song.fromString(item)).toList();

      // 노래 목록을 돌며 즐겨찾기 여부 표시
      for (var song in songs) {
        song.favorite = favoriteSongs.any((fav) => fav.id == song.id);
      }
    }
    return songs;
  }

  Future<List<Song>> loadBestSongList() async {
    final url = Uri.parse("$baseUrl:$apiPort/song/chart100");

    final response = await http.get(url).timeout(
      Duration(seconds: 30),
      onTimeout: () => throw TimeoutException("요청 시간이 초과되었습니다."),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      List<Song> songList = jsonData.map((json) => Song.fromJson(json)).toList();

      _loadFavorites(songList);
      return songList;
    }
    return Future.error("fail:load");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Song>>(
        future: loadBestSongList(), // API 호출 함수 연결
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('불러오는데 실패했습니다.(1)'));
          } else if (snapshot.hasData) {
            return SongListBody(songList: snapshot.data!);
          } else {
            return Center(child: Text('불러오는데 실패했습니다.(2)'));
          }
        }
      )
    );
  }
}

class SongListWidget extends State<SongListBody> {
  SongListWidget({required this.songList});

  final List<Song> songList;
  final int adCount = 10;
  bool isSelected = false;

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
                  const SizedBox(width: 30, child: Text("순위", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))), // 인덱스
                  const SizedBox(width: 30, child: Text("찜", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))), // 이미지
                  Expanded(
                    flex: 2,
                    child: Text("금영", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text("TJ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text("노래명 / 가수", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 2. 리스트뷰
            Expanded(
              child: ListView.builder(
                itemCount: songList.length + (songList.length ~/ adCount),
                itemBuilder: (context, index) {
                  if ((index+1) % (adCount+1) == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: AdWidgetContainer(adHeight: -1),
                    );
                  }
                  var songIndex = index - ((index) ~/ (adCount+1));
                  var song = songList[songIndex];

                  return InkWell(
                    onTap: () { // 상세 페이지 현재 미구현
                      /*Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(song: song),
                        ),
                      );*/
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          // 인덱스
                          SizedBox(
                            width: 30,
                            child: Text((songIndex+1).toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                          ),
                          // 찜
                          SizedBox(
                            width: 30,
                            child: GestureDetector(
                              onTap: () => addFavorite(songIndex),  // 아이콘을 클릭하면 색상 변경
                              child: Icon(
                                Icons.favorite,  // 사용할 아이콘
                                color: song.favorite ? Colors.red : Colors.grey,  // 클릭 여부에 따라 색상 변경
                                size: 20.0,  // 아이콘 크기
                              ),
                            ),
                          ),
                          // 번호1 (금영)
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(song.ky.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            ),
                          ),
                          // 번호2 (TJ)
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(song.tj.toString(),
                                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            ),
                          ),
                          // 제목 & 가수 (2줄)
                          Expanded(
                            flex: 4,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AutoSizeText(song.title,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  maxLines: 2,),
                                AutoSizeText(song.singer,
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  maxLines: 1,),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        )
    );
  }
}

class SongListBody extends StatefulWidget {
  SongListBody({super.key, required this.songList});
  final List<Song> songList;

  @override
  SongListWidget createState() => SongListWidget(songList: songList);
}