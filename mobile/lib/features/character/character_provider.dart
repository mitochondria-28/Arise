import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/character.dart';
import '../../core/network/api_client.dart';

class CharacterNotifier extends AsyncNotifier<CharacterResponse> {
  @override
  Future<CharacterResponse> build() => _fetch();

  Future<CharacterResponse> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/character');
      return CharacterResponse.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final characterProvider =
    AsyncNotifierProvider<CharacterNotifier, CharacterResponse>(
        CharacterNotifier.new);
