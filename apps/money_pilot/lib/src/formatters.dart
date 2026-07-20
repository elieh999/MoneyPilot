import 'package:intl/intl.dart';

class MoneyFormatter {
  MoneyFormatter._();

  static final NumberFormat _whole = NumberFormat.decimalPattern('en_US');
  static const int _maxInt64 = 9223372036854775807;

  static String amount(int minor) {
    final absolute = minor.abs();
    final major = absolute ~/ 100;
    final fraction = (absolute % 100).toString().padLeft(2, '0');
    final value = '\$${_whole.format(major)}.$fraction';
    return minor < 0 ? '-$value' : value;
  }

  static String input(int minor, {bool absolute = false}) {
    final value = absolute ? minor.abs() : minor;
    final magnitude = value.abs();
    final major = magnitude ~/ 100;
    final fraction = (magnitude % 100).toString().padLeft(2, '0');
    return '${value < 0 ? '-' : ''}$major.$fraction';
  }

  static int? parseInputToMinor(
    String input, {
    bool allowNegative = false,
    bool allowZero = false,
  }) {
    var normalized = input.trim();
    if (normalized.startsWith(r'$')) {
      normalized = normalized.substring(1).trim();
    }
    normalized = normalized.replaceAll(',', '');
    if (normalized.startsWith('-.')) {
      normalized = '-0${normalized.substring(1)}';
    } else if (normalized.startsWith('.')) {
      normalized = '0$normalized';
    }
    final match = RegExp(
      r'^(-)?([0-9]+)(?:\.([0-9]{1,2}))?$',
    ).firstMatch(normalized);
    if (match == null) return null;
    final negative = match.group(1) != null;
    if (negative && !allowNegative) return null;
    final major = int.tryParse(match.group(2)!);
    if (major == null || major > _maxInt64 ~/ 100) return null;
    final fractionText = (match.group(3) ?? '').padRight(2, '0');
    final fraction = fractionText.isEmpty ? 0 : int.parse(fractionText);
    if (major == _maxInt64 ~/ 100 && fraction > _maxInt64 % 100) return null;
    final unsigned = major * 100 + fraction;
    if (unsigned > _maxInt64 || (!allowZero && unsigned == 0)) return null;
    return negative ? -unsigned : unsigned;
  }

  static String compact(int minor) {
    final absolute = minor.abs();
    final (divisor, suffix) = switch (absolute) {
      >= 100000000000 => (100000000000, 'B'),
      >= 100000000 => (100000000, 'M'),
      >= 100000 => (100000, 'K'),
      _ => (0, ''),
    };
    if (divisor == 0) return amount(minor);
    var whole = absolute ~/ divisor;
    var tenth = (((absolute % divisor) * 10) + divisor ~/ 2) ~/ divisor;
    if (tenth == 10) {
      whole += 1;
      tenth = 0;
    }
    final value = tenth == 0 ? '\$$whole$suffix' : '\$$whole.$tenth$suffix';
    return minor < 0 ? '-$value' : value;
  }

  static String percent(int basisPoints) {
    final absolute = basisPoints.abs();
    final whole = absolute ~/ 100;
    final remainder = absolute % 100;
    final fraction = remainder == 0
        ? ''
        : remainder % 10 == 0
        ? '.${remainder ~/ 10}'
        : '.${remainder.toString().padLeft(2, '0')}';
    return '${basisPoints < 0 ? '-' : ''}$whole$fraction%';
  }
}

class DateFormats {
  DateFormats._();

  static final DateFormat short = DateFormat('MMM d');
  static final DateFormat medium = DateFormat('MMM d, y');
  static final DateFormat month = DateFormat('MMMM y');
}
