import 'package:flutter/material.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/theme.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 850;
            final intro = _Intro(
              onContinue: () =>
                  ref.read(appControllerProvider.notifier).completeOnboarding(),
            );
            final preview = const _PreviewPanel();
            return wide
                ? Row(
                    children: [
                      Expanded(child: intro),
                      Expanded(child: preview),
                    ],
                  )
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [intro, const SizedBox(height: 8), preview],
                  );
          },
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.sky, AppTheme.mint],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.auto_graph, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: AppText(
                      'MoneyPilot AI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 44),
              AppText(
                'Clarity for every\nmoney decision.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                ),
              ),
              const SizedBox(height: 20),
              AppText(
                'See what is safe to spend, keep plans on course, and ask a coach that explains before it acts.',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  height: 1.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              const _TrustLine(
                icon: Icons.lock_outline,
                title: 'Empty by design',
                detail:
                    'No sample balances, expenses, salary, bills, or goals are added for you.',
              ),
              const _TrustLine(
                icon: Icons.check_circle_outline,
                title: 'You approve every action',
                detail: 'AI suggestions never change a plan silently.',
              ),
              const _TrustLine(
                icon: Icons.offline_bolt_outlined,
                title: 'Works offline',
                detail:
                    'Core tracking, budgets, forecasts, and the Local Coach work without internet.',
              ),
              const SizedBox(height: 32),
              Semantics(
                button: true,
                label: 'Open my empty MoneyPilot workspace',
                child: FilledButton.icon(
                  key: const Key('open-empty-workspace-button'),
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const AppText('Open my empty workspace'),
                ),
              ),
              const SizedBox(height: 12),
              AppText(
                'Add only the financial records you choose',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustLine extends StatelessWidget {
  const _TrustLine({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                AppText(
                  detail,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  const _PreviewPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 520),
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A47), Color(0xFF1C4960)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppText(
                'SAFE TO SPEND',
                style: TextStyle(
                  color: Color(0xFF8FE4C4),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              const AppText(
                r'$0.00',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 46,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const AppText(
                'Your estimate remains zero until you add your own accounts and obligations.',
                style: TextStyle(color: Color(0xFFD0DEE7), height: 1.5),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Column(
                  children: [
                    _PreviewRow(label: 'Available cash', value: r'$0.00'),
                    _PreviewRow(
                      label: 'Protected commitments',
                      value: r'$0.00',
                    ),
                    Divider(color: Colors.white24, height: 26),
                    _PreviewRow(
                      label: 'Financial records',
                      value: 'Empty',
                      highlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Color(0xFF8FE4C4)),
                  SizedBox(width: 10),
                  Expanded(
                    child: AppText(
                      '“I will use your real numbers and tell you when information is missing.”',
                      style: TextStyle(
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              style: const TextStyle(color: Color(0xFFD0DEE7)),
            ),
          ),
          AppText(
            value,
            style: TextStyle(
              color: highlight ? const Color(0xFF8FE4C4) : Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
