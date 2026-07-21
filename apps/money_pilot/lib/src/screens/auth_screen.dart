import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/auth.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/theme.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _create = false;
  bool _obscure = true;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final form = _AuthForm(
              formKey: _formKey,
              create: _create,
              busy: auth.busy,
              error: auth.error,
              name: _name,
              email: _email,
              password: _password,
              obscure: _obscure,
              onToggleMode: () => setState(() {
                _create = !_create;
                _password.clear();
              }),
              onToggleObscure: () => setState(() => _obscure = !_obscure),
              onSubmit: _submit,
              onReset: _showReset,
            );
            if (constraints.maxWidth >= 900) {
              return Row(
                children: [
                  const Expanded(flex: 11, child: _AuthStoryPanel()),
                  Expanded(flex: 9, child: form),
                ],
              );
            }
            return ListView(
              children: [
                const SizedBox(
                  height: 300,
                  child: _AuthStoryPanel(compact: true),
                ),
                form,
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final preferredLanguage = ref
        .read(appControllerProvider)
        .settings
        .languageCode;
    try {
      if (_create) {
        final result = await controller.register(
          displayName: _name.text,
          email: _email.text,
          password: _password.text,
        );
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.key_outlined),
            title: const AppText('Save your recovery code'),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppText(
                    'This is the only way to reset a local password. Store it somewhere private; MoneyPilot cannot reveal it again.',
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: SelectableText(
                      result.recoveryCode,
                      key: const Key('recovery-code'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              FilledButton(
                key: const Key('saved-recovery-code'),
                onPressed: () => Navigator.pop(context),
                child: const AppText('I saved it'),
              ),
            ],
          ),
        );
        await controller.completeRegistration(result.user);
        ref
            .read(appControllerProvider.notifier)
            .updateSettings(
              ref
                  .read(appControllerProvider)
                  .settings
                  .copyWith(languageCode: preferredLanguage),
            );
      } else {
        await controller.login(email: _email.text, password: _password.text);
      }
    } on AuthException {
      // The provider exposes a single accessible error message in the form.
    }
  }

  Future<void> _showReset() async {
    await showDialog<void>(
      context: context,
      builder: (context) => _ResetPasswordDialog(initialEmail: _email.text),
    );
  }
}

class _AuthForm extends ConsumerWidget {
  const _AuthForm({
    required this.formKey,
    required this.create,
    required this.busy,
    required this.error,
    required this.name,
    required this.email,
    required this.password,
    required this.obscure,
    required this.onToggleMode,
    required this.onToggleObscure,
    required this.onSubmit,
    required this.onReset,
  });

  final GlobalKey<FormState> formKey;
  final bool create;
  final bool busy;
  final String? error;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController password;
  final bool obscure;
  final VoidCallback onToggleMode;
  final VoidCallback onToggleObscure;
  final VoidCallback onSubmit;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      appControllerProvider.select((data) => data.settings),
    );
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  create ? 'Create your account' : 'Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                AppText(
                  create
                      ? 'Your new profile starts completely empty.'
                      : 'Sign in to your private local workspace.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                if (error != null) ...[
                  Semantics(
                    liveRegion: true,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: AppText(error!)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (create) ...[
                  TextFormField(
                    key: const Key('auth-name-field'),
                    controller: name,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    decoration: InputDecoration(
                      labelText: context.l10n.translate('Name'),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => (value ?? '').trim().length < 2
                        ? context.l10n.translate('Enter at least 2 characters')
                        : null,
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  key: const Key('auth-email-field'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Email'),
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                  validator: (value) =>
                      RegExp(
                        r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                      ).hasMatch((value ?? '').trim())
                      ? null
                      : context.l10n.translate('Enter a valid email'),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('auth-password-field'),
                  controller: password,
                  obscureText: obscure,
                  textInputAction: TextInputAction.done,
                  autofillHints: [
                    create ? AutofillHints.newPassword : AutofillHints.password,
                  ],
                  onFieldSubmitted: (_) => busy ? null : onSubmit(),
                  decoration: InputDecoration(
                    labelText: context.l10n.translate('Password'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: context.l10n.translate(
                        obscure ? 'Show password' : 'Hide password',
                      ),
                      onPressed: onToggleObscure,
                      icon: Icon(
                        obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (!create) {
                      return (value ?? '').isEmpty
                          ? context.l10n.translate('Enter your password')
                          : null;
                    }
                    final result = LocalAuthRepository.validatePassword(
                      value ?? '',
                    );
                    return result == null
                        ? null
                        : context.l10n.translate(result);
                  },
                ),
                if (create) ...[
                  const SizedBox(height: 10),
                  AppText(
                    'Use 10+ characters with uppercase, lowercase, and a number.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton.icon(
                  key: Key(create ? 'create-account-button' : 'login-button'),
                  onPressed: busy ? null : onSubmit,
                  icon: busy
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(create ? Icons.person_add_alt_1 : Icons.login),
                  label: AppText(create ? 'Create empty workspace' : 'Sign in'),
                ),
                if (!create)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: busy ? null : onReset,
                      child: const AppText('Forgot password?'),
                    ),
                  ),
                const Divider(height: 30),
                TextButton(
                  onPressed: busy ? null : onToggleMode,
                  child: AppText(
                    create
                        ? 'Already have an account? Sign in'
                        : 'New to MoneyPilot? Create an account',
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 24),
                AppText(
                  context.l10n.text('language'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'en',
                      label: AppText(context.l10n.text('english')),
                    ),
                    ButtonSegment(
                      value: 'fr',
                      label: AppText(context.l10n.text('french')),
                    ),
                    ButtonSegment(
                      value: 'ar',
                      label: AppText(context.l10n.text('arabic')),
                    ),
                  ],
                  selected: {settings.languageCode},
                  onSelectionChanged: (values) => ref
                      .read(appControllerProvider.notifier)
                      .updateSettings(
                        settings.copyWith(languageCode: values.first),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthStoryPanel extends StatelessWidget {
  const _AuthStoryPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(compact ? 12 : 24),
      padding: EdgeInsets.all(compact ? 24 : 42),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102A47), Color(0xFF1B5360)],
        ),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              const Expanded(
                child: AppText(
                  'MoneyPilot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 22 : 52),
          AppText(
            compact
                ? 'Your money.\nNo invented numbers.'
                : 'Your money.\nNo invented numbers.\nNo financial shaming.',
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 28 : 42,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 24),
            const _StoryLine(
              icon: Icons.person_outline,
              text: 'Separate profiles with isolated local data',
            ),
            const _StoryLine(
              icon: Icons.enhanced_encryption_outlined,
              text: 'Argon2id password hashing and recovery codes',
            ),
            const _StoryLine(
              icon: Icons.auto_awesome_outlined,
              text: 'A coach that answers from your actual records',
            ),
            const _StoryLine(
              icon: Icons.offline_bolt_outlined,
              text: 'Core account and finance tools work offline',
            ),
          ],
        ],
      ),
    );
  }
}

class _StoryLine extends StatelessWidget {
  const _StoryLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Row(
      children: [
        Icon(icon, color: const Color(0xFF8FE4C4)),
        const SizedBox(width: 13),
        Expanded(
          child: AppText(
            text,
            style: const TextStyle(color: Color(0xFFE2EEF3)),
          ),
        ),
      ],
    ),
  );
}

class _ResetPasswordDialog extends ConsumerStatefulWidget {
  const _ResetPasswordDialog({required this.initialEmail});

  final String initialEmail;

  @override
  ConsumerState<_ResetPasswordDialog> createState() =>
      _ResetPasswordDialogState();
}

class _ResetPasswordDialogState extends ConsumerState<_ResetPasswordDialog> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _code = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    icon: const Icon(Icons.password_outlined),
    title: const AppText('Reset local password'),
    content: SizedBox(
      width: 440,
      child: Form(
        key: _key,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error != null) ...[
              AppText(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _email,
              decoration: InputDecoration(
                labelText: context.l10n.translate('Email'),
              ),
              validator: (value) =>
                  (value ?? '').contains('@') ? null : 'Enter your email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('recovery-code-field'),
              controller: _code,
              decoration: InputDecoration(
                labelText: context.l10n.translate('Recovery code'),
              ),
              validator: (value) =>
                  (value ?? '').replaceAll('-', '').length == 16
                  ? null
                  : 'Enter the 16-character recovery code',
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: true,
              decoration: InputDecoration(
                labelText: context.l10n.translate('New password'),
              ),
              validator: (value) =>
                  LocalAuthRepository.validatePassword(value ?? ''),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: _busy ? null : () => Navigator.pop(context),
        child: const AppText('Cancel'),
      ),
      FilledButton(
        key: const Key('reset-password-button'),
        onPressed: _busy ? null : _reset,
        child: AppText(_busy ? 'Resetting…' : 'Reset password'),
      ),
    ],
  );

  Future<void> _reset() async {
    if (!_key.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(
            email: _email.text,
            recoveryCode: _code.text,
            newPassword: _password.text,
          );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Password reset. You can sign in now.'),
        ),
      );
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
