import 'package:flutter/material.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = constraints.maxWidth >= 900 ? 36.0 : 20.0;
        final displayTitle = switch (title) {
          'Accounts' => context.l10n.navLabel('/accounts'),
          'Transactions' => context.l10n.navLabel('/transactions'),
          'Budgets' => context.l10n.navLabel('/budgets'),
          'Bills' => context.l10n.navLabel('/bills'),
          'Goals' => context.l10n.navLabel('/goals'),
          'Reports & forecast' => context.l10n.navLabel('/reports'),
          'Smart purchase check' => context.l10n.navLabel('/purchase-check'),
          _ => title,
        };
        return Semantics(
          container: true,
          label: '$displayTitle page',
          child: ListView(
            key: PageStorageKey<String>(displayTitle),
            padding: EdgeInsets.fromLTRB(horizontal, 28, horizontal, 40),
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                runSpacing: 16,
                spacing: 16,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 650),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          displayTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        AppText(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (actions.isNotEmpty)
                    Wrap(spacing: 10, runSpacing: 10, children: actions),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        );
      },
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    required this.child,
    this.title,
    this.trailing,
    this.padding = const EdgeInsets.all(20),
    this.fillHeight = false,
    super.key,
  });

  final String? title;
  final Widget? trailing;
  final EdgeInsets padding;
  final Widget child;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      title!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (fillHeight) Expanded(child: child) else child,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.accent,
    super.key,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: '$label, $value${detail == null ? '' : ', $detail'}',
      child: SectionCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 3),
                    AppText(
                      detail!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({required this.category, this.size = 42, super.key});

  final SpendingCategory category;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(
        _categoryIcon(category.iconCode),
        color: color,
        size: size * 0.5,
      ),
    );
  }

  IconData _categoryIcon(int codePoint) => switch (codePoint) {
    0xe227 => Icons.payments_outlined,
    0xe318 => Icons.home_outlined,
    0xe547 => Icons.local_grocery_store_outlined,
    0xe56c => Icons.restaurant_outlined,
    0xe1d7 => Icons.directions_car_outlined,
    0xe63c => Icons.bolt_outlined,
    0xe3f3 => Icons.favorite_outline,
    0xe59c => Icons.shopping_bag_outlined,
    0xe539 => Icons.flight_outlined,
    _ => Icons.category_outlined,
  };
}

class AmountText extends StatelessWidget {
  const AmountText({required this.minor, this.emphasized = false, super.key});

  final int minor;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final income = minor >= 0;
    return AppText(
      MoneyFormatter.amount(minor),
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
        color: income
            ? const Color(0xFF18875C)
            : Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            AppText(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            AppText(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.icon,
    this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? Theme.of(context).colorScheme.primary;
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: resolved.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: resolved),
            const SizedBox(width: 6),
            AppText(
              label,
              style: TextStyle(
                color: resolved,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    required this.children,
    this.minItemWidth = 250,
    this.spacing = 16,
    super.key,
  });

  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final count = (constraints.maxWidth / minItemWidth).floor().clamp(
          1,
          children.length,
        );
        final width = (constraints.maxWidth - spacing * (count - 1)) / count;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(),
        );
      },
    );
  }
}
