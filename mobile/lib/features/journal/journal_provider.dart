import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/journal.dart';
import '../../core/network/api_client.dart';

class JournalNotifier extends AsyncNotifier<JournalListResult> {
  @override
  Future<JournalListResult> build() => _fetch();

  Future<JournalListResult> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>(
        '/journal',
        queryParameters: {'limit': 50, 'offset': 0},
      );
      return JournalListResult.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<JournalEntry?> fetchToday() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<dynamic>('/journal/today');
      if (res.data == null) return null;
      return JournalEntry.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<JournalEntry> saveEntry({
    required String content,
    int? mood,
    String? entryDate,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{
        'content': content,
        if (mood != null) 'mood': mood,
        if (entryDate != null) 'entry_date': entryDate,
      };
      final res = await dio.post<Map<String, dynamic>>('/journal', data: body);
      final entry = JournalEntry.fromJson(res.data!);
      // Refresh list
      state = await AsyncValue.guard(_fetch);
      return entry;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<JournalEntry> generateReflection(String entryId) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/journal/$entryId/reflect');
      final entry = JournalEntry.fromJson(res.data!);
      // Refresh list
      state = await AsyncValue.guard(_fetch);
      return entry;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }
}

final journalProvider =
    AsyncNotifierProvider<JournalNotifier, JournalListResult>(
        JournalNotifier.new);
