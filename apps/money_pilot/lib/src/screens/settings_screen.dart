import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/auth.dart';
import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/widgets/common.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appControllerProvider);
    final auth = ref.watch(authControllerProvider);
    final controller = ref.read(appControllerProvider.notifier);
    final l10n = context.l10n;
    return PageFrame(
      title: l10n.text('settingsTitle'),
      subtitle: l10n.text('settingsSubtitle'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final appearance = _AppearanceCard(
            settings: data.settings,
            onChanged: controller.updateSettings,
          );
          final privacy = _PrivacyCard(
            settings: data.settings,
            onChanged: controller.updateSettings,
          );
          final dataControls = _DataCard(data: data);
          final account = _AccountCard(user: auth.currentUser);
          final coach = _CoachPreferencesCard(
            settings: data.settings,
            onChanged: controller.updateSettings,
          );
          final shortcuts = const _ShortcutsCard();
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                account,
                const SizedBox(height: 18),
                appearance,
                const SizedBox(height: 18),
                privacy,
                const SizedBox(height: 18),
                coach,
                const SizedBox(height: 18),
                dataControls,
                const SizedBox(height: 18),
                shortcuts,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    account,
                    const SizedBox(height: 18),
                    appearance,
                    const SizedBox(height: 18),
                    dataControls,
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    coach,
                    const SizedBox(height: 18),
                    privacy,
                    const SizedBox(height: 18),
                    shortcuts,
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AppearanceCard extends StatelessWidget {
  const _AppearanceCard({required this.settings, required this.onChanged});

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.text('appearance'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(l10n.text('language')),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'en',
                  label: AppText(l10n.text('english')),
                ),
                ButtonSegment(value: 'fr', label: AppText(l10n.text('french'))),
                ButtonSegment(value: 'ar', label: AppText(l10n.text('arabic'))),
              ],
              selected: {settings.languageCode},
              onSelectionChanged: (values) =>
                  onChanged(settings.copyWith(languageCode: values.first)),
            ),
          ),
          const SizedBox(height: 8),
          AppText(
            l10n.text('languageHelp'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const Divider(height: 28),
          AppText(l10n.text('theme')),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'system',
                  label: AppText(l10n.text('system')),
                  icon: const Icon(Icons.brightness_auto_outlined),
                ),
                ButtonSegment(
                  value: 'light',
                  label: AppText(l10n.text('light')),
                  icon: const Icon(Icons.light_mode_outlined),
                ),
                ButtonSegment(
                  value: 'dark',
                  label: AppText(l10n.text('dark')),
                  icon: const Icon(Icons.dark_mode_outlined),
                ),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (values) =>
                  onChanged(settings.copyWith(themeMode: values.first)),
            ),
          ),
          const SizedBox(height: 18),
          const AppText('Color palette'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PaletteChoice(
                value: 'ocean',
                label: 'Ocean blue',
                color: const Color(0xFF4E7BEF),
                selected: settings.themePalette == 'ocean',
                onSelected: () =>
                    onChanged(settings.copyWith(themePalette: 'ocean')),
              ),
              _PaletteChoice(
                value: 'cyan',
                label: 'Electric cyan',
                color: const Color(0xFF00A9C7),
                selected: settings.themePalette == 'cyan',
                onSelected: () =>
                    onChanged(settings.copyWith(themePalette: 'cyan')),
              ),
              _PaletteChoice(
                value: 'forest',
                label: 'Deep forest',
                color: const Color(0xFF19704B),
                selected: settings.themePalette == 'forest',
                onSelected: () =>
                    onChanged(settings.copyWith(themePalette: 'forest')),
              ),
              _PaletteChoice(
                value: 'violet',
                label: 'Royal violet',
                color: const Color(0xFF7654D6),
                selected: settings.themePalette == 'violet',
                onSelected: () =>
                    onChanged(settings.copyWith(themePalette: 'violet')),
              ),
              _PaletteChoice(
                value: 'sunset',
                label: 'Warm sunset',
                color: const Color(0xFFE16647),
                selected: settings.themePalette == 'sunset',
                onSelected: () =>
                    onChanged(settings.copyWith(themePalette: 'sunset')),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.auto_awesome_outlined),
            title: const AppText('Glow effects'),
            subtitle: const AppText(
              'Adds a soft accent glow to cards and controls.',
            ),
            value: settings.glowEffects,
            onChanged: (value) =>
                onChanged(settings.copyWith(glowEffects: value)),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: AppText(l10n.text('highContrast')),
            subtitle: AppText(l10n.text('highContrastHelp')),
            value: settings.highContrast,
            onChanged: (value) =>
                onChanged(settings.copyWith(highContrast: value)),
          ),
          const Divider(height: 24),
          const Row(
            children: [
              Icon(Icons.accessibility_new_outlined, color: AppTheme.mint),
              SizedBox(width: 10),
              Expanded(
                child: AppText(
                  'Text scales up to 160%, controls expose semantic labels, and keyboard navigation is supported.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaletteChoice extends StatelessWidget {
  const _PaletteChoice({
    required this.value,
    required this.label,
    required this.color,
    required this.selected,
    required this.onSelected,
  });

  final String value;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      key: Key('palette-$value'),
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: CircleAvatar(backgroundColor: color, radius: 8),
      label: AppText(label),
    );
  }
}

class _AccountCard extends ConsumerWidget {
  const _AccountCard({required this.user});

  final LocalUser? user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      title: 'Account',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: AppText(
                  _initials(user?.displayName ?? 'MP'),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      user?.displayName ?? 'Local user',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    AppText(user?.email ?? ''),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                key: const Key('logout-button'),
                onPressed: () =>
                    ref.read(authControllerProvider.notifier).logout(),
                icon: const Icon(Icons.logout),
                label: const AppText('Sign out'),
              ),
              TextButton.icon(
                onPressed: () => _deleteAccount(context, ref),
                icon: const Icon(Icons.delete_forever_outlined),
                label: const AppText('Delete account'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final password = TextEditingController();
    String? error;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: const Icon(Icons.warning_amber_rounded),
          title: const AppText('Delete this local account?'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  'This permanently removes the profile and all of its local financial data. This cannot be undone.',
                ),
                const SizedBox(height: 14),
                TextField(
                  key: const Key('delete-account-password'),
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Confirm password'),
                    errorText: error == null
                        ? null
                        : context.l10n.translate(error!),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText('Cancel'),
            ),
            FilledButton(
              key: const Key('confirm-delete-account'),
              onPressed: () async {
                try {
                  await ref
                      .read(authControllerProvider.notifier)
                      .deleteCurrentAccount(password.text);
                  if (context.mounted) Navigator.pop(context, true);
                } on AuthException catch (exception) {
                  setState(() => error = exception.message);
                }
              },
              child: const AppText('Delete permanently'),
            ),
          ],
        ),
      ),
    );
    password.dispose();
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: AppText('Local account deleted.')),
      );
    }
  }
}

class _CoachPreferencesCard extends StatelessWidget {
  const _CoachPreferencesCard({
    required this.settings,
    required this.onChanged,
  });

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Coach & safety preferences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppText('Coaching style'),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'encouraging',
                  label: AppText('Supportive'),
                ),
                ButtonSegment(value: 'direct', label: AppText('Direct')),
                ButtonSegment(value: 'data', label: AppText('Data only')),
              ],
              selected: {settings.coachingStyle},
              onSelectionChanged: (values) =>
                  onChanged(settings.copyWith(coachingStyle: values.first)),
            ),
          ),
          const Divider(height: 28),
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: AppTheme.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppText(
                      'Personal safety buffer',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    AppText(MoneyFormatter.amount(settings.safetyBufferMinor)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => _editBuffer(context),
                child: const AppText('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AppText(
            'This amount stays protected in every safe spending calculation.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _editBuffer(BuildContext context) async {
    final input = TextEditingController(
      text: MoneyFormatter.input(settings.safetyBufferMinor),
    );
    String? error;
    final value = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const AppText('Personal safety buffer'),
          content: TextField(
            key: const Key('safety-buffer-field'),
            controller: input,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: context.l10n.translate('Amount to protect'),
              prefixText: r'$ ',
              errorText: error,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const AppText('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final parsed = MoneyFormatter.parseInputToMinor(
                  input.text,
                  allowZero: true,
                );
                if (parsed == null) {
                  setState(
                    () => error = context.l10n.translate(
                      'Enter zero or a positive amount',
                    ),
                  );
                  return;
                }
                Navigator.pop(context, parsed);
              },
              child: const AppText('Save'),
            ),
          ],
        ),
      ),
    );
    input.dispose();
    if (value != null) {
      onChanged(settings.copyWith(safetyBufferMinor: value));
    }
  }
}

class _PrivacyCard extends StatelessWidget {
  const _PrivacyCard({required this.settings, required this.onChanged});

  final AppSettings settings;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Privacy controls',
      child: Column(
        children: [
          _SettingSwitch(
            icon: Icons.analytics_outlined,
            title: 'Share anonymous diagnostics',
            subtitle: 'Off by default. Financial values are never included.',
            value: settings.analytics,
            onChanged: (value) =>
                onChanged(settings.copyWith(analytics: value)),
          ),
          _SettingSwitch(
            icon: Icons.fingerprint,
            title: 'Biometric lock preference',
            subtitle:
                'Preference saved. Biometric support depends on the device.',
            value: settings.biometricLock,
            onChanged: (value) =>
                onChanged(settings.copyWith(biometricLock: value)),
          ),
          _SettingSwitch(
            icon: Icons.cloud_outlined,
            title: 'API connection checks',
            subtitle:
                'When off, this profile stays on this device. Financial upload is not enabled.',
            value: settings.cloudSync,
            onChanged: (value) =>
                onChanged(settings.copyWith(cloudSync: value)),
          ),
          _SettingSwitch(
            icon: Icons.notifications_outlined,
            title: 'Bill reminders',
            subtitle: 'Controls reminder eligibility for recorded bills.',
            value: settings.notifications,
            onChanged: (value) =>
                onChanged(settings.copyWith(notifications: value)),
          ),
          const SizedBox(height: 6),
          const StatusPill(
            label: 'Private by default',
            icon: Icons.info_outline,
            color: AppTheme.mint,
          ),
        ],
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: AppText(title),
      subtitle: AppText(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _DataCard extends ConsumerWidget {
  const _DataCard({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(appControllerProvider.notifier);
    final itemCount =
        data.transactions.length +
        data.accounts.length +
        data.budgets.length +
        data.bills.length +
        data.goals.length;
    return SectionCard(
      title: 'Local data & sync',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storage_outlined, color: AppTheme.mint),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '$itemCount local records',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    AppText(data.syncStatus),
                  ],
                ),
              ),
            ],
          ),
          if (data.lastSyncAt != null) ...[
            const SizedBox(height: 8),
            AppText(
              'Last checked ${DateFormats.medium.format(data.lastSyncAt!)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: controller.syncNow,
                icon: const Icon(Icons.sync),
                label: const AppText('Check API'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showApiLogin(context, ref),
                icon: const Icon(Icons.cloud_done_outlined),
                label: const AppText('Connect API account'),
              ),
              OutlinedButton.icon(
                key: const Key('clear-financial-data-button'),
                onPressed: () => _confirmClear(context, ref),
                icon: const Icon(Icons.delete_sweep_outlined),
                label: const AppText('Clear financial data'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          AppText(
            'Financial records are encrypted and kept separate for each signed in local profile. API passwords and session tokens are never saved to disk.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Future<void> _showApiLogin(BuildContext context, WidgetRef ref) async {
    final endpoint = TextEditingController(text: data.settings.apiBaseUrl);
    final email = TextEditingController();
    final password = TextEditingController();
    try {
      final connect = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const AppText('Connect API account'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppText(
                  'Connect to a running MoneyPilot API. This verifies your account session; financial records stay local.',
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: endpoint,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('API address'),
                    prefixIcon: const Icon(Icons.link),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Email'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: password,
                  obscureText: true,
                  onSubmitted: (_) => Navigator.pop(context, true),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const AppText('Connect'),
            ),
          ],
        ),
      );
      if (connect != true || !context.mounted) return;
      final result = await ref
          .read(appControllerProvider.notifier)
          .connectApi(
            baseUrl: endpoint.text,
            email: email.text,
            password: password.text,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: AppText(result)));
      }
    } finally {
      endpoint.dispose();
      email.dispose();
      password.dispose();
    }
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    var confirmation = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          icon: Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.error,
          ),
          title: const AppText('Clear all financial data?'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  'Accounts, transactions, budgets, bills, goals, and coach history will be removed. Your login and categories remain.',
                ),
                const SizedBox(height: 8),
                const AppText(
                  'This cannot be undone.',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('wipe-confirmation-field'),
                  autofocus: true,
                  autocorrect: false,
                  onChanged: (value) => setState(() => confirmation = value),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Type WIPE to confirm'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const AppText('Cancel'),
            ),
            FilledButton.icon(
              key: const Key('confirm-wipe-button'),
              onPressed: confirmation.trim().toUpperCase() == 'WIPE'
                  ? () => Navigator.pop(context, true)
                  : null,
              icon: const Icon(Icons.delete_sweep_outlined),
              label: const AppText('Clear data'),
            ),
          ],
        ),
      ),
    );
    if (confirmed == true) {
      await ref.read(appControllerProvider.notifier).clearAllData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Financial data cleared.')),
        );
      }
    }
  }
}

class _ShortcutsCard extends StatelessWidget {
  const _ShortcutsCard();

  @override
  Widget build(BuildContext context) {
    return const SectionCard(
      title: 'Keyboard shortcuts',
      child: Column(
        children: [
          _ShortcutRow(keys: 'Ctrl + N', action: 'Add transaction'),
          SizedBox(height: 12),
          _ShortcutRow(keys: 'Ctrl + D', action: 'Open dashboard'),
          SizedBox(height: 12),
          _ShortcutRow(keys: 'Ctrl + K', action: 'Search transactions'),
        ],
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  const _ShortcutRow({required this.keys, required this.action});

  final String keys;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: AppText(
            keys,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: AppText(action)),
      ],
    );
  }
}
