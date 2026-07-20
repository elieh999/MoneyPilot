import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/screens/transactions_screen.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/widgets/common.dart';

class AppDestination {
  const AppDestination(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

const appDestinations = [
  AppDestination(
    '/dashboard',
    'Overview',
    Icons.grid_view_outlined,
    Icons.grid_view_rounded,
  ),
  AppDestination(
    '/transactions',
    'Transactions',
    Icons.swap_horiz_outlined,
    Icons.swap_horiz_rounded,
  ),
  AppDestination(
    '/calendar',
    'Calendar',
    Icons.calendar_month_outlined,
    Icons.calendar_month_rounded,
  ),
  AppDestination(
    '/accounts',
    'Accounts',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
  ),
  AppDestination(
    '/budgets',
    'Budgets',
    Icons.donut_large_outlined,
    Icons.donut_large_rounded,
  ),
  AppDestination(
    '/bills',
    'Bills',
    Icons.receipt_long_outlined,
    Icons.receipt_long_rounded,
  ),
  AppDestination('/goals', 'Goals', Icons.flag_outlined, Icons.flag_rounded),
  AppDestination(
    '/reports',
    'Reports',
    Icons.query_stats_outlined,
    Icons.query_stats_rounded,
  ),
  AppDestination(
    '/coach',
    'AI Coach',
    Icons.auto_awesome_outlined,
    Icons.auto_awesome_rounded,
  ),
  AppDestination(
    '/purchase-check',
    'Purchase Check',
    Icons.balance_outlined,
    Icons.balance_rounded,
  ),
  AppDestination(
    '/settings',
    'Settings',
    Icons.settings_outlined,
    Icons.settings_rounded,
  ),
];

class AppShell extends ConsumerWidget {
  const AppShell({required this.location, required this.child, super.key});

  final String location;
  final Widget child;

  int get _selectedIndex {
    final index = appDestinations.indexWhere(
      (destination) => location.startsWith(destination.path),
    );
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.sizeOf(context).width;
    final body = CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
            showTransactionEditor(context),
        const SingleActivator(LogicalKeyboardKey.keyD, control: true): () =>
            context.go('/dashboard'),
        const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
            context.go('/transactions'),
      },
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: child,
      ),
    );
    if (width >= 1100) return _desktop(context, ref, body, extended: true);
    if (width >= 720) return _desktop(context, ref, body, extended: false);
    return _mobile(context, ref, body);
  }

  Widget _desktop(
    BuildContext context,
    WidgetRef ref,
    Widget body, {
    required bool extended,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Container(
              width: extended ? 248 : 82,
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                border: Border(right: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: extended ? 20 : 14,
                      vertical: 22,
                    ),
                    child: Row(
                      mainAxisAlignment: extended
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        const _LogoMark(),
                        if (extended) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppText(
                              'MoneyPilot',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      itemCount: appDestinations.length,
                      itemBuilder: (context, index) {
                        final destination = appDestinations[index];
                        final selected = index == _selectedIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Tooltip(
                            message: extended
                                ? ''
                                : l10n.navLabel(destination.path),
                            child: Material(
                              color: selected
                                  ? scheme.primaryContainer
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => context.go(destination.path),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: extended ? 14 : 0,
                                    vertical: 13,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: extended
                                        ? MainAxisAlignment.start
                                        : MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        selected
                                            ? destination.selectedIcon
                                            : destination.icon,
                                        color: selected
                                            ? scheme.onPrimaryContainer
                                            : scheme.onSurfaceVariant,
                                      ),
                                      if (extended) ...[
                                        const SizedBox(width: 13),
                                        Expanded(
                                          child: AppText(
                                            l10n.navLabel(destination.path),
                                            style: TextStyle(
                                              fontWeight: selected
                                                  ? FontWeight.w800
                                                  : FontWeight.w600,
                                              color: selected
                                                  ? scheme.onPrimaryContainer
                                                  : scheme.onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: extended
                        ? StatusPill(
                            label: l10n.text('offlineReady'),
                            icon: Icons.cloud_done_outlined,
                            color: AppTheme.mint,
                          )
                        : Tooltip(
                            message: l10n.text('savedLocally'),
                            child: const Icon(
                              Icons.cloud_done_outlined,
                              color: AppTheme.mint,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  _DesktopTopBar(location: location),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobile(BuildContext context, WidgetRef ref, Widget body) {
    final l10n = context.l10n;
    const mobilePaths = ['/dashboard', '/transactions', '/budgets', '/coach'];
    final mobileIndex = mobilePaths.indexWhere(location.startsWith);
    final selected = mobileIndex < 0 ? 4 : mobileIndex;
    final current = appDestinations[_selectedIndex];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const _LogoMark(size: 34),
            const SizedBox(width: 10),
            AppText(l10n.navLabel(current.path)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: '${l10n.text('addTransaction')} (Ctrl+N)',
            onPressed: () => showTransactionEditor(context),
            icon: const Icon(Icons.add_circle_outline),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(top: false, child: body),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (index) {
          if (index < mobilePaths.length) {
            context.go(mobilePaths[index]);
          } else {
            _showMore(context);
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: l10n.navLabel('/dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.swap_horiz_outlined),
            selectedIcon: const Icon(Icons.swap_horiz_rounded),
            label: l10n.text('activity'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.donut_large_outlined),
            selectedIcon: const Icon(Icons.donut_large_rounded),
            label: l10n.text('plan'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.auto_awesome_outlined),
            selectedIcon: const Icon(Icons.auto_awesome_rounded),
            label: l10n.text('coach'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.text('more'),
          ),
        ],
      ),
    );
  }

  Future<void> _showMore(BuildContext context) async {
    final l10n = context.l10n;
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: AppText(
                l10n.text('tools'),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            for (final destination in appDestinations)
              ListTile(
                leading: Icon(destination.icon),
                title: AppText(l10n.navLabel(destination.path)),
                selected: location.startsWith(destination.path),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onTap: () => Navigator.of(context).pop(destination.path),
              ),
          ],
        ),
      ),
    );
    if (selected != null && context.mounted) context.go(selected);
  }
}

class _DesktopTopBar extends ConsumerWidget {
  const _DesktopTopBar({required this.location});

  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final l10n = context.l10n;
    final syncStatus = data.syncStatus == 'Local changes saved'
        ? l10n.text('localChangesSaved')
        : data.syncStatus;
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              syncStatus,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Tooltip(
            message: '${l10n.text('addTransaction')} • Ctrl+N',
            child: FilledButton.icon(
              onPressed: () => showTransactionEditor(context),
              icon: const Icon(Icons.add, size: 19),
              label: AppText(l10n.text('addTransaction')),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            child: AppText(
              'MP',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MoneyPilot AI',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.sky, AppTheme.mint]),
          borderRadius: BorderRadius.circular(size * 0.32),
          boxShadow: [
            BoxShadow(
              color: AppTheme.sky.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
          Icons.auto_graph_rounded,
          color: Colors.white,
          size: size * 0.6,
        ),
      ),
    );
  }
}
