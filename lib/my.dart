import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hello_flutter/dto/song.dart';

import 'list.dart';

const List<Color> folderColors = [
  Colors.amber,
  Colors.redAccent,
  Colors.blueAccent,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.pinkAccent,
  Colors.orangeAccent,
  Colors.cyan,
];

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
  bool isReorderMode = false; // 순서 편집 모드 여부
  List<String> folderList = []; // 로컬에서 관리할 폴더 리스트

  void _onReorder(int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final String item = folderList.removeAt(oldIndex);
      folderList.insert(newIndex, item);
    });

    // SharedPreferences에 변경된 순서 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('folder_list', folderList);
  }

  Future<List<String>> _getFolderSongs(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('folder_$folderName') ?? [];
  }

  // 폴더 클릭 시 이동하는 코드 예시
  void _openFolder(String folderName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text(folderName)),
          body: SongListBody(
            mode: ListMode.favorite,
            folderName: folderName,
          ),
        ),
      ),
    );

    setState(() {
    });
  }

  // 1. 폴더 목록 가져오기
  Future<List<String>> _getFolders() async {
    final prefs = await SharedPreferences.getInstance();
    // 앱 처음 실행 시 마이그레이션 수행
    await _migrateOldData();
    return prefs.getStringList('folder_list') ?? ['기본 폴더'];
  }

  // 특정 폴더의 색상을 가져오는 함수
  Future<Color> _getFolderColor(String folderName) async {
    final prefs = await SharedPreferences.getInstance();
    String? colorMapJson = prefs.getString('folder_colors');
    if (colorMapJson != null) {
      Map<String, dynamic> colorMap = jsonDecode(colorMapJson);
      if (colorMap.containsKey(folderName)) {
        return Color(colorMap[folderName]); // 저장된 색상 반환
      }
    }
    return Colors.amber; // 기본값
  }

// 폴더 색상을 저장하는 함수
  Future<void> _setFolderColor(String folderName, Color color) async {
    final prefs = await SharedPreferences.getInstance();
    String? colorMapJson = prefs.getString('folder_colors');
    Map<String, dynamic> colorMap = colorMapJson != null ? jsonDecode(colorMapJson) : {};

    colorMap[folderName] = color.value; // Color 객체를 정수값으로 저장
    await prefs.setString('folder_colors', jsonEncode(colorMap));
    setState(() {}); // 화면 갱신
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

  void _showColorPickerDialog(String folderName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("'$folderName' 색상 변경"),
        content: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: folderColors.map((color) {
            return GestureDetector(
              onTap: () {
                _setFolderColor(folderName, color);
                Navigator.pop(context);
              },
              child: CircleAvatar(backgroundColor: color, radius: 20),
            );
          }).toList(),
        ),
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

  Widget _buildFolderGrid(List<String> folders) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 1.3,
      ),
      itemCount: folders.length + 1,
      itemBuilder: (context, index) {
        if (index == folders.length) return _buildAddFolderButton();

        final folderName = folders[index];
        return FutureBuilder<Color>(
          future: _getFolderColor(folderName),
          builder: (context, colorSnapshot) {
            final folderColor = colorSnapshot.data ?? Colors.amber;

            return GestureDetector(
              onTap: () => _openFolder(folderName),
              child: FutureBuilder<List<String>>(
                future: _getFolderSongs(folderName),
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
                        // 1. 상단: 폴더 아이콘과 곡 수
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Icon(Icons.folder, color: folderColor, size: 30),
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
                        // 2. 중간: 폴더 이름
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
                        // 3. 하단: 노래 제목 미리보기
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 보관함"),
        actions: [
          // 순서 변경 모드 토글 버튼
          IconButton(
            icon: Icon(isReorderMode ? Icons.check_circle : Icons.reorder),
            color: isReorderMode ? Colors.blue : Colors.black,
            onPressed: () => setState(() => isReorderMode = !isReorderMode),
          ),
        ],
      ),
      body: FutureBuilder<List<String>>(
        future: _getFolders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 처음 데이터를 가져올 때만 리스트 초기화
          if (folderList.isEmpty || folderList.length != snapshot.data!.length) {
            folderList = snapshot.data!;
          }

          if (isReorderMode) {
            // --- 1. 순서 편집 모드 (리스트 형태) ---
            return ReorderableListView(
              padding: const EdgeInsets.all(10),
              onReorder: _onReorder,
              children: folderList.map((folder) {
                // 각 항목마다 저장된 색상을 불러옴
                return FutureBuilder<Color>(
                  key: ValueKey(folder), // ReorderableListView는 최상위 자식에 Key가 있어야 함
                  future: _getFolderColor(folder),
                  builder: (context, colorSnapshot) {
                    final folderColor = colorSnapshot.data ?? Colors.amber;

                    return ListTile(
                      key: ValueKey(folder),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(folder, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("클릭하여 색상 변경", style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: Icon(Icons.folder, color: folderColor), // 저장된 색상 적용
                      tileColor: Colors.grey[50],
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () => _showColorPickerDialog(folder), // 여기서 클릭 시 색상 변경
                    );
                  },
                );
              }).toList(),
            );
          } else {
            // --- 2. 일반 모드 (기존 그리드 형태) ---
            return _buildFolderGrid(folderList);
          }
        },
      ),
    );
  }
}
