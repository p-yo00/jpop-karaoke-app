import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hello_flutter/detail.dart';
import 'package:hello_flutter/dto/song.dart';

enum ListMode { ranking, singer, search, favorite }
const String baseUrl = String.fromEnvironment('API_BASE_URL');
const String apiPort = "8080";

class LoadSongList {

  static Future<List<Song>> loadSingerSongList(String singerId) async {
    final url = Uri.parse("$baseUrl:$apiPort/singer/$singerId/song");
    final response = await http.get(url);

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
    final response = await http.get(url);

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
    if (mode == ListMode.singer) {
      songList = LoadSongList.loadSingerSongList(modeValue);
    } else if (mode == ListMode.search) {
      songList = LoadSongList.loadSearchSongList(modeValue);
    } else {
      songList = SongListPage().loadBestSongList();
    }
  }
  final String title;
  final ListMode mode;
  final String modeValue;
  late final Future<List<Song>> songList;

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

  Future<List<Song>> loadBestSongList() async {
    final url = Uri.parse("$baseUrl:$apiPort/song/chart100");

    final response = await http.get(url);
    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      return jsonData.map((json) => Song.fromJson(json)).toList();
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


class SongListBody extends StatelessWidget {
  const SongListBody({super.key, required this.songList});
  final List<Song> songList;

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
                  const SizedBox(width: 30, child: Text("순위", textAlign: TextAlign.center)), // 인덱스
                  const SizedBox(width: 50, child: Text("앨범", textAlign: TextAlign.center)), // 이미지
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
                itemCount: songList.length,
                itemBuilder: (context, index) {
                  var song = songList[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailPage(song: song),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: Row(
                        children: [
                          // 인덱스
                          SizedBox(
                            width: 30,
                            child: Text((index+1).toString(), textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                          ),
                          // 이미지
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network("$baseUrl${song.albumImg}", width: 50, height: 50, fit: BoxFit.cover, 
                            errorBuilder: (context, error, stackTrace) {
                              return Image.asset('images/no_image.png', width: 50, height: 50, fit: BoxFit.cover);
                            }),
                          ),
                          const SizedBox(width: 10),
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