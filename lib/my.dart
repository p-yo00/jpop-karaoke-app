import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_flutter/dto/song.dart';

import 'list.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  final GlobalKey<SongListWidget> _songListKey = GlobalKey<SongListWidget>();

  Future<List<String>> _getFolderSongs(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('folder_$folderName') ?? [];
  }

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

  // 폴더 클릭 시 이동하는 코드 예시
  void _openFolder(String folderName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(folderName)),
          body: SongListBody(
            mode: ListMode.favorite,
            folderName: folderName, // 폴더명을 넘겨서 해당 데이터만 로드하게 수정
          ),
        ),
      ),
    );
  }

  // 1. 폴더 목록 가져오기
  Future<List<String>> _getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    // 앱 처음 실행 시 마이그레이션 수행
    await _migrateOldData();
    return prefs.getStringList('folder_list') ?? ['기본 폴더'];
  }

  Widget _buildAddFolderButton() {
    return GestureDetector(
      onTap: _showAddFolderDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 40),
            SizedBox(height: 8),
            Text("새 폴더"),
          ],
        ),
      ),
    );
  }

  // 2. 새 폴더 추가 버튼 UI
  Widget _buildFolderCard(String folderName) {
    return GestureDetector(
        onTap: () => _openFolder(folderName),
      child: FutureBuilder<List<String>>(
        future: _getFolderSongs(folderName), // 해당 폴더의 노래 리스트를 가져옴
        builder: (context, songSnapshot) {
          final songs = songSnapshot.data ?? [];
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, spreadRadius: 2)
              ],
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 상단: 폴더 아이콘과 곡 수
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.folder, color: Colors.amber, size: 30),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "${songs.length}곡",
                          style: TextStyle(fontSize: 11, color: Colors.blue[700], fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                // 중간: 폴더 이름
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    folderName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Spacer(),
                // 하단: 노래 제목 미리보기 (텍스트 위주)
                if (songs.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: songs.take(2).map((s) {
                        final song = Song.fromJson(jsonDecode(s));
                        return Text(
                          "• ${song.title}",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text("비어 있음", style: TextStyle(fontSize: 10, color: Colors.black12)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

// 3. 새 폴더 이름 입력 다이얼로그
  void _showAddFolderDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("새 폴더 생성"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "폴더 이름을 입력하세요"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                List<String> folders = prefs.getStringList('folder_list') ?? ['기본 폴더'];
                if (!folders.contains(controller.text)) {
                  folders.add(controller.text);
                  await prefs.setStringList('folder_list', folders);
                  setState(() {}); // 화면 새로고침
                }
                Navigator.pop(context);
              }
            },
            child: const Text("생성"),
          ),
        ],
      ),
    );
  }

  // my.dart의 폴더 리스트 화면 부분
  Widget _buildFolderList() {
    return FutureBuilder(
      future: _getFolders(), // 폴더 목록 가져오는 함수
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        List<String> folders = snapshot.data as List<String>;

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
          ),
          itemCount: folders.length + 1, // +1은 '새 폴더 추가' 버튼
          itemBuilder: (context, index) {
            if (index == folders.length) {
              return _buildAddFolderButton();
            }

            return _buildFolderCard(folders[index]);
          },
        );
      },
    );
  }

  Future<void> _migrateOldData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? oldFavorites = prefs.getStringList('favorites');

    if (oldFavorites != null && oldFavorites.isNotEmpty) {
      // 기존 데이터가 있으면 '기본 폴더'로 이동
      List<String> folders = prefs.getStringList('folder_list') ?? ['기본 폴더'];
      if (!folders.contains('기본 폴더')) folders.add('기본 폴더');

      await prefs.setStringList('folder_list', folders);
      await prefs.setStringList('folder_기본 폴더', oldFavorites);

      // 이동 후 기존 데이터 삭제 (중복 방지)
      await prefs.remove('favorites');
    }
  }

  // 4. 직접 등록한 노래 저장 로직
  Future<void> _saveCustomSong(String title, String singer, String ky, String tj) async {
    final prefs = await SharedPreferences.getInstance();
    // 수정: 'favorites' 대신 'folder_기본 폴더' 사용
    List<String> favorites = prefs.getStringList('folder_기본 폴더') ?? [];

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
    await prefs.setStringList('folder_기본 폴더', favorites);

    // 폴더 리스트 화면을 새로고침
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 우측 하단에 등록 버튼 추가
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCustomSongDialog,
        child: const Icon(Icons.add),
      ),
      body: _buildFolderList(),
    );
  }
}
