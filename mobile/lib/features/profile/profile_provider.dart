import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/user_profile.dart';
import '../../core/network/api_client.dart';

class ProfileNotifier extends AsyncNotifier<MeResponse> {
  @override
  Future<MeResponse> build() => _fetch();

  Future<MeResponse> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/users/me');
      return MeResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<MeResponse> updateProfile({
    String? displayName,
    String? bio,
    String? timezone,
    String? themePreference,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      final body = <String, dynamic>{
        if (displayName != null) 'display_name': displayName,
        if (bio != null) 'bio': bio,
        if (timezone != null) 'timezone': timezone,
        if (themePreference != null) 'theme_preference': themePreference,
      };
      final res = await dio.patch<Map<String, dynamic>>('/users/me/profile', data: body);
      final updated = MeResponse.fromJson(res.data!);
      state = AsyncData(updated);
      return updated;
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.post<void>('/users/me/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.delete<void>('/users/me', data: {'password': password});
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }
}

final profileProvider =
    AsyncNotifierProvider<ProfileNotifier, MeResponse>(ProfileNotifier.new);
