import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/feed/presentation/pages/feed_page.dart';
import '../../features/reader/presentation/pages/reader_page.dart';
import '../../features/subscription/presentation/pages/subscription_page.dart';
import '../../features/ai_chat/presentation/pages/ai_chat_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/bookmark/presentation/pages/bookmark_page.dart';
import '../../features/crypto_radar/presentation/pages/crypto_radar_page.dart';
import '../shared/widgets/main_shell.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
GoRouter goRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/feed',
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
                path: '/feed',
                name: 'feed',
                builder: (context, state) => const FeedPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/subscription',
                name: 'subscription',
                builder: (context, state) => const SubscriptionPage(),
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
    ],
  );
}
