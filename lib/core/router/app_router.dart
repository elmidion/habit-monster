import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/providers/collection_provider.dart';
import '../../features/achievements/achievements_screen.dart';
import '../../features/collection/collection_screen.dart';
import '../../features/creature_detail/creature_detail_screen.dart';
import '../../features/hatch/hatch_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/parent/parent_screen.dart';
import '../../features/report/report_screen.dart';
import '../../features/skill_selection/skill_selection_screen.dart';
import '../../features/stats/account_stats_screen.dart';
import '../../features/summon/summon_screen.dart';

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(Ref ref) {
    ref.listen<AsyncValue>(collectionProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: (context, state) {
      final collection = ref.read(collectionProvider).valueOrNull;
      if (collection == null) return null;

      final hasHatched = collection.any((c) => c.stage.isHatched);
      final onHatch = state.uri.path.startsWith('/hatch');

      if (!hasHatched && !onHatch && collection.isNotEmpty) {
        return '/hatch/${collection.first.id}';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/home',       builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/collection', builder: (_, __) => const CollectionScreen()),
      GoRoute(path: '/summon',     builder: (_, __) => const SummonScreen()),
      GoRoute(
        path: '/hatch/:id',
        builder: (_, state) =>
            HatchScreen(eggId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/creature',     builder: (_, __) => const CreatureDetailScreen()),
      GoRoute(path: '/achievements', builder: (_, __) => const AchievementsScreen()),
      GoRoute(path: '/history',      builder: (_, __) => const HistoryScreen()),
      GoRoute(path: '/stats',        builder: (_, __) => const AccountStatsScreen()),
      GoRoute(path: '/parent',       builder: (_, __) => const ParentScreen()),
      GoRoute(path: '/report',       builder: (_, __) => const ReportScreen()),
      GoRoute(path: '/skill-selection', builder: (_, __) => const SkillSelectionScreen()),
    ],
  );
});
