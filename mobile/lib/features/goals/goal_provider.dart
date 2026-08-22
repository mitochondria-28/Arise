import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/goal.dart';
import '../../core/network/api_client.dart';
import '../character/character_provider.dart';

class GoalListNotifier extends AsyncNotifier<List<GoalResponse>> {
  @override
  Future<List<GoalResponse>> build() => _fetch();

  Future<List<GoalResponse>> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/goals');
      final items = res.data!['goals'] as List;
      return items
          .map((e) => GoalResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(CreateGoalRequest req) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post<void>('/goals', data: req.toJson());
      state = await AsyncValue.guard(_fetch);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<CompleteGoalResponse> complete(
      String goalId, CompleteGoalRequest req) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/goals/$goalId/complete',
        data: req.toJson(),
      );
      final result = CompleteGoalResponse.fromJson(res.data!);
      // Refresh both goals and character after XP gain
      state = await AsyncValue.guard(_fetch);
      ref.invalidate(characterProvider);
      return result;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }
}

final goalListProvider =
    AsyncNotifierProvider<GoalListNotifier, List<GoalResponse>>(
        GoalListNotifier.new);
