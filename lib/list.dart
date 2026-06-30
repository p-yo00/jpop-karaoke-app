import 'dart:async';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/bannerAd.dart';
import 'package:hello_flutter/dto/song.dart';
import 'package:hello_flutter/dto/collection.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum ListMode { collection, singer, search, favorite }
const String baseUrl = String.fromEnvironment('API_BASE_URL');
const String apiPort = "8080";

class LoadSongList {

  static Future<List<Song>> loadCollectionSongList(int id) async {
    final url = Uri.parse("$baseUrl:$apiPort/collections/$id");

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

  static Future<List<Song>> loadFavoriteSongs() async {
      final prefs = await SharedPreferences.getInstance();

      List<String>? jsonList = prefs.getStringList('favorites') ?? [];

      return jsonList.map((item) => Song.fromString(item)).toList();
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
  final String title;
  final ListMode mode;
  final String modeValue;

  const SongListPageWithAppBar({super.key, required this.title, required this.mode, required this.modeValue});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SongListBody(mode: mode, modeValue: modeValue),
    );
  }
}

class SongListPage extends StatelessWidget {
  const SongListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SongListBody(mode: ListMode.collection),
    );
  }
}

class SongListWidget extends State<SongListBody> {
  List<Song> songList = [];
  List<Collection> collectionList = [];
  final int adCount = 12;
  bool isSelected = false;
  int? expandedIndex;
  bool isYoutubeOn = false;
  bool isLoading = false;
  bool isCategoryExpanded = true;

  @override
  void initState() {
    super.initState();

    if (widget.mode == ListMode.collection) {
      _loadCollections();
    } else {
      handleRefresh();
    }

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

  // 컬렉션 조회
  Future<void> _loadCollections() async {
    final url = Uri.parse("$baseUrl:$apiPort/collections");
    final response = await http.get(url).timeout(
      Duration(seconds: 30),
      onTimeout: () => throw TimeoutException("요청 시간이 초과되었습니다."),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      final collections =
      jsonData.map((json) => Collection.fromJson(json)).toList();

      setState(() {
        collectionList = collections;
        if (collectionList.isNotEmpty) {
          widget.modeValue = collectionList[0].id;
          handleRefresh();
        }
      });

      return;
    }
    return Future.error("fail:load");
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
      return await LoadSongList.loadSingerSongList(widget.modeValue as String);
    } else if (widget.mode == ListMode.search) {
      return await LoadSongList.loadSearchSongList(widget.modeValue as String);
    } else if (widget.mode == ListMode.collection) {
      return await LoadSongList.loadCollectionSongList(widget.modeValue as int);
    } else if (widget.mode == ListMode.favorite) {
      return await LoadSongList.loadFavoriteSongs();
    }
    return songList;
  }

  Future<void> handleRefresh() async {
    setState(() {
      isLoading = true;
      songList = []; // 이전 리스트를 비워줘야 로딩바가 확실히 보임
    });

    try {
      List<Song> freshSongList = await loadSongList();
      setState(() {
        songList = freshSongList;
      });
    } catch (e) {
      print("로딩 에러: $e");
    } finally {
      // 2. 데이터 로딩이 끝나면 로딩바 제거
      setState(() {
        isLoading = false;
      });
    }
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
    if (isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      body: Column(
        children: [
          // 컬렉션 모드일 때 상단 카테고리 선택창 노출
          if (widget.mode == ListMode.collection) ...[
            // 1. 카테고리 리스트 (애니메이션 효과)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isCategoryExpanded ? 70 : 0, // 닫히면 높이가 0이 됨
              child: isCategoryExpanded
                  ? ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: collectionList.length,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                itemBuilder: (context, index) {
                  final cat = collectionList[index];
                  final isSelected = widget.modeValue == cat.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        widget.modeValue = cat.id;
                        handleRefresh();
                      });
                    },
                    child: Container(
                      width: 110,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.grey,
                        image: cat.imageUrl != null ? DecorationImage(
                          image: NetworkImage(cat.imageUrl!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(isSelected ? 0.2 : 0.5),
                            BlendMode.darken,
                          ),
                        ) : null,
                        border: isSelected ? Border.all(color: Colors.blue, width: 3) : null,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(cat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
                  : const SizedBox.shrink(),
            ),
            // 2. 접기/펴기 버튼
            GestureDetector(
              onTap: () => setState(() => isCategoryExpanded = !isCategoryExpanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 5),
                color: Colors.grey[200],
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(isCategoryExpanded ? "카테고리 접기 " : "카테고리 펼치기 ",
                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    Icon(isCategoryExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],

          // 1. 고정 헤더 영역
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.grey[300],
            child: Row(
              children: [
                SizedBox(
                  width: 30,
                  child: Text(
                    widget.mode == ListMode.collection ? "순위" : "순서",
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
              onRefresh: handleRefresh,
              child: widget.mode == ListMode.favorite
                  ? ReorderableListView.builder(
                itemCount: songList.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = songList.removeAt(oldIndex);
                    songList.insert(newIndex, item);
                  });
                  _updateSavedOrder();
                },
                itemBuilder: (context, index) => _buildSongRow(index, songList[index]),
              )
                  : ListView.builder(
                itemCount: songList.length + (songList.length ~/ adCount),
                itemBuilder: (context, index) {
                  if ((index + 1) % (adCount + 1) == 0) {
                    return AdWidgetContainer(adHeight: -1);
                  }
                  int songIndex = index - (index ~/ (adCount + 1));
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
  final ListMode mode;
  Object? modeValue;

  SongListBody({super.key, required this.mode, this.modeValue});

  @override
  State<SongListBody> createState() => SongListWidget();
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