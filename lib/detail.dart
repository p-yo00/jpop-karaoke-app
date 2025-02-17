import 'package:flutter/material.dart';
import 'package:hello_flutter/dto/song.dart';

class DetailPage extends StatelessWidget {

  final Song song;
  const DetailPage({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(song.title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(song.albumImg, width: 150, height: 150,
            errorBuilder: (context, error, stackTrace) {
              return Image.asset('images/no_image.png', width: 150, height: 150);
            }),
            const SizedBox(height: 10),
            Text(song.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(song.singer, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}