import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/l10n/app_l10n.dart';

class AppNavigation extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider);

    final items = [
      _NavItem(Icons.home_outlined, Icons.home, t.navHome, '/'),
      _NavItem(
          Icons.people_outline, Icons.people, t.navCandidatos, '/candidatos'),
      _NavItem(Icons.compare_arrows_outlined, Icons.compare_arrows,
          t.navComparar, '/comparar'),
      _NavItem(Icons.how_to_vote_outlined, Icons.how_to_vote, t.navMiVoto,
          '/mi-voto'),
      _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, t.navEncuestas,
          '/encuestas'),
      _NavItem(Icons.newspaper_outlined, Icons.newspaper, t.navNoticias,
          '/noticias'),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          items: items
              .map((item) => BottomNavigationBarItem(
                    icon: Icon(item.icon),
                    activeIcon: Icon(item.activeIcon),
                    label: item.label,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String path;

  const _NavItem(this.icon, this.activeIcon, this.label, this.path);
}
