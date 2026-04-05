import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/storage/hive_service.dart';
import '../../domain/enums/app_mode.dart';

// ── App Mode ───────────────────────────────────────────────────────────────
final appModeProvider = StateNotifierProvider<AppModeNotifier, AppMode>(
  (ref) => AppModeNotifier(),
);

class AppModeNotifier extends StateNotifier<AppMode> {
  AppModeNotifier() : super(AppMode.child);

  void switchToParent() => state = AppMode.parent;
  void switchToChild() => state = AppMode.child;
  void toggle() =>
      state = state == AppMode.child ? AppMode.parent : AppMode.child;
}

// ── Parent PIN ─────────────────────────────────────────────────────────────
final parentPinProvider = Provider<String>((ref) {
  return HiveService.settings.get(
        AppConstants.keyParentPin,
        defaultValue: AppConstants.defaultParentPin,
      ) as String;
});

bool verifyParentPin(WidgetRef ref, String input) {
  return input == ref.read(parentPinProvider);
}
