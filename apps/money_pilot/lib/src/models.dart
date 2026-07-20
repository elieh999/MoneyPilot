import 'dart:convert';

typedef Json = Map<String, dynamic>;

class MoneyAccount {
  const MoneyAccount({
    required this.id,
    required this.name,
    required this.type,
    required this.balanceMinor,
    required this.colorValue,
    this.includedInSafeToSpend = true,
  });

  final String id;
  final String name;
  final String type;
  final int balanceMinor;
  final int colorValue;
  final bool includedInSafeToSpend;

  bool get isCredit => type == 'Credit card';

  MoneyAccount copyWith({
    String? name,
    String? type,
    int? balanceMinor,
    int? colorValue,
    bool? includedInSafeToSpend,
  }) => MoneyAccount(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    balanceMinor: balanceMinor ?? this.balanceMinor,
    colorValue: colorValue ?? this.colorValue,
    includedInSafeToSpend: includedInSafeToSpend ?? this.includedInSafeToSpend,
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'balanceMinor': balanceMinor,
    'colorValue': colorValue,
    'includedInSafeToSpend': includedInSafeToSpend,
  };

  factory MoneyAccount.fromJson(Json json) => MoneyAccount(
    id: json['id'] as String,
    name: json['name'] as String,
    type: json['type'] as String,
    balanceMinor: json['balanceMinor'] as int,
    colorValue: json['colorValue'] as int,
    includedInSafeToSpend: json['includedInSafeToSpend'] as bool? ?? true,
  );
}

class SpendingCategory {
  const SpendingCategory({
    required this.id,
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });

  final String id;
  final String name;
  final int iconCode;
  final int colorValue;

  SpendingCategory copyWith({String? name, int? iconCode, int? colorValue}) =>
      SpendingCategory(
        id: id,
        name: name ?? this.name,
        iconCode: iconCode ?? this.iconCode,
        colorValue: colorValue ?? this.colorValue,
      );

  Json toJson() => {
    'id': id,
    'name': name,
    'iconCode': iconCode,
    'colorValue': colorValue,
  };

  factory SpendingCategory.fromJson(Json json) => SpendingCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    iconCode: json['iconCode'] as int,
    colorValue: json['colorValue'] as int,
  );
}

class FinanceTransaction {
  const FinanceTransaction({
    required this.id,
    required this.accountId,
    required this.categoryId,
    required this.title,
    required this.amountMinor,
    required this.date,
    this.note = '',
    this.isPending = false,
  });

  final String id;
  final String accountId;
  final String categoryId;
  final String title;
  final String note;
  final int amountMinor;
  final DateTime date;
  final bool isPending;

  bool get isIncome => amountMinor >= 0;

  FinanceTransaction copyWith({
    String? accountId,
    String? categoryId,
    String? title,
    String? note,
    int? amountMinor,
    DateTime? date,
    bool? isPending,
  }) => FinanceTransaction(
    id: id,
    accountId: accountId ?? this.accountId,
    categoryId: categoryId ?? this.categoryId,
    title: title ?? this.title,
    note: note ?? this.note,
    amountMinor: amountMinor ?? this.amountMinor,
    date: date ?? this.date,
    isPending: isPending ?? this.isPending,
  );

  Json toJson() => {
    'id': id,
    'accountId': accountId,
    'categoryId': categoryId,
    'title': title,
    'note': note,
    'amountMinor': amountMinor,
    'date': date.toIso8601String(),
    'isPending': isPending,
  };

  factory FinanceTransaction.fromJson(Json json) => FinanceTransaction(
    id: json['id'] as String,
    accountId: json['accountId'] as String,
    categoryId: json['categoryId'] as String,
    title: json['title'] as String,
    note: json['note'] as String? ?? '',
    amountMinor: json['amountMinor'] as int,
    date: DateTime.parse(json['date'] as String),
    isPending: json['isPending'] as bool? ?? false,
  );
}

class Budget {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.plannedMinor,
    required this.month,
  });

  final String id;
  final String categoryId;
  final int plannedMinor;
  final DateTime month;

  Budget copyWith({String? categoryId, int? plannedMinor, DateTime? month}) =>
      Budget(
        id: id,
        categoryId: categoryId ?? this.categoryId,
        plannedMinor: plannedMinor ?? this.plannedMinor,
        month: month ?? this.month,
      );

  Json toJson() => {
    'id': id,
    'categoryId': categoryId,
    'plannedMinor': plannedMinor,
    'month': month.toIso8601String(),
  };

  factory Budget.fromJson(Json json) => Budget(
    id: json['id'] as String,
    categoryId: json['categoryId'] as String,
    plannedMinor: json['plannedMinor'] as int,
    month: DateTime.parse(json['month'] as String),
  );
}

class Bill {
  const Bill({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.dueDate,
    this.isPaid = false,
    this.autopay = false,
  });

  final String id;
  final String name;
  final int amountMinor;
  final DateTime dueDate;
  final bool isPaid;
  final bool autopay;

  Bill copyWith({
    String? name,
    int? amountMinor,
    DateTime? dueDate,
    bool? isPaid,
    bool? autopay,
  }) => Bill(
    id: id,
    name: name ?? this.name,
    amountMinor: amountMinor ?? this.amountMinor,
    dueDate: dueDate ?? this.dueDate,
    isPaid: isPaid ?? this.isPaid,
    autopay: autopay ?? this.autopay,
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'amountMinor': amountMinor,
    'dueDate': dueDate.toIso8601String(),
    'isPaid': isPaid,
    'autopay': autopay,
  };

  factory Bill.fromJson(Json json) => Bill(
    id: json['id'] as String,
    name: json['name'] as String,
    amountMinor: json['amountMinor'] as int,
    dueDate: DateTime.parse(json['dueDate'] as String),
    isPaid: json['isPaid'] as bool? ?? false,
    autopay: json['autopay'] as bool? ?? false,
  );
}

class SavingsGoal {
  const SavingsGoal({
    required this.id,
    required this.name,
    required this.targetMinor,
    required this.savedMinor,
    required this.targetDate,
  });

  final String id;
  final String name;
  final int targetMinor;
  final int savedMinor;
  final DateTime targetDate;

  SavingsGoal copyWith({
    String? name,
    int? targetMinor,
    int? savedMinor,
    DateTime? targetDate,
  }) => SavingsGoal(
    id: id,
    name: name ?? this.name,
    targetMinor: targetMinor ?? this.targetMinor,
    savedMinor: savedMinor ?? this.savedMinor,
    targetDate: targetDate ?? this.targetDate,
  );

  Json toJson() => {
    'id': id,
    'name': name,
    'targetMinor': targetMinor,
    'savedMinor': savedMinor,
    'targetDate': targetDate.toIso8601String(),
  };

  factory SavingsGoal.fromJson(Json json) => SavingsGoal(
    id: json['id'] as String,
    name: json['name'] as String,
    targetMinor: json['targetMinor'] as int,
    savedMinor: json['savedMinor'] as int,
    targetDate: DateTime.parse(json['targetDate'] as String),
  );
}

class CoachMessage {
  const CoachMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String role;
  final String text;
  final DateTime createdAt;

  Json toJson() => {
    'id': id,
    'role': role,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  factory CoachMessage.fromJson(Json json) => CoachMessage(
    id: json['id'] as String,
    role: json['role'] as String,
    text: json['text'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
  );
}

class CoachAction {
  const CoachAction({
    required this.id,
    required this.title,
    required this.description,
    required this.kind,
    required this.payload,
  });

  final String id;
  final String title;
  final String description;
  final String kind;
  final Json payload;

  Json toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'kind': kind,
    'payload': payload,
  };

  factory CoachAction.fromJson(Json json) => CoachAction(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    kind: json['kind'] as String,
    payload: Map<String, dynamic>.from(json['payload'] as Map),
  );
}

class AppSettings {
  const AppSettings({
    this.themeMode = 'system',
    this.highContrast = false,
    this.analytics = false,
    this.biometricLock = false,
    this.cloudSync = false,
    this.notifications = true,
    this.privacyMode = false,
    this.coachingStyle = 'encouraging',
    this.safetyBufferMinor = 0,
    this.languageCode = 'en',
    this.themePalette = 'ocean',
    this.glowEffects = false,
  });

  final String themeMode;
  final bool highContrast;
  final bool analytics;
  final bool biometricLock;
  final bool cloudSync;
  final bool notifications;
  final bool privacyMode;
  final String coachingStyle;
  final int safetyBufferMinor;
  final String languageCode;
  final String themePalette;
  final bool glowEffects;

  AppSettings copyWith({
    String? themeMode,
    bool? highContrast,
    bool? analytics,
    bool? biometricLock,
    bool? cloudSync,
    bool? notifications,
    bool? privacyMode,
    String? coachingStyle,
    int? safetyBufferMinor,
    String? languageCode,
    String? themePalette,
    bool? glowEffects,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    highContrast: highContrast ?? this.highContrast,
    analytics: analytics ?? this.analytics,
    biometricLock: biometricLock ?? this.biometricLock,
    cloudSync: cloudSync ?? this.cloudSync,
    notifications: notifications ?? this.notifications,
    privacyMode: privacyMode ?? this.privacyMode,
    coachingStyle: coachingStyle ?? this.coachingStyle,
    safetyBufferMinor: safetyBufferMinor ?? this.safetyBufferMinor,
    languageCode: languageCode ?? this.languageCode,
    themePalette: themePalette ?? this.themePalette,
    glowEffects: glowEffects ?? this.glowEffects,
  );

  Json toJson() => {
    'themeMode': themeMode,
    'highContrast': highContrast,
    'analytics': analytics,
    'biometricLock': biometricLock,
    'cloudSync': cloudSync,
    'notifications': notifications,
    'privacyMode': privacyMode,
    'coachingStyle': coachingStyle,
    'safetyBufferMinor': safetyBufferMinor,
    'languageCode': languageCode,
    'themePalette': themePalette,
    'glowEffects': glowEffects,
  };

  factory AppSettings.fromJson(Json json) => AppSettings(
    themeMode: json['themeMode'] as String? ?? 'system',
    highContrast: json['highContrast'] as bool? ?? false,
    analytics: json['analytics'] as bool? ?? false,
    biometricLock: json['biometricLock'] as bool? ?? false,
    cloudSync: json['cloudSync'] as bool? ?? false,
    notifications: json['notifications'] as bool? ?? true,
    privacyMode: json['privacyMode'] as bool? ?? false,
    coachingStyle: json['coachingStyle'] as String? ?? 'encouraging',
    safetyBufferMinor: json['safetyBufferMinor'] as int? ?? 0,
    languageCode: switch (json['languageCode'] as String?) {
      'fr' => 'fr',
      'ar' => 'ar',
      _ => 'en',
    },
    themePalette: switch (json['themePalette'] as String?) {
      'cyan' => 'cyan',
      'forest' => 'forest',
      'violet' => 'violet',
      'sunset' => 'sunset',
      _ => 'ocean',
    },
    glowEffects: json['glowEffects'] as bool? ?? false,
  );
}

class AppData {
  const AppData({
    required this.accounts,
    required this.categories,
    required this.transactions,
    required this.budgets,
    required this.bills,
    required this.goals,
    required this.messages,
    required this.settings,
    this.pendingCoachAction,
    this.onboardingComplete = false,
    this.syncStatus = 'Local changes saved',
    this.lastSyncAt,
    this.coachThinking = false,
  });

  final List<MoneyAccount> accounts;
  final List<SpendingCategory> categories;
  final List<FinanceTransaction> transactions;
  final List<Budget> budgets;
  final List<Bill> bills;
  final List<SavingsGoal> goals;
  final List<CoachMessage> messages;
  final CoachAction? pendingCoachAction;
  final AppSettings settings;
  final bool onboardingComplete;
  final String syncStatus;
  final DateTime? lastSyncAt;
  final bool coachThinking;

  AppData copyWith({
    List<MoneyAccount>? accounts,
    List<SpendingCategory>? categories,
    List<FinanceTransaction>? transactions,
    List<Budget>? budgets,
    List<Bill>? bills,
    List<SavingsGoal>? goals,
    List<CoachMessage>? messages,
    CoachAction? pendingCoachAction,
    bool clearPendingCoachAction = false,
    AppSettings? settings,
    bool? onboardingComplete,
    String? syncStatus,
    DateTime? lastSyncAt,
    bool? coachThinking,
  }) => AppData(
    accounts: accounts ?? this.accounts,
    categories: categories ?? this.categories,
    transactions: transactions ?? this.transactions,
    budgets: budgets ?? this.budgets,
    bills: bills ?? this.bills,
    goals: goals ?? this.goals,
    messages: messages ?? this.messages,
    pendingCoachAction: clearPendingCoachAction
        ? null
        : pendingCoachAction ?? this.pendingCoachAction,
    settings: settings ?? this.settings,
    onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    syncStatus: syncStatus ?? this.syncStatus,
    lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    coachThinking: coachThinking ?? this.coachThinking,
  );

  Json toJson() => {
    'accounts': accounts.map((item) => item.toJson()).toList(),
    'categories': categories.map((item) => item.toJson()).toList(),
    'transactions': transactions.map((item) => item.toJson()).toList(),
    'budgets': budgets.map((item) => item.toJson()).toList(),
    'bills': bills.map((item) => item.toJson()).toList(),
    'goals': goals.map((item) => item.toJson()).toList(),
    'messages': messages.map((item) => item.toJson()).toList(),
    'pendingCoachAction': pendingCoachAction?.toJson(),
    'settings': settings.toJson(),
    'onboardingComplete': onboardingComplete,
    'syncStatus': syncStatus,
    'lastSyncAt': lastSyncAt?.toIso8601String(),
  };

  factory AppData.fromJson(Json json) => AppData(
    accounts: (json['accounts'] as List)
        .map(
          (item) =>
              MoneyAccount.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    categories: (json['categories'] as List)
        .map(
          (item) =>
              SpendingCategory.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    transactions: (json['transactions'] as List)
        .map(
          (item) => FinanceTransaction.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList(),
    budgets: (json['budgets'] as List)
        .map((item) => Budget.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    bills: (json['bills'] as List)
        .map((item) => Bill.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    goals: (json['goals'] as List)
        .map(
          (item) =>
              SavingsGoal.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    messages: (json['messages'] as List? ?? const [])
        .map(
          (item) =>
              CoachMessage.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList(),
    pendingCoachAction: json['pendingCoachAction'] == null
        ? null
        : CoachAction.fromJson(
            Map<String, dynamic>.from(json['pendingCoachAction'] as Map),
          ),
    settings: AppSettings.fromJson(
      Map<String, dynamic>.from(json['settings'] as Map? ?? const {}),
    ),
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    syncStatus: json['syncStatus'] as String? ?? 'Local changes saved',
    lastSyncAt: json['lastSyncAt'] == null
        ? null
        : DateTime.parse(json['lastSyncAt'] as String),
    coachThinking: false,
  );

  String encode() => jsonEncode(toJson());
  factory AppData.decode(String value) =>
      AppData.fromJson(Map<String, dynamic>.from(jsonDecode(value) as Map));
}
