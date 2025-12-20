import 'package:uuid/uuid.dart';

class ProfitSchedule {
  final String id;
  final String calculationType;
  final double value;
  final int profitDuration;
  final int agreementDuration;
  final bool isActive;

  ProfitSchedule({
    required this.id,
    required this.calculationType,
    required this.value,
    required this.profitDuration,
    required this.agreementDuration,
    required this.isActive,
  });

  factory ProfitSchedule.fromJson(Map<String, dynamic> json) {
    return ProfitSchedule(
      id: json['id'] as String? ?? const Uuid().v4(),
      calculationType: json['calculation_type'] as String? ?? 'approx',
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      profitDuration: (json['profit_duration'] as num?)?.toInt() ?? 1,
      agreementDuration: (json['agreement_duration'] as num?)?.toInt() ?? 6,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
