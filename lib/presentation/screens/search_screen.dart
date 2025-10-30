import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../data/services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final SearchService _searchService = SearchService();
  final List<Map<String, dynamic>> _results = <Map<String, dynamic>>[];
  Timer? _debounce;

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final res = await _searchService.search(value);
      if (!mounted) return;
      setState(() {
        _results
          ..clear()
          ..addAll(res);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search notes, pages, tags...',
              ),
              onChanged: _onChanged,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No results'))
                  : ListView(
                      children: [
                        ..._buildGroup('Notes', 'note'),
                        const SizedBox(height: 12),
                        ..._buildGroup('Pages (OCR)', 'page'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroup(String title, String type) {
    final items = _results.where((e) => e['type'] == type).toList();
    if (items.isEmpty) return <Widget>[];
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleLarge),
      ),
      ...List.generate(items.length, (index) {
        final item = items[index];
        final id = type == 'note' ? item['id'] as String : item['note_id'] as String;
        return Column(
          children: [
            ListTile(
              leading: Icon(type == 'note' ? Icons.note : Icons.image),
              title: Text(item['title'] as String),
              subtitle: Text(item['snippet'] as String? ?? ''),
              onTap: () => context.go('/note/$id'),
            ),
            const Divider(height: 1),
          ],
        );
      }),
    ];
  }
}


