import 'package:go_router/go_router.dart';
import '../../features/home/home_screen.dart';
import '../../features/candidates/candidates_screen.dart';
import '../../features/profile/candidate_profile_screen.dart';
import '../../features/compare/compare_screen.dart';
import '../../features/mi_voto/mi_voto_screen.dart';
import '../../features/polls/polls_screen.dart';
import '../../features/news/news_screen.dart';
import '../../features/como_votar/como_votar_screen.dart';
import '../../widgets/navigation/app_navigation.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  debugLogDiagnostics: false,
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppNavigation(navigationShell: navigationShell),
      branches: [
        // 0 — Home
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const HomeScreen(),
            ),
          ),
        ]),

        // 1 — Candidatos
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/candidatos',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CandidatosScreen(),
            ),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CandidatoProfileScreen(
                  candidatoId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ]),

        // 2 — Comparar
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/comparar',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CompararScreen(),
            ),
          ),
        ]),

        // 3 — Mi Voto
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/mi-voto',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MiVotoScreen(),
            ),
            routes: [
              GoRoute(
                path: 'como-votar',
                builder: (context, state) => const ComoVotarScreen(),
              ),
            ],
          ),
        ]),

        // 4 — Encuestas
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/encuestas',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EncuestasScreen(),
            ),
          ),
        ]),

        // 5 — Noticias
        StatefulShellBranch(routes: [
          GoRoute(
            path: '/noticias',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: NoticiasScreen(),
            ),
          ),
        ]),
      ],
    ),
  ],
);
