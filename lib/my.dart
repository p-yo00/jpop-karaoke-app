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
  // 2. 데이터를 불러오는 함수 (기존 로직 유지)
  Future<List<Song>> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? jsonList = prefs.getStringList('favorites');

    if (jsonList == null || jsonList.isEmpty) {
      return []; // 데이터가 없으면 빈 리스트 반환 (에러 방지)
    }

    return jsonList.map((item) => Song.fromString(item)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Song>>(
        future: _loadFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('불러오는데 실패했습니다.'));
          } else if (snapshot.hasData) {
            final favorites = snapshot.data!;
            if (favorites.isEmpty) {
              return const Center(child: Text('즐겨찾기한 노래가 없습니다.'));
            }
            // 4. 최신 데이터가 담긴 snapshot.data를 SongListBody에 전달
            return SongListBody(songList: favorites, mode: ListMode.favorite);
          } else {
            return const Center(child: Text('데이터가 없습니다.'));
          }
        },
      ),
    );
  }
}
