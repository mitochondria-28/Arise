import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/mission.dart';
import '../../core/network/api_client.dart';
import '../character/character_provider.dart';

class MissionListNotifier extends AsyncNotifier<List<MissionResponse>> {
  @override
  Future<List<MissionResponse>> build() => _fetch();

  Future<List<MissionResponse>> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/missions');
      final items = res.data!['missions'] as List;
      return items
          .map((e) => MissionResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> create(CreateMissionRequest req) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post<void>('/missions', data: req.toJson());
      state = await AsyncValue.guard(_fetch);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<CheckinResponse> checkin(String missionId, CheckinRequest req) async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.post<Map<String, dynamic>>(
        '/missions/$missionId/checkin',
        data: req.toJson(),
      );
      final result = CheckinResponse.fromJson(res.data!);
      state = await AsyncValue.guard(_fetch);
      ref.invalidate(characterProvider);
      return result;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }
}

final missionListProvider =
    AsyncNotifierProvider<MissionListNotifier, List<MissionResponse>>(
        MissionListNotifier.new);
