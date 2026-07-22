import 'package:flutter/material.dart';
import 'package:hello_flutter/list.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  const SearchAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<SearchAppBar> createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openSearchPage({String? initialQuery}) {
    _controller.clear();

    final query = (initialQuery ?? _controller.text).trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchEntryPage(initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TextField(
          controller: _controller,
          readOnly: true,
          onTap: () => _openSearchPage(),
          decoration: InputDecoration(
            hintText: '가수나 노래를 검색해보세요.',
            suffixIcon: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => _openSearchPage(),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class SearchEntryPage extends StatefulWidget {
  final String initialQuery;

  const SearchEntryPage({super.key, this.initialQuery = ''});

  @override
  State<SearchEntryPage> createState() => _SearchEntryPageState();
}

class _SearchEntryPageState extends State<SearchEntryPage> {
  late final TextEditingController _controller;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _recentSearches = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveRecentSearches(List<String> searches) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('search_history', searches);
  }

  Future<void> _addRecentSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return;

    final nextSearches = <String>[trimmedQuery];
    for (final existing in _recentSearches) {
      if (existing != trimmedQuery) {
        nextSearches.add(existing);
      }
    }

    _recentSearches = nextSearches.take(3).toList();
    await _saveRecentSearches(_recentSearches);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _removeRecentSearch(String query) async {
    _recentSearches.remove(query);
    await _saveRecentSearches(_recentSearches);
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _performSearch(String? query) async {
    final trimmedQuery = (query ?? _controller.text).trim();
    if (trimmedQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('검색어를 입력해주세요.')),
      );
      return;
    }

    await _addRecentSearch(trimmedQuery);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => SongListPageWithAppBar(
          title: trimmedQuery,
          mode: ListMode.search,
          modeValue: trimmedQuery,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('검색'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '가수나 노래를 검색해보세요.',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _performSearch(null),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onSubmitted: (value) => _performSearch(value),
            ),
            const SizedBox(height: 20),
            const Text(
              '최근 검색어',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_recentSearches.isEmpty)
              const Text('아직 최근 검색어가 없어요.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _recentSearches
                    .map(
                      (query) => InputChip(
                        label: Text(query),
                        onPressed: () => _performSearch(query),
                        onDeleted: () => _removeRecentSearch(query),
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
