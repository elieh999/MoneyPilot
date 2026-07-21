import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:money_pilot/src/ui_translations.dart';
import 'package:money_pilot/src/ui_translations_extra.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('fr'), Locale('ar')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  String text(String key) {
    final language = _translations[locale.languageCode] ?? _translations['en']!;
    return language[key] ?? _translations['en']![key] ?? key;
  }

  String navLabel(String path) => text('nav:$path');

  String translate(String source) {
    if (locale.languageCode == 'en' || source.trim().isEmpty) return source;
    final phrases = locale.languageCode == 'ar'
        ? arabicUiPhrases
        : frenchUiPhrases;
    final extras = locale.languageCode == 'ar'
        ? arabicUiPhrasesExtra
        : frenchUiPhrasesExtra;
    final exact = phrases[source] ?? extras[source];
    if (exact != null) return exact;
    return _translateDynamic(source, phrases);
  }

  bool hasPhrase(String source) {
    if (locale.languageCode == 'en') return true;
    final phrases = locale.languageCode == 'ar'
        ? arabicUiPhrases
        : frenchUiPhrases;
    final extras = locale.languageCode == 'ar'
        ? arabicUiPhrasesExtra
        : frenchUiPhrasesExtra;
    return phrases.containsKey(source) || extras.containsKey(source);
  }

  String _translateDynamic(String source, Map<String, String> phrases) {
    final language = locale.languageCode;
    final patterns = <(RegExp, String Function(RegExpMatch))>[
      (
        RegExp(r'^(\d+) local records$'),
        (match) => language == 'ar'
            ? '${match[1]} سجلاً محلياً'
            : '${match[1]} enregistrements locaux',
      ),
      (
        RegExp(r'^Across (\d+) active goals$'),
        (match) => language == 'ar'
            ? 'عبر ${match[1]} أهداف نشطة'
            : 'Sur ${match[1]} objectifs actifs',
      ),
      (
        RegExp(r'^Due (.+)$'),
        (match) =>
            language == 'ar' ? 'الاستحقاق ${match[1]}' : 'Échéance ${match[1]}',
      ),
      (
        RegExp(r'^Target (.+)$'),
        (match) => language == 'ar'
            ? 'الموعد المستهدف ${match[1]}'
            : 'Objectif ${match[1]}',
      ),
      (
        RegExp(r'^Delete (.+)$'),
        (match) =>
            language == 'ar' ? 'حذف ${match[1]}' : 'Supprimer ${match[1]}',
      ),
      (
        RegExp(r'^Edit (.+)$'),
        (match) =>
            language == 'ar' ? 'تعديل ${match[1]}' : 'Modifier ${match[1]}',
      ),
      (
        RegExp(r'^Contribute to (.+)$'),
        (match) => language == 'ar'
            ? 'المساهمة في ${match[1]}'
            : 'Contribuer à ${match[1]}',
      ),
      (
        RegExp(r'^Mark (.+) paid$'),
        (match) => language == 'ar'
            ? 'تحديد ${match[1]} كمدفوعة'
            : 'Marquer ${match[1]} comme payée',
      ),
      (
        RegExp(r'^Mark (.+) unpaid$'),
        (match) => language == 'ar'
            ? 'تحديد ${match[1]} كغير مدفوعة'
            : 'Marquer ${match[1]} comme impayée',
      ),
      (
        RegExp(r'^Safe to spend (.+)$'),
        (match) => language == 'ar'
            ? 'المبلغ الآمن للصرف ${match[1]}'
            : 'Montant disponible ${match[1]}',
      ),
      (
        RegExp(r'^Savings rate (.+)$'),
        (match) => language == 'ar'
            ? 'نسبة الادخار ${match[1]}'
            : 'Taux d’épargne ${match[1]}',
      ),
      (
        RegExp(r'^Last checked (.+)$'),
        (match) => language == 'ar'
            ? 'آخر فحص ${match[1]}'
            : 'Dernière vérification ${match[1]}',
      ),
      (
        RegExp(r'^Too many attempts\. Try again in (\d+) seconds\.$'),
        (match) => language == 'ar'
            ? 'محاولات كثيرة. حاول مجدداً بعد ${match[1]} ثانية.'
            : 'Trop de tentatives. Réessayez dans ${match[1]} secondes.',
      ),
      (
        RegExp(r'^Approval required: (.+)$'),
        (match) => language == 'ar'
            ? 'الموافقة مطلوبة: ${match[1]}'
            : 'Approbation requise : ${match[1]}',
      ),
      (
        RegExp(r'^(.+) budget actions$'),
        (match) => language == 'ar'
            ? 'إجراءات ميزانية ${match[1]}'
            : 'Actions du budget ${match[1]}',
      ),
      (
        RegExp(r'^(.+) actions$'),
        (match) =>
            language == 'ar' ? 'إجراءات ${match[1]}' : 'Actions de ${match[1]}',
      ),
      (
        RegExp(r'^of (.+)$'),
        (match) => language == 'ar' ? 'من ${match[1]}' : 'sur ${match[1]}',
      ),
      (
        RegExp(r'^Can I afford (.+) for (.+)\?$'),
        (match) => language == 'ar'
            ? 'هل أستطيع شراء ${match[1]} بسعر ${match[2]}؟'
            : 'Puis-je acheter ${match[1]} pour ${match[2]} ?',
      ),
      (
        RegExp(r'^Deleting (.+) also removes its (\d+) local transactions\.$'),
        (match) => language == 'ar'
            ? 'سيؤدي حذف ${match[1]} أيضاً إلى حذف ${match[2]} من معاملاته المحلية.'
            : 'La suppression de ${match[1]} supprimera aussi ses ${match[2]} transactions locales.',
      ),
      (
        RegExp(r'^That page is unavailable: (.+)$'),
        (match) => language == 'ar'
            ? 'هذه الصفحة غير متاحة: ${match[1]}'
            : 'Cette page n’est pas disponible : ${match[1]}',
      ),
      (
        RegExp(
          r'^At the current recorded monthly surplus, closing the gap would take roughly (\d+) days?\.$',
        ),
        (match) => language == 'ar'
            ? 'بحسب الفائض الشهري المسجل حالياً، يستغرق تغطية الفرق نحو ${match[1]} يوماً.'
            : 'Avec l’excédent mensuel actuellement enregistré, combler l’écart prendrait environ ${match[1]} jours.',
      ),
      (
        RegExp(
          r'^The purchase fits the records you entered\. Your (\d+) day pause ends on (.+)\.$',
        ),
        (match) => language == 'ar'
            ? 'يناسب الشراء البيانات التي أدخلتها. تنتهي فترة الانتظار المحددة ومدتها ${match[1]} أيام في ${match[2]}.'
            : 'L’achat correspond aux données saisies. Votre délai de réflexion de ${match[1]} jours se termine le ${match[2]}.',
      ),
      (
        RegExp(r'^You said: (.+)$', dotAll: true),
        (match) => language == 'ar'
            ? 'قلت: ${match[1]}'
            : 'Vous avez dit : ${match[1]}',
      ),
      (
        RegExp(r'^Coach said: (.+)$', dotAll: true),
        (match) => language == 'ar'
            ? 'قال المساعد: ${match[1]}'
            : 'Le Coach a dit : ${match[1]}',
      ),
      (
        RegExp(r'^(.+) page$'),
        (match) => language == 'ar'
            ? 'صفحة ${translate(match[1]!)}'
            : 'Page ${translate(match[1]!)}',
      ),
    ];
    for (final (pattern, replacement) in patterns) {
      final match = pattern.firstMatch(source);
      if (match != null) return replacement(match);
    }
    return source;
  }

  static const _translations = <String, Map<String, String>>{
    'en': {
      'nav:/dashboard': 'Overview',
      'nav:/transactions': 'Transactions',
      'nav:/accounts': 'Accounts',
      'nav:/budgets': 'Budgets',
      'nav:/bills': 'Bills',
      'nav:/goals': 'Goals',
      'nav:/reports': 'Reports',
      'nav:/calendar': 'Calendar',
      'nav:/coach': 'AI Coach',
      'nav:/purchase-check': 'Purchase Check',
      'nav:/settings': 'Settings',
      'activity': 'Activity',
      'plan': 'Plan',
      'coach': 'Coach',
      'more': 'More',
      'tools': 'MoneyPilot tools',
      'offlineReady': 'Offline ready',
      'savedLocally': 'All changes are saved locally',
      'localChangesSaved': 'Local changes saved',
      'addTransaction': 'Add transaction',
      'settingsTitle': 'Settings & privacy',
      'settingsSubtitle':
          'Control your account, coach, appearance, and local data.',
      'appearance': 'Appearance & language',
      'language': 'Language',
      'languageHelp': 'Changes the app direction and the Coach reply language.',
      'english': 'English',
      'french': 'French',
      'arabic': 'Arabic',
      'theme': 'Theme',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'highContrast': 'High contrast',
      'highContrastHelp': 'Stronger borders and color separation.',
      'coachTitle': 'AI Coach',
      'coachSubtitle':
          'A private, conversational coach grounded in your local data.',
      'localAiReady': 'Local AI ready',
      'clearConversation': 'Clear conversation',
      'coachWelcomeTitle': 'What should we work through?',
      'coachWelcomeBody':
          'Ask naturally. If a number is missing, I will say so and help you add the right input.',
      'whatCanYouDo': 'What can you do?',
      'explainSafe': 'Explain safe to spend',
      'reviewCashFlow': 'Review my cash flow',
      'reviewDining': 'Review dining budget',
      'upcomingBills': 'Upcoming bills',
      'canIAfford': 'Can I afford it?',
      'askHint': 'Type any money question…',
      'sendMessage': 'Send message',
      'checkingNumbers': 'Checking your numbers…',
      'coachContext': 'Coach context',
      'coachContextBody':
          'The Local Coach reads only this signed in profile and never invents missing numbers.',
      'openBills': 'Open bills',
      'safetyContract': 'Safety contract',
      'explainsBasis': 'Explains the basis for suggestions',
      'followUps': 'Supports ongoing conversation',
      'oneAction': 'Prepares one explicit action at a time',
      'confirmation': 'Requires confirmation before applying',
      'neverMovesMoney': 'Never moves money',
      'educational': 'AI guidance is educational and not financial advice.',
    },
    'fr': {
      'nav:/dashboard': 'Vue d’ensemble',
      'nav:/transactions': 'Transactions',
      'nav:/accounts': 'Comptes',
      'nav:/budgets': 'Budgets',
      'nav:/bills': 'Factures',
      'nav:/goals': 'Objectifs',
      'nav:/reports': 'Rapports',
      'nav:/calendar': 'Calendrier',
      'nav:/coach': 'Coach IA',
      'nav:/purchase-check': 'Vérifier un achat',
      'nav:/settings': 'Paramètres',
      'activity': 'Activité',
      'plan': 'Plan',
      'coach': 'Coach',
      'more': 'Plus',
      'tools': 'Outils MoneyPilot',
      'offlineReady': 'Prêt hors ligne',
      'savedLocally': 'Toutes les modifications sont enregistrées localement',
      'localChangesSaved': 'Modifications locales enregistrées',
      'addTransaction': 'Ajouter une transaction',
      'settingsTitle': 'Paramètres et confidentialité',
      'settingsSubtitle':
          'Gérez votre compte, le coach, l’apparence et les données locales.',
      'appearance': 'Apparence et langue',
      'language': 'Langue',
      'languageHelp':
          'Modifie la direction de l’application et la langue des réponses du Coach.',
      'english': 'Anglais',
      'french': 'Français',
      'arabic': 'Arabe',
      'theme': 'Thème',
      'system': 'Système',
      'light': 'Clair',
      'dark': 'Sombre',
      'highContrast': 'Contraste élevé',
      'highContrastHelp': 'Bordures et séparation des couleurs renforcées.',
      'coachTitle': 'Coach IA',
      'coachSubtitle':
          'Un coach privé et conversationnel basé sur vos données locales.',
      'localAiReady': 'IA locale prête',
      'clearConversation': 'Effacer la conversation',
      'coachWelcomeTitle': 'Que souhaitez-vous analyser ?',
      'coachWelcomeBody':
          'Posez votre question naturellement. S’il manque un chiffre, je vous le dirai sans rien inventer.',
      'whatCanYouDo': 'Que peux-tu faire ?',
      'explainSafe': 'Expliquer le montant disponible',
      'reviewCashFlow': 'Analyser ma trésorerie',
      'reviewDining': 'Analyser le budget restaurants',
      'upcomingBills': 'Factures à venir',
      'canIAfford': 'Puis-je me le permettre ?',
      'askHint': 'Écrivez votre question financière…',
      'sendMessage': 'Envoyer',
      'checkingNumbers': 'Analyse de vos chiffres…',
      'coachContext': 'Contexte du Coach',
      'coachContextBody':
          'Le Coach local lit uniquement ce profil et n’invente jamais les chiffres manquants.',
      'openBills': 'Factures ouvertes',
      'safetyContract': 'Contrat de sécurité',
      'explainsBasis': 'Explique la base de chaque suggestion',
      'followUps': 'Accepte les questions de suivi',
      'oneAction': 'Prépare une seule action explicite à la fois',
      'confirmation': 'Demande votre confirmation avant application',
      'neverMovesMoney': 'Ne déplace jamais d’argent',
      'educational':
          'Les conseils de l’IA sont éducatifs et ne constituent pas un conseil financier.',
    },
    'ar': {
      'nav:/dashboard': 'نظرة عامة',
      'nav:/transactions': 'المعاملات',
      'nav:/accounts': 'الحسابات',
      'nav:/budgets': 'الميزانيات',
      'nav:/bills': 'الفواتير',
      'nav:/goals': 'الأهداف',
      'nav:/reports': 'التقارير',
      'nav:/calendar': 'التقويم',
      'nav:/coach': 'المساعد الذكي',
      'nav:/purchase-check': 'فحص الشراء',
      'nav:/settings': 'الإعدادات',
      'activity': 'النشاط',
      'plan': 'الخطة',
      'coach': 'المساعد',
      'more': 'المزيد',
      'tools': 'أدوات MoneyPilot',
      'offlineReady': 'جاهز دون إنترنت',
      'savedLocally': 'تم حفظ جميع التغييرات محلياً',
      'localChangesSaved': 'تم حفظ التغييرات محلياً',
      'addTransaction': 'إضافة معاملة',
      'settingsTitle': 'الإعدادات والخصوصية',
      'settingsSubtitle': 'تحكّم في حسابك والمساعد والمظهر والبيانات المحلية.',
      'appearance': 'المظهر واللغة',
      'language': 'اللغة',
      'languageHelp': 'تغيّر اتجاه التطبيق ولغة ردود المساعد.',
      'english': 'الإنجليزية',
      'french': 'الفرنسية',
      'arabic': 'العربية',
      'theme': 'المظهر',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'highContrast': 'تباين مرتفع',
      'highContrastHelp': 'حدود أوضح وفصل أقوى بين الألوان.',
      'coachTitle': 'المساعد الذكي',
      'coachSubtitle': 'مساعد خاص وحواري يعتمد على بياناتك المحلية.',
      'localAiReady': 'المساعد المحلي جاهز',
      'clearConversation': 'مسح المحادثة',
      'coachWelcomeTitle': 'ما الذي تريد أن نحلّله؟',
      'coachWelcomeBody':
          'اسأل بطريقتك الطبيعية. إذا كان رقم ما مفقوداً سأخبرك ولن أخترع أي بيانات.',
      'whatCanYouDo': 'ماذا يمكنك أن تفعل؟',
      'explainSafe': 'اشرح المبلغ الآمن للصرف',
      'reviewCashFlow': 'راجع تدفقي النقدي',
      'reviewDining': 'راجع ميزانية المطاعم',
      'upcomingBills': 'الفواتير القادمة',
      'canIAfford': 'هل أستطيع شراءه؟',
      'askHint': 'اكتب أي سؤال مالي…',
      'sendMessage': 'إرسال',
      'checkingNumbers': 'جارٍ تحليل أرقامك…',
      'coachContext': 'سياق المساعد',
      'coachContextBody':
          'يقرأ المساعد المحلي هذا الملف فقط ولا يخترع الأرقام المفقودة.',
      'openBills': 'الفواتير المفتوحة',
      'safetyContract': 'عقد الأمان',
      'explainsBasis': 'يشرح أساس كل اقتراح',
      'followUps': 'يدعم الأسئلة المتابعة',
      'oneAction': 'يحضّر إجراءً واضحاً واحداً في كل مرة',
      'confirmation': 'يطلب تأكيدك قبل تطبيق أي تغيير',
      'neverMovesMoney': 'لا ينقل الأموال أبداً',
      'educational': 'إرشادات المساعد تعليمية وليست نصيحة مالية.',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
    this.selectionColor,
  });

  final String data;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final TextScaler? textScaler;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;
  final Color? selectionColor;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Text(
      l10n.translate(data),
      style: style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaler: textScaler,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel == null
          ? null
          : l10n.translate(semanticsLabel!),
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
      selectionColor: selectionColor,
    );
  }
}
