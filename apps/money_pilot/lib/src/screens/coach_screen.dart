import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:money_pilot/src/app_controller.dart';
import 'package:money_pilot/src/localization.dart';
import 'package:money_pilot/src/models.dart';
import 'package:money_pilot/src/theme.dart';
import 'package:money_pilot/src/widgets/common.dart';

class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send([String? suggestion]) {
    final value = suggestion ?? _messageController.text;
    if (value.trim().isEmpty) return;
    final response = ref.read(appControllerProvider.notifier).askCoach(value);
    _messageController.clear();
    _scrollToEnd();
    unawaited(response.whenComplete(_scrollToEnd));
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appControllerProvider);
    final l10n = context.l10n;
    return PageFrame(
      title: l10n.text('coachTitle'),
      subtitle: l10n.text('coachSubtitle'),
      actions: [
        StatusPill(
          label: l10n.text('localAiReady'),
          icon: Icons.offline_bolt_outlined,
          color: AppTheme.mint,
        ),
        if (data.messages.isNotEmpty)
          IconButton(
            tooltip: l10n.text('clearConversation'),
            onPressed: () => ref
                .read(appControllerProvider.notifier)
                .clearCoachConversation(),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final conversation = _ConversationPanel(
            messages: data.messages,
            pendingAction: data.pendingCoachAction,
            thinking: data.coachThinking,
            messageController: _messageController,
            scrollController: _scrollController,
            onSend: _send,
          );
          final contextPanel = _CoachContextPanel(data: data);
          if (constraints.maxWidth < 900) {
            return Column(
              children: [
                SizedBox(height: 640, child: conversation),
                const SizedBox(height: 18),
                contextPanel,
              ],
            );
          }
          return SizedBox(
            height: 680,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: conversation),
                const SizedBox(width: 18),
                Expanded(flex: 2, child: contextPanel),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ConversationPanel extends ConsumerWidget {
  const _ConversationPanel({
    required this.messages,
    required this.pendingAction,
    required this.thinking,
    required this.messageController,
    required this.scrollController,
    required this.onSend,
  });

  final List<CoachMessage> messages;
  final CoachAction? pendingAction;
  final bool thinking;
  final TextEditingController messageController;
  final ScrollController scrollController;
  final void Function([String? suggestion]) onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return SectionCard(
      padding: EdgeInsets.zero,
      fillHeight: true,
      child: Column(
        children: [
          Expanded(
            child: messages.isEmpty && pendingAction == null && !thinking
                ? _CoachWelcome(onSend: onSend)
                : ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount:
                        messages.length +
                        (pendingAction == null ? 0 : 1) +
                        (thinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < messages.length) {
                        return _MessageBubble(message: messages[index]);
                      }
                      final actionIndex = messages.length;
                      if (pendingAction != null && index == actionIndex) {
                        return _ApprovalCard(action: pendingAction!);
                      }
                      return const _ThinkingBubble();
                    },
                  ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _PromptChip(
                        label: l10n.text('explainSafe'),
                        onTap: () => onSend('Explain my safe to spend'),
                      ),
                      _PromptChip(
                        label: l10n.text('reviewDining'),
                        onTap: () => onSend('How much did I spend on dining?'),
                      ),
                      _PromptChip(
                        label: l10n.text('upcomingBills'),
                        onTap: () => onSend('What bills are coming up?'),
                      ),
                      _PromptChip(
                        label: l10n.text('canIAfford'),
                        onTap: () => onSend('Can I afford a purchase for 100?'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('coach-message-field'),
                        controller: messageController,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => onSend(),
                        decoration: InputDecoration(
                          hintText: l10n.text('askHint'),
                          prefixIcon: const Icon(Icons.auto_awesome_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      key: const Key('coach-send-button'),
                      tooltip: l10n.text('sendMessage'),
                      onPressed: onSend,
                      icon: const Icon(Icons.arrow_upward_rounded),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final CoachMessage message;

  @override
  Widget build(BuildContext context) {
    final user = message.role == 'user';
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: user
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: Semantics(
        label: user
            ? 'You said: ${message.text}'
            : 'Coach said: ${message.text}',
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          decoration: BoxDecoration(
            color: user ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(user ? 18 : 4),
              bottomRight: Radius.circular(user ? 4 : 18),
            ),
          ),
          child: AppText(
            message.text,
            style: TextStyle(color: user ? scheme.onPrimary : scheme.onSurface),
          ),
        ),
      ),
    );
  }
}

class _CoachWelcome extends StatelessWidget {
  const _CoachWelcome({required this.onSend});

  final void Function([String? suggestion]) onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 34),
              ),
              const SizedBox(height: 18),
              AppText(
                l10n.text('coachWelcomeTitle'),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              AppText(
                l10n.text('coachWelcomeBody'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 22),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 10,
                children: [
                  ActionChip(
                    label: AppText(l10n.text('whatCanYouDo')),
                    onPressed: () => onSend('What can you help me with?'),
                  ),
                  ActionChip(
                    label: AppText(l10n.text('explainSafe')),
                    onPressed: () => onSend('Explain my safe to spend'),
                  ),
                  ActionChip(
                    label: AppText(l10n.text('reviewCashFlow')),
                    onPressed: () => onSend('Review my income and cash flow'),
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

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox.square(
            dimension: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          AppText(context.l10n.text('checkingNumbers')),
        ],
      ),
    ),
  );
}

class _ApprovalCard extends ConsumerWidget {
  const _ApprovalCard({required this.action});

  final CoachAction action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Semantics(
      container: true,
      label: 'Approval required: ${action.title}',
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiaryContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.tertiary.withValues(alpha: 0.45),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatusPill(
              label: 'Approval required',
              icon: Icons.gpp_maybe_outlined,
              color: Color(0xFFD17C13),
            ),
            const SizedBox(height: 12),
            AppText(
              action.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            AppText(action.description),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.icon(
                  key: const Key('approve-coach-action'),
                  onPressed: () => _confirmApproval(context, ref),
                  icon: const Icon(Icons.check),
                  label: const AppText('Review & approve'),
                ),
                TextButton(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .rejectCoachAction(action.id),
                  child: const AppText('Not now'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmApproval(BuildContext context, WidgetRef ref) async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.shield_outlined),
        title: const AppText('Approve this plan change?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(
              action.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            AppText(action.description),
            const SizedBox(height: 12),
            const AppText(
              'No money will move and no transaction will be created.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const AppText('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-coach-action'),
            onPressed: () => Navigator.pop(context, true),
            child: const AppText('Approve change'),
          ),
        ],
      ),
    );
    if (approved == true) {
      ref.read(appControllerProvider.notifier).approveCoachAction(action.id);
    }
  }
}

class _PromptChip extends StatelessWidget {
  const _PromptChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: const Icon(Icons.auto_awesome, size: 16),
        label: AppText(label),
        onPressed: onTap,
      ),
    );
  }
}

class _CoachContextPanel extends StatelessWidget {
  const _CoachContextPanel({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final upcoming = data.bills.where((bill) => !bill.isPaid).length;
    final l10n = context.l10n;
    return SectionCard(
      title: l10n.text('coachContext'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(l10n.text('coachContextBody')),
          const SizedBox(height: 18),
          _ContextRow(
            icon: Icons.account_balance_wallet_outlined,
            label: l10n.navLabel('/accounts'),
            value: '${data.accounts.length}',
          ),
          _ContextRow(
            icon: Icons.donut_large_outlined,
            label: l10n.navLabel('/budgets'),
            value: '${data.budgets.length}',
          ),
          _ContextRow(
            icon: Icons.receipt_long_outlined,
            label: l10n.text('openBills'),
            value: '$upcoming',
          ),
          _ContextRow(
            icon: Icons.flag_outlined,
            label: l10n.navLabel('/goals'),
            value: '${data.goals.length}',
          ),
          const Divider(height: 28),
          AppText(
            l10n.text('safetyContract'),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          _SafetyLine(text: l10n.text('explainsBasis')),
          _SafetyLine(text: l10n.text('followUps')),
          _SafetyLine(text: l10n.text('oneAction')),
          _SafetyLine(text: l10n.text('confirmation')),
          _SafetyLine(text: l10n.text('neverMovesMoney')),
          const SizedBox(height: 24),
          AppText(
            l10n.text('educational'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ContextRow extends StatelessWidget {
  const _ContextRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: AppText(label)),
          AppText(value, style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _SafetyLine extends StatelessWidget {
  const _SafetyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: AppTheme.mint, size: 19),
          const SizedBox(width: 9),
          Expanded(child: AppText(text)),
        ],
      ),
    );
  }
}
