class ModifyExpenseModel {
  final String id;
  final double amount;
  final String description;
  final String membership_no;
  final String sr_no;
  final String category;
  final DateTime date;

  ModifyExpenseModel({
    required this.id,
    required this.amount,
    required this.description,
    required this.membership_no,
    required this.sr_no,
    required this.category,
    required this.date,
  });

  factory ModifyExpenseModel.fromJson(Map<String, dynamic> json) =>
      ModifyExpenseModel(
        id: json['id']?.toString() ?? '',
        amount: (json['amount'] as num).toDouble(),
        description: json['description']?.toString() ?? '',
        sr_no: json['sr_no']?.toString() ?? '',
        membership_no: json['membership_no']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Uncategorized',
        date: DateTime.parse(
          json['date']?.toString() ?? DateTime.now().toIso8601String(),
        ),
      );
}
