import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/app_providers.dart';

class AppShell extends ConsumerWidget {
  const AppShell({required this.child, super.key});

  final Widget child;

  static const paths = [
    '/app/home',
    '/app/products',
    '/app/scan',
    '/app/repairs',
    '/app/profile',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final selected = paths.indexWhere((path) => location.startsWith(path));
    final selectedIndex = selected < 0 ? 0 : selected;
    final profile = ref.watch(currentProfileProvider).asData?.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final desktop = constraints.maxWidth >= 900;
        final body = SafeArea(child: child);
        return Scaffold(
          appBar: desktop
              ? null
              : AppBar(
                  titleSpacing: 20,
                  title: const _Brand(),
                  actions: [
                    if (profile != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Center(
                          child: Text(
                            profile.role.label,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ),
                      ),
                  ],
                ),
          body: desktop
              ? Row(
                  children: [
                    Container(
                      width: 236,
                      color: Colors.white,
                      child: SafeArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(22, 24, 22, 20),
                              child: _Brand(),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            Expanded(
                              child: NavigationRail(
                                extended: true,
                                backgroundColor: Colors.white,
                                selectedIndex: selectedIndex,
                                onDestinationSelected: (index) =>
                                    context.go(paths[index]),
                                labelType: NavigationRailLabelType.none,
                                groupAlignment: -1,
                                destinations: _railDestinations,
                              ),
                            ),
                            if (profile != null)
                              Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      child: Text(
                                        profile.displayName.characters.first
                                            .toUpperCase(),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.displayName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            profile.role.label,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: body),
                  ],
                )
              : body,
          bottomNavigationBar: desktop
              ? null
              : NavigationBar(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (index) => context.go(paths[index]),
                  destinations: _barDestinations,
                ),
        );
      },
    );
  }
}

const _barDestinations = [
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home),
    label: 'Home',
  ),
  NavigationDestination(
    icon: Icon(Icons.inventory_2_outlined),
    selectedIcon: Icon(Icons.inventory_2),
    label: 'Products',
  ),
  NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
  NavigationDestination(
    icon: Icon(Icons.build_outlined),
    selectedIcon: Icon(Icons.build),
    label: 'Repairs',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline),
    selectedIcon: Icon(Icons.person),
    label: 'Profile',
  ),
];

const _railDestinations = [
  NavigationRailDestination(icon: Icon(Icons.home_outlined), label: Text('Home')),
  NavigationRailDestination(
    icon: Icon(Icons.inventory_2_outlined),
    label: Text('Products'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.qr_code_scanner),
    label: Text('Scan passport'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.build_outlined),
    label: Text('Repair cases'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.person_outline),
    label: Text('Profile'),
  ),
];

class _Brand extends StatelessWidget {
  const _Brand();

  @override
  Widget build(BuildContext context) => const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.build_circle_outlined, color: Color(0xFF142B3A), size: 26),
          SizedBox(width: 9),
          Text('RepairLoop', style: TextStyle(fontWeight: FontWeight.w800)),
        ],
      );
}
