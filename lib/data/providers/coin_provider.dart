import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/hive_service.dart';
import '../../core/utils/app_clock.dart';

const _coinKey = 'coin_balance';
const _rateKey = 'coin_exchange_rate';
const _coinPerMissionKey = 'coin_per_mission';
const _exchangeHistoryKey = 'coin_exchange_history';

// ── 코인 잔액 ─────────────────────────────────────────────────────────────────
final coinBalanceProvider =
    NotifierProvider<CoinBalanceNotifier, int>(CoinBalanceNotifier.new);

class CoinBalanceNotifier extends Notifier<int> {
  @override
  int build() {
    return HiveService.settings.get(_coinKey, defaultValue: 0) as int;
  }

  Future<void> add(int amount) async {
    state = state + amount;
    await HiveService.settings.put(_coinKey, state);
  }

  /// 용돈 교환: 코인 차감. 잔액 부족 시 false.
  Future<bool> spend(int amount) async {
    if (state < amount) return false;
    state = state - amount;
    await HiveService.settings.put(_coinKey, state);
    return true;
  }
}

// ── 환율 (코인 1개당 원) ──────────────────────────────────────────────────────
final coinExchangeRateProvider =
    NotifierProvider<CoinExchangeRateNotifier, int>(
        CoinExchangeRateNotifier.new);

class CoinExchangeRateNotifier extends Notifier<int> {
  @override
  int build() {
    return HiveService.settings.get(_rateKey, defaultValue: 100) as int;
  }

  Future<void> setRate(int rate) async {
    state = rate;
    await HiveService.settings.put(_rateKey, state);
  }
}

// ── 미션당 코인 ───────────────────────────────────────────────────────────────
final coinPerMissionProvider =
    NotifierProvider<CoinPerMissionNotifier, int>(CoinPerMissionNotifier.new);

class CoinPerMissionNotifier extends Notifier<int> {
  @override
  int build() {
    return HiveService.settings.get(_coinPerMissionKey, defaultValue: 1) as int;
  }

  Future<void> set(int amount) async {
    state = amount;
    await HiveService.settings.put(_coinPerMissionKey, state);
  }
}

// ── 교환 내역 ─────────────────────────────────────────────────────────────────
class ExchangeRecord {
  final DateTime date;
  final int coins;
  final int won;

  const ExchangeRecord({
    required this.date,
    required this.coins,
    required this.won,
  });

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'coins': coins,
    'won': won,
  };

  factory ExchangeRecord.fromJson(Map<String, dynamic> json) {
    return ExchangeRecord(
      date: DateTime.parse(json['date'] as String),
      coins: json['coins'] as int,
      won: json['won'] as int,
    );
  }
}

final exchangeHistoryProvider =
    NotifierProvider<ExchangeHistoryNotifier, List<ExchangeRecord>>(
        ExchangeHistoryNotifier.new);

class ExchangeHistoryNotifier extends Notifier<List<ExchangeRecord>> {
  @override
  List<ExchangeRecord> build() {
    final raw = HiveService.settings.get(_exchangeHistoryKey) as String?;
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ExchangeRecord.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<void> _persist() async {
    await HiveService.settings.put(
      _exchangeHistoryKey,
      jsonEncode(state.map((r) => r.toJson()).toList()),
    );
  }

  /// 용돈 교환 실행
  Future<bool> exchange(int coins) async {
    final rate = ref.read(coinExchangeRateProvider);
    final spent = await ref.read(coinBalanceProvider.notifier).spend(coins);
    if (!spent) return false;

    final record = ExchangeRecord(
      date: AppClock.now(),
      coins: coins,
      won: coins * rate,
    );
    state = [...state, record];
    await _persist();
    return true;
  }
}
