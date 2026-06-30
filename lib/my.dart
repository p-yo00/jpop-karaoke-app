import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_flutter/dto/song.dart';
import 'package:hello_flutter/util/eventSender.dart';

import 'list.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final GlobalKey<SongListWidget> _songListKey = GlobalKey<SongListWidget>();

  // 2. 직접 노래 등록 다이얼로그
  void _showAddCustomSongDialog() {
    final titleController = TextEditingController();
    final singerController = TextEditingController();
    final kyController = TextEditingController(); // KY 컨트롤러 추가
    final tjController = TextEditingController(); // TJ 컨트롤러 추가

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            SizedBox(width: 10),
            Text("노래 직접 등록"),
          ],
        ),
        content: SingleChildScrollView( // 키보드 가림 방지
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "제목",
                  hintText: "노래 제목을 입력하세요",
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: singerController,
                decoration: const InputDecoration(
                  labelText: "가수",
                  hintText: "가수 이름을 입력하세요",
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  // KY 입력 필드
                  Expanded(
                    child: TextField(
                      controller: kyController,
                      keyboardType: TextInputType.number, // 숫자 키보드
                      decoration: InputDecoration(
                        labelText: "KY 번호",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // TJ 입력 필드
                  Expanded(
                    child: TextField(
                      controller: tjController,
                      keyboardType: TextInputType.number, // 숫자 키보드
                      decoration: InputDecoration(
                        labelText: "TJ 번호",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty && singerController.text.isNotEmpty) {
                await _saveCustomSong(
                  titleController.text,
                  singerController.text,
                  kyController.text,
                  tjController.text,
                );
                Navigator.pop(context);
              } else {
                // 제목/가수 미입력 시 안내 (선택사항)
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("제목과 가수를 입력해주세요.")),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("등록"),
          ),
        ],
      ),
    );
  }

  // 4. 직접 등록한 노래 저장 로직
  Future<void> _saveCustomSong(
      String title, String singer,
      String ky, String tj) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList('favorites') ?? [];

    // Song 객체 생성 (번호가 없으므로 빈값 처리)
    Song newSong = Song(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      originalTitle: "",
      singer: singer,
      ky: ky,
      tj: tj,
      youtubeUrl: "",
      favorite: true,
      albumImg: ""
    );

    favorites.add(jsonEncode(newSong.toJson()));

    EventSender.sendEvent(
        eventType: "FAVORITE_CUSTOM",
        payload: {
          "title": title,
          "singer": singer,
          "ky": ky,
          "tj": tj,
        });

    await prefs.setStringList('favorites', favorites);
    _songListKey.currentState?.handleRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 우측 하단에 등록 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomSongDialog,
        child: const Icon(Icons.add),
      ),
      body: SongListBody(key: _songListKey, mode: ListMode.favorite)
    );
  }
}
