import 'package:money_pilot/src/models.dart';

/// A real user's workspace starts with useful category labels and no financial
/// records. Categories are definitions, not transactions or sample balances.
AppData buildEmptyData({bool onboardingComplete = false}) => AppData(
  accounts: const [],
  categories: defaultCategories,
  transactions: const [],
  budgets: const [],
  bills: const [],
  goals: const [],
  messages: const [],
  settings: const AppSettings(),
  onboardingComplete: onboardingComplete,
);

const defaultCategories = [
  SpendingCategory(
    id: 'salary',
    name: 'Income',
    iconCode: 0xe227,
    colorValue: 0xFF1D9B68,
  ),
  SpendingCategory(
    id: 'housing',
    name: 'Housing',
    iconCode: 0xe318,
    colorValue: 0xFF5B6EE1,
  ),
  SpendingCategory(
    id: 'groceries',
    name: 'Groceries',
    iconCode: 0xe547,
    colorValue: 0xFFF08A5D,
  ),
  SpendingCategory(
    id: 'dining',
    name: 'Dining',
    iconCode: 0xe56c,
    colorValue: 0xFFE86F91,
  ),
  SpendingCategory(
    id: 'transport',
    name: 'Transport',
    iconCode: 0xe1d7,
    colorValue: 0xFF2F9CCB,
  ),
  SpendingCategory(
    id: 'utilities',
    name: 'Utilities',
    iconCode: 0xe63c,
    colorValue: 0xFF8E6CC0,
  ),
  SpendingCategory(
    id: 'wellness',
    name: 'Wellness',
    iconCode: 0xe3f3,
    colorValue: 0xFF33A6A6,
  ),
  SpendingCategory(
    id: 'shopping',
    name: 'Shopping',
    iconCode: 0xe59c,
    colorValue: 0xFFD69B2D,
  ),
  SpendingCategory(
    id: 'travel',
    name: 'Travel',
    iconCode: 0xe539,
    colorValue: 0xFF4776D0,
  ),
  SpendingCategory(
    id: 'other',
    name: 'Other',
    iconCode: 0xe5d3,
    colorValue: 0xFF747B8A,
  ),
];
