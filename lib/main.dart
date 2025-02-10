import 'package:flutter/material.dart';
import 'package:hello_flutter/list.dart';
import 'package:hello_flutter/singer.dart';
import 'package:hello_flutter/my.dart';

void main() {
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
  final TextEditingController _controller = TextEditingController();

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _searchSong() {
    String query = _controller.text;
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("검색어를 입력해주세요."))
      );
      return;
    }
    print("검색어: $query"); // 실제 검색 기능 추가 가능

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SongListPageWithAppBar(
            title: query,
            mode: ListMode.search,
            modeValue: query
        )
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("J-pop 노래방 번호 검색"),

        // 검색창
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60), // 검색창 높이
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '검색어를 입력하세요',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchSong,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) => _searchSong(),
            ),
          ),
        ),

      ),

      body: _pages[_currentIndex],

      bottomNavigationBar: NavigationBar(
        destinations: [
          NavigationDestination(
            icon: Badge(
              child: Icon(Icons.music_note),
            ),
            label: '인기차트',
          ),
          NavigationDestination(
            icon: Badge(
              child: Icon(Icons.album),
            ),
            label: '가수별',
          ),
          NavigationDestination(
            icon: Badge(
              child: Icon(Icons.star),
            ),
            label: 'My Music',
          ),
        ],
        selectedIndex: _currentIndex,
        onDestinationSelected: _onItemTapped,
      ),
    );
  }
}
