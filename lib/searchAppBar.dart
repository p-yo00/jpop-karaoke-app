import 'package:flutter/material.dart';
import 'package:hello_flutter/list.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    void searchSong() {
      String query = controller.text;
      print(query);
      if (query.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("검색어를 입력해주세요.")));
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SongListPageWithAppBar(
                title: query, mode: ListMode.search, modeValue: query)),
      );
    }

    return PreferredSize(
      preferredSize: Size.fromHeight(60), // 검색창 높이
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: '검색어를 입력하세요',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: searchSong,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onSubmitted: (value) => searchSong(),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
