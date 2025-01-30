import 'package:flutter/material.dart';
import 'package:hello_flutter/list.dart';
import 'package:hello_flutter/dto/singer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SingerPage extends StatelessWidget {

  const SingerPage({super.key});

  Future<List<Singer>> fetchSinger() async {
    return List.of({
      Singer(name: "1", imageUrl: "https://picsum.photos/250?image=9"),
      Singer(name: "2", imageUrl: "https://picsum.photos/250?image=10"),
      Singer(name: "3", imageUrl: "https://picsum.photos/250?image=11"),
      Singer(name: "4", imageUrl: "https://picsum.photos/250?image=12"),
      Singer(name: "5", imageUrl: "https://picsum.photos/250?image=13"),
      Singer(name: "6", imageUrl: "https://picsum.photos/250?image=14")
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: FutureBuilder<List<Singer>>(
              future: fetchSinger(), // API 호출 함수 연결
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
                                  modeValue: singer.name,
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
                                singer.imageUrl,
                                height: 120,
                                fit: BoxFit.cover, // 이미지 꽉 채우기
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(singer.name, style: TextStyle(fontSize: 16)),
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
