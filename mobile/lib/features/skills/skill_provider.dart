import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/skill.dart';
import '../../core/network/api_client.dart';

class SkillCatalogNotifier extends AsyncNotifier<List<SkillResponse>> {
  @override
  Future<List<SkillResponse>> build() => _fetch();

  Future<List<SkillResponse>> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<dynamic>>('/skills');
      return res.data!
          .map((e) => SkillResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final skillCatalogProvider =
    AsyncNotifierProvider<SkillCatalogNotifier, List<SkillResponse>>(
        SkillCatalogNotifier.new);

class UserSkillsNotifier extends AsyncNotifier<List<UserSkillResponse>> {
  @override
  Future<List<UserSkillResponse>> build() => _fetch();

  Future<List<UserSkillResponse>> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<List<dynamic>>('/skills/me');
      return res.data!
          .map((e) => UserSkillResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<UserSkillResponse> unlock(String skillId) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>('/skills/$skillId/unlock');
      final us = UserSkillResponse.fromJson(res.data!);
      state = await AsyncValue.guard(_fetch);
      return us;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<PracticeResult> practice(
    String skillId, {
    required String notes,
    int? durationMinutes,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/skills/$skillId/practice',
        data: {
          'notes': notes,
          if (durationMinutes != null) 'duration_minutes': durationMinutes,
        },
      );
      final result = PracticeResult.fromJson(res.data!);
      state = await AsyncValue.guard(_fetch);
      return result;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }
}

final userSkillsProvider =
    AsyncNotifierProvider<UserSkillsNotifier, List<UserSkillResponse>>(
        UserSkillsNotifier.new);
