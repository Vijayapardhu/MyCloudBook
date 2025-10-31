import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'dart:async';
import '../../../data/services/search_service.dart';

// Events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
  @override
  List<Object?> get props => [];
}

class QueryChanged extends SearchEvent {
  final String query;
  const QueryChanged(this.query);
  @override
  List<Object?> get props => [query];
}

class ExecuteSearch extends SearchEvent {
  final String query;
  const ExecuteSearch(this.query);
  @override
  List<Object?> get props => [query];
}

// States
abstract class SearchState extends Equatable {
  const SearchState();
  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {
  const SearchInitial();
}

class SearchLoading extends SearchState {
  const SearchLoading();
}

class SearchResults extends SearchState {
  final List<Map<String, dynamic>> results;
  const SearchResults(this.results);
  @override
  List<Object?> get props => [results];
}

class SearchEmpty extends SearchState {
  final String query;
  const SearchEmpty(this.query);
  @override
  List<Object?> get props => [query];
}

class SearchError extends SearchState {
  final String message;
  const SearchError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final SearchService _searchService;
  Timer? _debounceTimer;

  SearchBloc({SearchService? searchService})
      : _searchService = searchService ?? SearchService(),
        super(const SearchInitial()) {
    on<QueryChanged>(_onQueryChanged);
    on<ExecuteSearch>(_onExecuteSearch);
  }

  void _onQueryChanged(QueryChanged event, Emitter<SearchState> emit) {
    _debounceTimer?.cancel();
    
    if (event.query.isEmpty) {
      emit(const SearchInitial());
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      add(ExecuteSearch(event.query));
    });
  }

  Future<void> _onExecuteSearch(ExecuteSearch event, Emitter<SearchState> emit) async {
    if (event.query.trim().isEmpty) {
      emit(const SearchInitial());
      return;
    }

    emit(const SearchLoading());
    
    try {
      final results = await _searchService.search(event.query);
      
      if (results.isEmpty) {
        emit(SearchEmpty(event.query));
      } else {
        emit(SearchResults(results));
      }
    } catch (e) {
      emit(SearchError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}
