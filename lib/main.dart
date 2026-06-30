import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hello_flutter/list.dart';
import 'package:hello_flutter/singer.dart';
import 'package:hello_flutter/my.dart';
import 'package:hello_flutter/searchAppBar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // 애드몹 초기화
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jpop-Karaoke',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [SongListPage(), SingerPage(), MyPage()];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // 1. 건의사항 다이얼로그 함수 추가
  void _showSuggestionDialog() {
    TextEditingController suggestionController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("건의사항 보내기"),
          content: TextField(
            controller: suggestionController,
            maxLines: 3,
            decoration: const InputDecoration(
              hintText: "내용을 입력해주세요.",
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
            ElevatedButton(
              onPressed: () async {
                String content = suggestionController.text;
                if (content.isEmpty) return;

                await sendSuggestion(content);

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("소중한 의견 감사합니다."),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text("보내기"),
            ),
          ],
        );
      },
    );
  }

  Future<void> sendSuggestion(String content) async {
    final url = Uri.parse("$baseUrl:$apiPort/suggestion");

    await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "content": content,
      }),
    ).timeout(const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("J-pop 노래방 번호 검색"),
        // 2. 앱 이름 우측에 아이콘 추가
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note), // 건의 아이콘
            onPressed: _showSuggestionDialog,
            tooltip: '건의하기',
          ),
          IconButton(
            icon: const Icon(Icons.settings), // 설정 아이콘
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            tooltip: '설정',
          ),
          const SizedBox(width: 8),
        ],
        bottom: SearchAppBar()
      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.music_note),
            label: '탐색',
          ),
          NavigationDestination(
            icon: Icon(Icons.album),
            label: '가수별',
          ),
          NavigationDestination(
            icon: Icon(Icons.star),
            label: 'My Music',
          ),
        ],
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isYoutubeOn = true;

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 2. 시작할 때 설정 불러오기
  }

  // 설정 불러오기 함수
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // 'isYoutubeOn' 키로 저장된 값을 가져옴 (없으면 true)
      _isYoutubeOn = prefs.getBool('isYoutubeOn') ?? true;
    });
  }

  // 설정 저장하기 함수
  Future<void> _saveSettings(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isYoutubeOn', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("설정")),
      body: ListView(
        children: [
          CheckboxListTile(
            title: const Text("곡 클릭 시 유튜브 영상 재생"),
            subtitle: const Text("노래를 누르면 유튜브 영상을 띄워 음악을 감상할 수 있습니다."),
            value: _isYoutubeOn,
            onChanged: (val) {
              setState(() {
                _isYoutubeOn = val!;
              });
              _saveSettings(val!);
            },
            secondary: const Icon(Icons.play_circle_fill, color: Colors.red), // 유튜브 느낌 아이콘
          )
        ],
      ),
    );
  }
}
