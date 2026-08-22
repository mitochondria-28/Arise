import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/models/auth.dart';
import '../../core/network/api_client.dart';

class GrowthReportNotifier extends AsyncNotifier<AIAnalysisResponse?> {
  @override
  Future<AIAnalysisResponse?> build() async => null;

  Future<void> generate() async {
    state = const AsyncLoading();
    try {
      final dio = ref.read(dioProvider);
      final res =
          await dio.post<Map<String, dynamic>>('/ai/growth-report');
      state = AsyncData(AIAnalysisResponse.fromJson(res.data!));
    } on DioException catch (e) {
      state = AsyncError(fromDioError(e), StackTrace.current);
    }
  }
}

final growthReportProvider =
    AsyncNotifierProvider<GrowthReportNotifier, AIAnalysisResponse?>(
        GrowthReportNotifier.new);
