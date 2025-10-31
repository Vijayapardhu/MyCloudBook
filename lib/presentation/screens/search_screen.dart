import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../blocs/search/search_bloc.dart';
import '../widgets/main_scaffold.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController();

    return MainScaffold(
      title: 'Search',
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Search notes and pages...',
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
              onChanged: (value) {
                context.read<SearchBloc>().add(QueryChanged(value));
              },
            ),
          ),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state is SearchInitial) {
                  return const Center(
                    child: Text('Enter a search query to find notes and pages'),
                  );
                }

                if (state is SearchLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SearchError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: ${state.message}'),
                        ElevatedButton(
                          onPressed: () {
                            context.read<SearchBloc>().add(ExecuteSearch(controller.text));
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is SearchEmpty) {
                  return Center(
                    child: Text('No results found for "${state.query}"'),
                  );
                }

                if (state is SearchResults) {
                  if (state.results.isEmpty) {
                    return const Center(child: Text('No results found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.results.length,
                    itemBuilder: (context, index) {
                      final result = state.results[index];
                      final type = result['type'] as String;
                      final id = result['id'] as String;
                      final title = result['title'] as String? ?? 'Untitled';
                      final snippet = result['snippet'] as String?;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Icon(
                            type == 'note' ? Icons.note : Icons.description,
                          ),
                          title: Text(title),
                          subtitle: snippet != null ? Text(snippet) : null,
                          onTap: () {
                            if (type == 'note') {
                              context.go('/note/$id');
                            } else {
                              final noteId = result['note_id'] as String?;
                              if (noteId != null) {
                                context.go('/note/$noteId');
                              }
                            }
                          },
                        ),
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
