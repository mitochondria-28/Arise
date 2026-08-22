import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/achievement.dart';
import '../../core/network/api_client.dart';

class AchievementNotifier extends AsyncNotifier<List<AchievementResponse>> {
  @override
  Future<List<AchievementResponse>> build() => _fetch();

  Future<List<AchievementResponse>> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<dynamic>>('/achievements');
      return res.data!
          .map((e) => AchievementResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<SyncResult> sync() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/achievements/sync');
      final result = SyncResult.fromJson(res.data!);
      // Refresh the list after sync
      state = await AsyncValue.guard(_fetch);
      return result;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }
}

final achievementProvider =
    AsyncNotifierProvider<AchievementNotifier, List<AchievementResponse>>(
        AchievementNotifier.new);
