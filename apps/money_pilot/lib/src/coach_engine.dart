import 'package:money_pilot/src/formatters.dart';
import 'package:money_pilot/src/models.dart';

class CoachReply {
  const CoachReply({required this.text, this.action});

  final String text;
  final CoachAction? action;
}

/// A private, offline conversational finance engine.
///
/// It never invents balances. It answers from the user's current snapshot,
/// asks for missing inputs, and only returns typed action drafts that still
/// require an explicit approval in the UI.
class LocalCoachEngine {
  const LocalCoachEngine();

  Future<CoachReply> reply({
    required String prompt,
    required AppData data,
    required int safeToSpendMinor,
    required int monthlyIncomeMinor,
    required int monthlyExpenseMinor,
    required int netWorthMinor,
    required int savingsRateBasisPoints,
    required String Function(String prefix) newId,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final clean = prompt.trim();
    final lower = clean.toLowerCase();
    final empty = data.accounts.isEmpty && data.transactions.isEmpty;
    final style = data.settings.coachingStyle;
    if (data.settings.languageCode == 'fr') {
      return _replyFrench(
        prompt: clean,
        data: data,
        safeToSpendMinor: safeToSpendMinor,
        monthlyIncomeMinor: monthlyIncomeMinor,
        monthlyExpenseMinor: monthlyExpenseMinor,
        netWorthMinor: netWorthMinor,
        newId: newId,
      );
    }
    if (data.settings.languageCode == 'ar') {
      return _replyArabic(
        prompt: clean,
        data: data,
        safeToSpendMinor: safeToSpendMinor,
        monthlyIncomeMinor: monthlyIncomeMinor,
        monthlyExpenseMinor: monthlyExpenseMinor,
        netWorthMinor: netWorthMinor,
        newId: newId,
      );
    }

    if (_hasAny(lower, [
          'hello',
          'hi ',
          'hey',
          'good morning',
          'good evening',
        ]) ||
        lower == 'hi' ||
        lower == 'hey') {
      return CoachReply(
        text: empty
            ? _styled(
                style,
                'Hi! Your workspace is empty, so I will not pretend to know your finances. Add an account first, then income or expenses. I can guide you through either one.',
              )
            : _styled(
                style,
                'Hi! I can use your local accounts, transactions, bills, budgets, and goals to answer questions. What decision are you working through?',
              ),
      );
    }

    if (_hasAny(lower, ['thank', 'thanks'])) {
      return CoachReply(
        text: _styled(
          style,
          'You are welcome. If you want, tell me the next money decision and the amount or deadline involved.',
        ),
      );
    }

    if (_hasAny(lower, ['what can you do', 'help me', 'how do you work'])) {
      return CoachReply(
        text:
            'I can explain safe-to-spend, total cash flow, category spending, upcoming bills, savings goals, and purchase affordability. I can also draft a category budget, but I cannot apply it without your approval. Your data stays on this device while the Local Coach is active.',
      );
    }

    if (_hasAny(lower, ['afford', 'buy', 'purchase', 'cost me'])) {
      final amount = _extractAmountMinor(clean);
      if (amount == null) {
        return CoachReply(
          text:
              'What price are you considering? Include the amount, for example: “Can I afford a laptop for 900?”',
        );
      }
      if (data.accounts.isEmpty) {
        return CoachReply(
          text:
              'I cannot assess ${MoneyFormatter.amount(amount)} yet because there is no account balance. Add the account that would pay for it, then ask me again.',
        );
      }
      final after = safeToSpendMinor - amount;
      if (amount <= safeToSpendMinor) {
        final share = safeToSpendMinor == 0
            ? 0
            : ((amount * 100) / safeToSpendMinor).round();
        return CoachReply(
          text: _styled(
            style,
            '${MoneyFormatter.amount(amount)} fits inside your current safe-to-spend estimate of ${MoneyFormatter.amount(safeToSpendMinor)}. It would use about $share% of that allowance and leave ${MoneyFormatter.amount(after)}. This is an estimate based only on the bills, balances, budgets, and reserves you entered.',
          ),
        );
      }
      return CoachReply(
        text: _styled(
          style,
          '${MoneyFormatter.amount(amount)} is ${MoneyFormatter.amount(amount - safeToSpendMinor)} above your current safe-to-spend estimate. Waiting, saving toward it, or reducing another flexible category would protect the commitments you entered.',
        ),
      );
    }

    if (_hasAny(lower, ['safe to spend', 'safe-to-spend', 'spend safely'])) {
      if (data.accounts.isEmpty) {
        return const CoachReply(
          text:
              'Safe-to-spend is unavailable until you add at least one cash, checking, or savings account. I will keep it at zero instead of inventing a balance.',
        );
      }
      final openBills = data.bills
          .where((bill) => !bill.isPaid)
          .fold<int>(0, (total, bill) => total + bill.amountMinor);
      return CoachReply(
        text:
            'Your current safe-to-spend estimate is ${MoneyFormatter.amount(safeToSpendMinor)}. I started with included non-credit balances, protected ${MoneyFormatter.amount(openBills)} in unpaid bills, card obligations, your ${MoneyFormatter.amount(data.settings.safetyBufferMinor)} personal buffer, and any tighter remaining budget cap. Estimates depend on the records you entered.',
      );
    }

    if (_hasAny(lower, ['income', 'cash flow', 'earned', 'salary'])) {
      if (data.transactions.isEmpty) {
        return const CoachReply(
          text:
              'There is no recorded income yet. Add an income transaction when money arrives; I will then calculate cash flow and savings rate without guessing your salary.',
        );
      }
      final net = monthlyIncomeMinor - monthlyExpenseMinor;
      return CoachReply(
        text:
            'This month you recorded ${MoneyFormatter.amount(monthlyIncomeMinor)} of income and ${MoneyFormatter.amount(monthlyExpenseMinor)} of expenses, for net cash flow of ${MoneyFormatter.amount(net)}.',
      );
    }

    if (_hasAny(lower, [
      'spent',
      'spend',
      'spending',
      'expense',
      'where did',
    ])) {
      if (data.transactions.isEmpty) {
        return const CoachReply(
          text:
              'No expenses have been recorded, so the honest total is zero. Add transactions and I can compare categories, merchants, and months.',
        );
      }
      final category = _mentionedCategory(lower, data.categories);
      if (category != null) {
        final now = DateTime.now();
        final spent = data.transactions
            .where(
              (item) =>
                  item.amountMinor < 0 &&
                  item.categoryId == category.id &&
                  item.date.year == now.year &&
                  item.date.month == now.month,
            )
            .fold<int>(0, (total, item) => total + item.amountMinor.abs());
        return CoachReply(
          text:
              'You spent ${MoneyFormatter.amount(spent)} on ${category.name} this month, based on the transactions currently recorded.',
        );
      }
      return CoachReply(
        text:
            'Your recorded expenses this month total ${MoneyFormatter.amount(monthlyExpenseMinor)}. Name a category—such as groceries, dining, or transport—and I can break it down.',
      );
    }

    if (_hasAny(lower, ['net worth', 'balance', 'how much money'])) {
      if (data.accounts.isEmpty) {
        return const CoachReply(
          text:
              'No accounts exist yet, so I do not have a balance to report. Add each account with its real opening balance and choose whether it belongs in safe-to-spend.',
        );
      }
      return CoachReply(
        text:
            'Your recorded net account balance is ${MoneyFormatter.amount(netWorthMinor)} across ${data.accounts.length} account${data.accounts.length == 1 ? '' : 's'}. Credit balances are included as liabilities.',
      );
    }

    if (_hasAny(lower, ['bill', 'due', 'upcoming'])) {
      final bills = data.bills.where((bill) => !bill.isPaid).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      if (bills.isEmpty) {
        return const CoachReply(
          text:
              'You have no unpaid bills recorded. Add recurring obligations so safe-to-spend can protect them before you make discretionary decisions.',
        );
      }
      final soon = bills
          .take(3)
          .map(
            (bill) =>
                '${bill.name} (${MoneyFormatter.amount(bill.amountMinor)})',
          );
      return CoachReply(
        text:
            'You have ${bills.length} unpaid bill${bills.length == 1 ? '' : 's'}. The next items are ${soon.join(', ')}. Open Bills for exact due dates.',
      );
    }

    if (_hasAny(lower, ['goal', 'saving', 'savings', 'emergency fund'])) {
      if (data.goals.isEmpty) {
        return const CoachReply(
          text:
              'You have no savings goals yet. A useful first goal is a small emergency buffer with a real target and date; the app will calculate progress from what you enter.',
        );
      }
      final goal = data.goals.first;
      final remaining = (goal.targetMinor - goal.savedMinor).clamp(0, 1 << 62);
      final rateText = monthlyIncomeMinor == 0
          ? 'A savings rate needs recorded income.'
          : 'Your current-month savings rate is ${MoneyFormatter.percent(savingsRateBasisPoints)}.';
      return CoachReply(
        text:
            '${goal.name} has ${MoneyFormatter.amount(goal.savedMinor)} saved and ${MoneyFormatter.amount(remaining)} remaining. $rateText',
      );
    }

    if (_hasAny(lower, ['budget', 'guardrail', 'limit'])) {
      final amount = _extractAmountMinor(clean);
      final category = _mentionedCategory(lower, data.categories);
      if (category == null) {
        return const CoachReply(
          text:
              'Which category should the budget cover? Include a category and amount, for example: “Set a 250 dining budget.”',
        );
      }
      if (amount == null) {
        return CoachReply(
          text:
              'What monthly limit should I draft for ${category.name}? I will show the proposal before changing anything.',
        );
      }
      final action = CoachAction(
        id: newId('action'),
        title:
            'Set ${category.name} budget to ${MoneyFormatter.amount(amount)}',
        description:
            'Creates or updates this month’s ${category.name} budget. No transaction or account balance will change.',
        kind: 'upsert_budget',
        payload: {'categoryId': category.id, 'plannedMinor': amount},
      );
      return CoachReply(
        text:
            'I prepared a ${MoneyFormatter.amount(amount)} monthly ${category.name} guardrail. Review it below—nothing changes unless you approve.',
        action: action,
      );
    }

    if (_hasAny(lower, ['yes', 'sure', 'okay', 'ok']) &&
        data.messages.length >= 2) {
      final previous = data.messages.reversed
          .where((message) => message.role == 'assistant')
          .firstOrNull;
      if (previous != null) {
        return CoachReply(
          text:
              'Great. Give me the missing amount, category, or deadline from the previous step and I will calculate it using your records.',
        );
      }
    }

    return CoachReply(
      text: empty
          ? 'I do not have enough personal data to answer that yet, and I will not invent any. Start by adding an account, then tell me the decision, amount, and deadline you are considering.'
          : 'I want to answer from your real numbers. Could you rephrase that as a question about a balance, expense category, budget, bill, savings goal, or purchase amount?',
    );
  }

  CoachReply _replyFrench({
    required String prompt,
    required AppData data,
    required int safeToSpendMinor,
    required int monthlyIncomeMinor,
    required int monthlyExpenseMinor,
    required int netWorthMinor,
    required String Function(String prefix) newId,
  }) {
    final lower = prompt.toLowerCase();
    final amount = _extractAmountMinor(prompt);
    if (_hasAny(lower, ['bonjour', 'salut', 'bonsoir', 'coucou'])) {
      return CoachReply(
        text: data.accounts.isEmpty
            ? 'Bonjour ! Votre espace est vide. Je ne vais inventer aucun chiffre. Ajoutez d’abord un compte, puis vos revenus ou dépenses, et je vous guiderai.'
            : 'Bonjour ! Je peux analyser vos comptes, transactions, factures, budgets et objectifs locaux. Quelle décision souhaitez-vous examiner ?',
      );
    }
    if (_hasAny(lower, ['merci'])) {
      return const CoachReply(
        text:
            'Avec plaisir. Dites-moi votre prochaine question financière, avec le montant ou la date si possible.',
      );
    }
    if (_hasAny(lower, ['que peux', 'quoi faire', 'aide-moi', 'aider'])) {
      return const CoachReply(
        text:
            'Je peux expliquer le montant disponible, la trésorerie, les dépenses par catégorie, les factures, les objectifs et la possibilité d’un achat. Je peux aussi préparer un budget, mais rien ne change sans votre approbation.',
      );
    }
    if (_hasAny(lower, ['acheter', 'achat', 'permettre', 'coûte', 'coute'])) {
      if (amount == null) {
        return const CoachReply(
          text:
              'Quel est le prix envisagé ? Par exemple : « Puis-je acheter un ordinateur à 900 ? »',
        );
      }
      if (data.accounts.isEmpty) {
        return CoachReply(
          text:
              'Je ne peux pas évaluer ${MoneyFormatter.amount(amount)} car aucun solde de compte n’est enregistré. Ajoutez le compte qui paierait cet achat puis redemandez-moi.',
        );
      }
      final after = safeToSpendMinor - amount;
      return CoachReply(
        text: amount <= safeToSpendMinor
            ? '${MoneyFormatter.amount(amount)} entre dans votre montant actuellement disponible de ${MoneyFormatter.amount(safeToSpendMinor)} et laisserait ${MoneyFormatter.amount(after)}. Cette estimation utilise uniquement les données que vous avez saisies.'
            : '${MoneyFormatter.amount(amount)} dépasse votre montant disponible de ${MoneyFormatter.amount(amount - safeToSpendMinor)}. Attendre ou épargner protégerait les engagements enregistrés.',
      );
    }
    if (_hasAny(lower, ['disponible', 'dépenser', 'depenser', 'sans risque'])) {
      return CoachReply(
        text: data.accounts.isEmpty
            ? 'Le montant disponible reste à zéro tant qu’aucun compte n’est ajouté. Je préfère signaler l’information manquante plutôt que d’inventer un solde.'
            : 'Votre estimation disponible est ${MoneyFormatter.amount(safeToSpendMinor)}. Elle protège les factures, obligations, budgets et votre marge de sécurité enregistrés.',
      );
    }
    if (_hasAny(lower, ['revenu', 'salaire', 'trésorerie', 'tresorerie'])) {
      return CoachReply(
        text: data.transactions.isEmpty
            ? 'Aucun revenu n’est enregistré. Ajoutez une transaction de revenu et je calculerai la trésorerie sans deviner votre salaire.'
            : 'Ce mois-ci, vous avez enregistré ${MoneyFormatter.amount(monthlyIncomeMinor)} de revenus et ${MoneyFormatter.amount(monthlyExpenseMinor)} de dépenses.',
      );
    }
    if (_hasAny(lower, [
      'dépense',
      'depense',
      'dépensé',
      'depensé',
      'dépens',
    ])) {
      final category = _localizedCategory(lower, data.categories, 'fr');
      if (data.transactions.isEmpty) {
        return const CoachReply(
          text:
              'Aucune dépense n’est enregistrée : le total réel est donc zéro. Ajoutez des transactions pour obtenir une analyse.',
        );
      }
      if (category != null) {
        final spent = _spentThisMonth(data, category.id);
        return CoachReply(
          text:
              'Vous avez dépensé ${MoneyFormatter.amount(spent)} dans la catégorie ${category.name} ce mois-ci.',
        );
      }
      return CoachReply(
        text:
            'Vos dépenses enregistrées ce mois-ci totalisent ${MoneyFormatter.amount(monthlyExpenseMinor)}. Indiquez une catégorie pour obtenir le détail.',
      );
    }
    if (_hasAny(lower, ['solde', 'valeur nette', 'combien'])) {
      return CoachReply(
        text: data.accounts.isEmpty
            ? 'Aucun compte n’est enregistré, donc aucun solde ne peut être calculé.'
            : 'Le solde net enregistré est ${MoneyFormatter.amount(netWorthMinor)} sur ${data.accounts.length} compte(s).',
      );
    }
    if (_hasAny(lower, ['facture', 'échéance', 'echeance'])) {
      final bills = data.bills.where((bill) => !bill.isPaid).toList();
      return CoachReply(
        text: bills.isEmpty
            ? 'Aucune facture impayée n’est enregistrée. Ajoutez vos obligations pour que le montant disponible les protège.'
            : 'Vous avez ${bills.length} facture(s) impayée(s), pour un total de ${MoneyFormatter.amount(bills.fold(0, (total, bill) => total + bill.amountMinor))}.',
      );
    }
    if (_hasAny(lower, ['objectif', 'épargne', 'epargne'])) {
      return CoachReply(
        text: data.goals.isEmpty
            ? 'Aucun objectif d’épargne n’est enregistré. Ajoutez un montant cible et une date pour suivre vos progrès.'
            : '${data.goals.first.name} contient ${MoneyFormatter.amount(data.goals.first.savedMinor)} sur un objectif de ${MoneyFormatter.amount(data.goals.first.targetMinor)}.',
      );
    }
    if (_hasAny(lower, ['budget', 'limite'])) {
      return _localizedBudgetReply(
        prompt: lower,
        amount: amount,
        data: data,
        language: 'fr',
        newId: newId,
      );
    }
    return CoachReply(
      text: data.accounts.isEmpty && data.transactions.isEmpty
          ? 'Je n’ai pas encore assez de données personnelles pour répondre précisément, et je n’en inventerai pas. Ajoutez un compte ou reformulez avec un montant.'
          : 'Je veux répondre avec vos vrais chiffres. Posez une question sur un solde, une dépense, un budget, une facture, un objectif ou un montant d’achat.',
    );
  }

  CoachReply _replyArabic({
    required String prompt,
    required AppData data,
    required int safeToSpendMinor,
    required int monthlyIncomeMinor,
    required int monthlyExpenseMinor,
    required int netWorthMinor,
    required String Function(String prefix) newId,
  }) {
    final lower = prompt.toLowerCase();
    final amount = _extractAmountMinor(prompt);
    if (_hasAny(lower, ['مرحبا', 'مرحباً', 'أهلا', 'اهلا', 'السلام'])) {
      return CoachReply(
        text: data.accounts.isEmpty
            ? 'مرحباً! مساحة العمل فارغة، لذلك لن أخترع أي أرقام. أضف حساباً أولاً ثم الدخل أو المصروفات وسأساعدك خطوة بخطوة.'
            : 'مرحباً! أستطيع تحليل حساباتك ومعاملاتك وفواتيرك وميزانياتك وأهدافك المحلية. ما القرار الذي تريد مناقشته؟',
      );
    }
    if (_hasAny(lower, ['شكرا', 'شكراً'])) {
      return const CoachReply(
        text:
            'على الرحب والسعة. اكتب سؤالك المالي التالي مع المبلغ أو الموعد إن أمكن.',
      );
    }
    if (_hasAny(lower, ['ماذا يمكنك', 'شو فيك', 'ساعدني', 'كيف تعمل'])) {
      return const CoachReply(
        text:
            'أستطيع شرح المبلغ الآمن للصرف والتدفق النقدي والمصروفات والفواتير والأهداف وإمكانية الشراء. ويمكنني اقتراح ميزانية، لكن لا يتغيّر شيء من دون موافقتك.',
      );
    }
    if (_hasAny(lower, ['شراء', 'أشتري', 'اشتري', 'أتحمل', 'اتحمل', 'سعر'])) {
      if (amount == null) {
        return const CoachReply(
          text:
              'ما سعر الشيء الذي تفكر في شرائه؟ مثال: «هل أستطيع شراء حاسوب بسعر 900؟»',
        );
      }
      if (data.accounts.isEmpty) {
        return CoachReply(
          text:
              'لا أستطيع تقييم ${MoneyFormatter.amount(amount)} لأنه لا يوجد رصيد حساب مسجّل. أضف الحساب الذي ستدفع منه ثم اسألني مجدداً.',
        );
      }
      final after = safeToSpendMinor - amount;
      return CoachReply(
        text: amount <= safeToSpendMinor
            ? '${MoneyFormatter.amount(amount)} ضمن المبلغ الآمن للصرف وهو ${MoneyFormatter.amount(safeToSpendMinor)}، وسيبقى ${MoneyFormatter.amount(after)}. يعتمد التقدير فقط على البيانات التي أدخلتها.'
            : 'السعر أعلى من المبلغ الآمن للصرف بمقدار ${MoneyFormatter.amount(amount - safeToSpendMinor)}. الانتظار أو الادخار يحمي الالتزامات المسجّلة.',
      );
    }
    if (_hasAny(lower, ['آمن', 'امن', 'الصرف', 'أصرف', 'اصرف'])) {
      return CoachReply(
        text: data.accounts.isEmpty
            ? 'يبقى المبلغ الآمن للصرف صفراً حتى تضيف حساباً. لن أخترع رصيداً غير موجود.'
            : 'المبلغ الآمن للصرف حالياً هو ${MoneyFormatter.amount(safeToSpendMinor)} بعد حماية الفواتير والالتزامات والميزانيات وهامش الأمان الذي أدخلته.',
      );
    }
    if (_hasAny(lower, ['دخل', 'راتب', 'تدفق نقدي'])) {
      return CoachReply(
        text: data.transactions.isEmpty
            ? 'لا يوجد دخل مسجّل بعد. أضف معاملة دخل وسأحسب التدفق النقدي من دون تخمين راتبك.'
            : 'سجّلت هذا الشهر دخلاً بقيمة ${MoneyFormatter.amount(monthlyIncomeMinor)} ومصروفات بقيمة ${MoneyFormatter.amount(monthlyExpenseMinor)}.',
      );
    }
    if (_hasAny(lower, ['صرف', 'مصروف', 'أنفقت', 'انفقت'])) {
      final category = _localizedCategory(lower, data.categories, 'ar');
      if (data.transactions.isEmpty) {
        return const CoachReply(
          text:
              'لا توجد مصروفات مسجّلة، لذلك المجموع الحقيقي هو صفر. أضف المعاملات لأحلّلها.',
        );
      }
      if (category != null) {
        return CoachReply(
          text:
              'أنفقت ${MoneyFormatter.amount(_spentThisMonth(data, category.id))} ضمن فئة ${category.name} هذا الشهر.',
        );
      }
      return CoachReply(
        text:
            'إجمالي المصروفات المسجّلة هذا الشهر هو ${MoneyFormatter.amount(monthlyExpenseMinor)}. اذكر فئة للحصول على التفاصيل.',
      );
    }
    if (_hasAny(lower, ['رصيد', 'صافي', 'كم معي'])) {
      return CoachReply(
        text: data.accounts.isEmpty
            ? 'لا توجد حسابات مسجّلة، لذلك لا يوجد رصيد يمكن عرضه.'
            : 'صافي رصيد الحسابات المسجّل هو ${MoneyFormatter.amount(netWorthMinor)} عبر ${data.accounts.length} حساب.',
      );
    }
    if (_hasAny(lower, ['فاتورة', 'فواتير', 'استحقاق'])) {
      final bills = data.bills.where((bill) => !bill.isPaid).toList();
      return CoachReply(
        text: bills.isEmpty
            ? 'لا توجد فواتير غير مدفوعة مسجّلة. أضف التزاماتك كي يحميها حساب المبلغ الآمن للصرف.'
            : 'لديك ${bills.length} فواتير غير مدفوعة بمجموع ${MoneyFormatter.amount(bills.fold(0, (total, bill) => total + bill.amountMinor))}.',
      );
    }
    if (_hasAny(lower, ['هدف', 'ادخار', 'توفير'])) {
      return CoachReply(
        text: data.goals.isEmpty
            ? 'لا توجد أهداف ادخار بعد. أضف مبلغاً مستهدفاً وتاريخاً لأحسب التقدّم.'
            : 'تم ادخار ${MoneyFormatter.amount(data.goals.first.savedMinor)} لهدف ${data.goals.first.name} من أصل ${MoneyFormatter.amount(data.goals.first.targetMinor)}.',
      );
    }
    if (_hasAny(lower, ['ميزانية', 'حد'])) {
      return _localizedBudgetReply(
        prompt: lower,
        amount: amount,
        data: data,
        language: 'ar',
        newId: newId,
      );
    }
    return CoachReply(
      text: data.accounts.isEmpty && data.transactions.isEmpty
          ? 'لا أملك بيانات شخصية كافية للإجابة الدقيقة ولن أخترعها. أضف حساباً أو اكتب السؤال مع المبلغ.'
          : 'أريد الإجابة من أرقامك الحقيقية. اسأل عن رصيد أو مصروف أو ميزانية أو فاتورة أو هدف أو مبلغ شراء.',
    );
  }

  CoachReply _localizedBudgetReply({
    required String prompt,
    required int? amount,
    required AppData data,
    required String language,
    required String Function(String prefix) newId,
  }) {
    final category = _localizedCategory(prompt, data.categories, language);
    if (category == null) {
      return CoachReply(
        text: language == 'ar'
            ? 'ما الفئة التي تريد ميزانية لها؟ اذكر الفئة والمبلغ، مثلاً: ميزانية مطاعم 250.'
            : 'Quelle catégorie doit couvrir le budget ? Indiquez la catégorie et le montant, par exemple : budget restaurants 250.',
      );
    }
    if (amount == null) {
      return CoachReply(
        text: language == 'ar'
            ? 'ما الحد الشهري المطلوب لفئة ${category.name}؟ سأعرض الاقتراح قبل تغيير أي شيء.'
            : 'Quelle limite mensuelle souhaitez-vous pour ${category.name} ? Je montrerai la proposition avant tout changement.',
      );
    }
    final action = CoachAction(
      id: newId('action'),
      title: language == 'ar'
          ? 'تحديد ميزانية ${category.name} بقيمة ${MoneyFormatter.amount(amount)}'
          : 'Fixer le budget ${category.name} à ${MoneyFormatter.amount(amount)}',
      description: language == 'ar'
          ? 'ينشئ أو يحدّث ميزانية هذا الشهر. لن يتغيّر أي رصيد أو معاملة.'
          : 'Crée ou met à jour le budget de ce mois. Aucun solde ni transaction ne sera modifié.',
      kind: 'upsert_budget',
      payload: {'categoryId': category.id, 'plannedMinor': amount},
    );
    return CoachReply(
      text: language == 'ar'
          ? 'حضّرت اقتراح ميزانية بقيمة ${MoneyFormatter.amount(amount)}. راجعه أدناه؛ لن يتغيّر شيء إلا بعد موافقتك.'
          : 'J’ai préparé une proposition de ${MoneyFormatter.amount(amount)}. Vérifiez-la ci-dessous : rien ne change sans votre approbation.',
      action: action,
    );
  }

  int _spentThisMonth(AppData data, String categoryId) {
    final now = DateTime.now();
    return data.transactions
        .where(
          (item) =>
              item.amountMinor < 0 &&
              item.categoryId == categoryId &&
              item.date.year == now.year &&
              item.date.month == now.month,
        )
        .fold(0, (total, item) => total + item.amountMinor.abs());
  }

  SpendingCategory? _localizedCategory(
    String prompt,
    List<SpendingCategory> categories,
    String language,
  ) {
    final aliases = language == 'ar'
        ? <String, List<String>>{
            'dining': ['مطاعم', 'طعام', 'أكل', 'اكل'],
            'groceries': ['بقالة', 'سوبرماركت', 'مواد غذائية'],
            'transport': ['نقل', 'مواصلات', 'بنزين'],
            'housing': ['سكن', 'إيجار', 'ايجار'],
            'shopping': ['تسوق', 'مشتريات'],
          }
        : <String, List<String>>{
            'dining': ['restaurant', 'repas'],
            'groceries': ['courses', 'épicerie', 'epicerie'],
            'transport': ['transport', 'essence'],
            'housing': ['logement', 'loyer'],
            'shopping': ['achats', 'shopping'],
          };
    for (final entry in aliases.entries) {
      if (entry.value.any(prompt.contains)) {
        return categories.where((item) => item.id == entry.key).firstOrNull;
      }
    }
    return _mentionedCategory(prompt, categories);
  }

  bool _hasAny(String value, List<String> terms) =>
      terms.any((term) => value.contains(term));

  int? _extractAmountMinor(String text) {
    final normalized = text
        .replaceAll('٠', '0')
        .replaceAll('١', '1')
        .replaceAll('٢', '2')
        .replaceAll('٣', '3')
        .replaceAll('٤', '4')
        .replaceAll('٥', '5')
        .replaceAll('٦', '6')
        .replaceAll('٧', '7')
        .replaceAll('٨', '8')
        .replaceAll('٩', '9');
    final matches = RegExp(
      r'(?:[$€£]\s*)?(\d[\d,]*(?:\.\d{1,2})?)',
    ).allMatches(normalized);
    for (final match in matches) {
      final parsed = MoneyFormatter.parseInputToMinor(match.group(1) ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  SpendingCategory? _mentionedCategory(
    String prompt,
    List<SpendingCategory> categories,
  ) {
    for (final category in categories) {
      if (prompt.contains(category.name.toLowerCase())) return category;
    }
    return null;
  }

  String _styled(String style, String text) {
    if (style == 'data') return text;
    if (style == 'direct') return 'Straight answer: $text';
    return text;
  }
}
