import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hello_flutter/list.dart';
import 'package:hello_flutter/singer.dart';
import 'package:hello_flutter/my.dart';
import 'package:hello_flutter/searchAppBar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("J-pop 노래방 번호 검색"),
        bottom: SearchAppBar()
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
