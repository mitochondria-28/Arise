import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/app_exception.dart';
import '../../core/network/api_client.dart';
import 'stats_models.dart';

class StatsSummaryNotifier extends AsyncNotifier<StatsSummary> {
  @override
  Future<StatsSummary> build() => _fetch();

  Future<StatsSummary> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>('/stats/summary');
      return StatsSummary.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

class XPHistoryNotifier extends AsyncNotifier<XPHistory> {
  int _days = 30;

  @override
  Future<XPHistory> build() => _fetch();

  Future<XPHistory> _fetch() async {
    try {
      final dio = ref.read(dioProvider);
      final res = await dio.get<Map<String, dynamic>>(
        '/stats/xp-history',
        queryParameters: {'days': _days},
      );
      return XPHistory.fromJson(res.data!);
    } on DioException catch (e) {
      throw fromDioError(e);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> setDays(int days) async {
    _days = days;
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}

final statsSummaryProvider =
    AsyncNotifierProvider<StatsSummaryNotifier, StatsSummary>(
        StatsSummaryNotifier.new);

final xpHistoryProvider =
    AsyncNotifierProvider<XPHistoryNotifier, XPHistory>(XPHistoryNotifier.new);
