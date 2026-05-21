import 'package:intl/intl.dart';

import '../../../shared/widgets/status_pill.dart';

String cardCheckStatusLabel(String status) => switch (status) {
      'available' => 'متاحة',
      'active' => 'نشطة',
      'expired' => 'منتهية',
      'revoked' => 'معطلة',
      'deleted' => 'محذوفة',
      'not_found' => 'غير موجودة',
      _ => status,
    };

PillTone cardCheckStatusTone(String status) => switch (status) {
      'available' => PillTone.green,
      'active' => PillTone.cyan,
      'expired' => PillTone.orange,
      'revoked' || 'deleted' => PillTone.red,
      _ => PillTone.neutral,
    };

String formatCheckDate(DateTime? value) {
  if (value == null) return 'غير معروف';
  return DateFormat('yyyy-MM-dd HH:mm').format(value.toLocal());
}

String formatCheckDuration(int seconds) {
  if (seconds <= 0) return 'غير محدد';
  final d = Duration(seconds: seconds);
  if (d.inDays > 0) return '${d.inDays}ي ${d.inHours.remainder(24)}س';
  if (d.inHours > 0) return '${d.inHours}س ${d.inMinutes.remainder(60)}د';
  if (d.inMinutes > 0) return '${d.inMinutes}د ${d.inSeconds.remainder(60)}ث';
  return '${d.inSeconds}ث';
}

String formatCheckBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(value < 10 ? 1 : 0)} ${units[unit]}';
}

String joinLocalizedFields(List<String> values) {
  if (values.isEmpty) return 'غير متوفر';
  return values.map(_fieldLabel).join('، ');
}

String _fieldLabel(String value) => switch (value) {
      'assigned_to' => 'المسؤول عن البطاقة',
      'cancelled_at' => 'وقت الإلغاء',
      'deleted_at' => 'وقت الأرشفة',
      'sold_by' => 'البائع',
      'cards' => 'بيانات البطاقات',
      'card_batches' => 'حزم البطاقات',
      'radacct' => 'جلسات الاتصال',
      'profiles' => 'العروض',
      'nas' => 'أجهزة الشبكة',
      'accounting' => 'المحاسبة',
      _ => value.replaceAll('_', ' '),
    };
