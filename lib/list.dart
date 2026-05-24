import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/bannerAd.dart';
import 'package:hello_flutter/dto/song.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
      List<Song> favoriteSongs = jsonList.map((item) => Song.fromString(item)).toList();

      // 노래 목록을 돌며 즐겨찾기 여부 표시
      for (var song in songs) {
        song.favorite = favoriteSongs.any((fav) => fav.id == song.id);
      }
    }
    return songs;
  }
}

class SongListPageWithAppBar extends StatelessWidget {
  SongListPageWithAppBar({super.key, required this.title, required this.mode, required this.modeValue}) {
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
                return SongListBody(songList: snapshot.data!, mode: mode, modeValue: modeValue);
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
            return SongListBody(songList: snapshot.data!, mode: ListMode.ranking);
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

  late List<Song> songList;
  final int adCount = 12;
  bool isSelected = false;
  int? expandedIndex;
  bool isYoutubeOn = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // 설정 불러오기 함수
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final bool currentSetting = prefs.getBool('isYoutubeOn') ?? true;

    // 현재 상태와 다를 때만 setState 호출 (무한 루프 방지)
    if (isYoutubeOn != currentSetting) {
      setState(() {
        isYoutubeOn = currentSetting;
        if (!isYoutubeOn) expandedIndex = null;
      });
    }
  }

  Future<void> _updateSavedOrder() async {
    final prefs = await SharedPreferences.getInstance();

    // 현재 리스트의 모든 노래를 하나의 리스트로 변환
    List<String> allFavorites = songList.map((song) => jsonEncode(song.toJson())).toList();

    // 'favorites' 키 하나에 모두 저장
    await prefs.setStringList('favorites', allFavorites);
  }

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

  Widget _buildSongRow(int songIndex, Song song) {
    return Column(
        key: ValueKey("song_row_${song.id}"),
        children: [
          InkWell(
            onTap: () {
              if (isYoutubeOn) {
                setState(() {
                  if (expandedIndex == songIndex) {
                    expandedIndex = null;
                  } else {
                    expandedIndex = songIndex;
                  }
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                children: [
                  // 인덱스
                  SizedBox(
                    width: 30,
                    child: Text(
                        (songIndex + 1).toString(), textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14)),
                  ),
                  // 찜
                  SizedBox(
                    width: 30,
                    child: GestureDetector(
                      onTap: () => addFavorite(songIndex), // 아이콘을 클릭하면 색상 변경
                      child: Icon(
                        Icons.favorite, // 사용할 아이콘
                        color: song.favorite ? Colors.red : Colors.grey,
                        // 클릭 여부에 따라 색상 변경
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
                            (song.ky
                                .toString()
                                .isNotEmpty)
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
                            (song.tj
                                .toString()
                                .isNotEmpty)
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
                        AutoSizeText(song.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 2,),
                        AutoSizeText(song.singer,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                          maxLines: 1,),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isYoutubeOn && expandedIndex == songIndex &&
              song.youtubeUrl.isNotEmpty)
            YoutubeWebView(
              youtubeUrl: song.youtubeUrl,
            ),
        ]
    );
  }

  Future<void> addFavorite(int songIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final selectedSong = songList[songIndex];

    setState(() {
      selectedSong.favorite = !selectedSong.favorite;
    });

    List<String> favoriteJsonList = prefs.getStringList('favorites') ?? [];

    if (selectedSong.favorite) {
      // 추가 로직: 중복 체크 후 삽입
      bool isAlreadyIn = favoriteJsonList.any((item) {
        final s = Song.fromJson(jsonDecode(item));
        return s.id == selectedSong.id;
      });

      if (!isAlreadyIn) {
        favoriteJsonList.add(jsonEncode(selectedSong.toJson()));
      }
    } else {
      // 삭제 로직: ID 기준으로 제거
      favoriteJsonList.removeWhere((item) {
        final s = Song.fromJson(jsonDecode(item));
        return s.id == selectedSong.id;
      });

      setState(() {
        if (widget.mode == ListMode.favorite) {
          songList.removeAt(songIndex);
        }
      });
    }

    // 통합된 리스트 저장
    await prefs.setStringList('favorites', favoriteJsonList);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // 1. 고정 헤더 영역
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[300],
            child: Row(
              children: [
                // [수정] const 제거 및 모드에 따른 텍스트 변경
                SizedBox(
                  width: 30,
                  child: Text(
                    widget.mode == ListMode.favorite ? "순서" : "순위",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 30, child: Text("찜", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 2, child: Text("금영", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 2, child: Text("TJ", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(flex: 4, child: Text("노래명 / 가수", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),

          // 2. 리스트 영역
          Expanded(
            child: RefreshIndicator(
              onRefresh: _handleRefresh,
              // [핵심] 마이페이지(favorite)일 때만 ReorderableListView 사용
              child: widget.mode == ListMode.favorite
                  ? ReorderableListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: songList.length,
                onReorder: (oldIndex, newIndex) async {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final Song item = songList.removeAt(oldIndex);
                    songList.insert(newIndex, item);
                  });
                  // 순서 변경 후 로컬 DB(SharedPreferences) 업데이트
                  await _updateSavedOrder();
                },
                itemBuilder: (context, index) {
                  return _buildSongRow(index, songList[index]);
                },
              )
                  : ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                // 일반 리스트는 광고 포함 개수 계산
                itemCount: songList.length + (songList.length ~/ adCount),
                itemBuilder: (context, index) {
                  // 광고 배치 로직
                  if ((index + 1) % (adCount + 1) == 0) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: AdWidgetContainer(adHeight: -1),
                    );
                  }
                  // 광고 제외한 실제 노래 인덱스 계산
                  var songIndex = index - ((index) ~/ (adCount + 1));
                  return _buildSongRow(songIndex, songList[songIndex]);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SongListBody extends StatefulWidget {
  const SongListBody({
    super.key,
    required this.songList,
    this.mode = ListMode.ranking, // 기본값은 랭킹
    this.modeValue = ""
  });

  final List<Song> songList;
  final ListMode mode;
  final String modeValue;

  @override
  SongListWidget createState() => SongListWidget(songList: songList);
}

class YoutubeWebView extends StatefulWidget {
  final String youtubeUrl;

  const YoutubeWebView({super.key, required this.youtubeUrl});

  @override
  State<YoutubeWebView> createState() => _YoutubeWebViewState();
}

class _YoutubeWebViewState extends State<YoutubeWebView> {

  late final WebViewController controller;

  @override
  void initState() {
    super.initState();

    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse(widget.youtubeUrl),
      );

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (url) async {
          await controller.runJavaScript('''
        document.addEventListener("fullscreenchange", function() {
          if (!document.fullscreenElement) {
            location.reload();
          }
        });
      ''');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: WebViewWidget(controller: controller),
    );
  }
}