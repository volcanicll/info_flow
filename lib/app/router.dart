import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:info_flow/features/signal_hub/presentation/pages/pulse_page.dart';
import 'package:info_flow/features/feed/presentation/pages/feed_page.dart';
import 'package:info_flow/features/reader/presentation/pages/reader_page.dart';
import 'package:info_flow/features/subscription/presentation/pages/subscription_page.dart';
import 'package:info_flow/features/ai_chat/presentation/pages/ai_chat_page.dart';
import 'package:info_flow/features/profile/presentation/pages/profile_page.dart';
import 'package:info_flow/features/search/presentation/pages/search_page.dart';
import 'package:info_flow/features/bookmark/presentation/pages/bookmark_page.dart';
import 'package:info_flow/features/crypto_radar/presentation/pages/crypto_radar_page.dart';
import 'package:info_flow/features/ai_models/presentation/pages/ai_models_page.dart';
import 'package:info_flow/features/precious_metals/presentation/pages/metals_page.dart';
import 'package:info_flow/shared/widgets/main_shell.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/market',
    debugLogDiagnostics: true,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/market',
                name: 'market',
                builder: (context, state) => const PulsePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/feed',
                name: 'feed',
                builder: (context, state) => const FeedPage(),
                routes: [
                  GoRoute(
                    path: 'subscription',
                    name: 'feedSubscription',
                    builder: (context, state) => const SubscriptionPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ai-chat',
                name: 'aiChat',
                builder: (context, state) => const AiChatPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookmark',
                name: 'bookmark',
                builder: (context, state) => const BookmarkPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/reader/:articleId',
        name: 'reader',
        builder: (context, state) {
          final articleId = state.pathParameters['articleId']!;
          return ReaderPage(articleId: articleId);
        },
      ),
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/crypto-radar',
        name: 'cryptoRadar',
        builder: (context, state) => const CryptoRadarPage(),
      ),
      GoRoute(
        path: '/ai-models',
        name: 'aiModels',
        builder: (context, state) => const AiModelsPage(),
      ),
      GoRoute(
        path: '/metals',
        name: 'metals',
        builder: (context, state) => const MetalsPage(),
      ),
    ],
  );
}
