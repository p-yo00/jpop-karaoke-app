import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/list.dart';
import 'package:hello_flutter/dto/singer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingerPage extends StatelessWidget {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL');
  static const String apiPort = "8080";

  const SingerPage({super.key});

  Future<List<Singer>> loadSingerList() async {
    final url = Uri.parse("$baseUrl:$apiPort/singer");
    final response = await http.get(url);

    if (response.statusCode == 200) {
      Map<String, dynamic> body = jsonDecode(utf8.decode(response.bodyBytes));
      final List<dynamic> jsonData = body['data'];

      return jsonData.map((json) => Singer.fromJson(json)).toList();
    }

    return Future.error("fail:load");
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Singer>>(
              future: loadSingerList(), // API 호출 함수 연결
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                return Center(child: Text('불러오는데 실패했습니다.'));
                } else if (snapshot.hasData) {
                  final List<Singer> singerList = snapshot.data!;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 한 줄에 2개
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: singerList.length,
                    itemBuilder: (context, index) {
                      final singer = singerList[index]; // 현재 아이템 정보 가져오기

                      return GestureDetector( // 클릭 감지를 위해 GestureDetector 사용
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SongListPageWithAppBar(
                                  title: singer.name,
                                  mode: ListMode.singer,
                                  modeValue: singer.id.toString(),
                              ),
                            ),
                          );
                        },
                        child: Card(
                          elevation: 4, // 그림자 효과
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // 카드 모서리 둥글게
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Image.network(
                                "$baseUrl${singer.profileImg}",
                                height: 130,
                                fit: BoxFit.cover, // 이미지 꽉 채우기
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.asset('images/no_image.png', height: 130, fit: BoxFit.cover);
                                },
                              ),
                              Spacer(flex: 1),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AutoSizeText(singer.name,
                                  style: TextStyle(fontSize: 24, fontFamily: 'NotoSans'),
                                  maxLines: 1,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: AutoSizeText(singer.originalName ?? "",
                                  style: TextStyle(fontSize: 18, fontFamily: 'NotoSans'),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        )
                      );
                    }
                  );
                } else {
                  return Center(child: Text('데이터가 없습니다.'));
                }
              }
        ),
    )
    );
  }
}
