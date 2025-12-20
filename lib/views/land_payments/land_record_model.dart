class LandPaymentRecord {
  final String id;
  final String srNo;
  final String title;
  final String description;
  final double amount;
  final DateTime date;

  LandPaymentRecord({
    required this.id,
    required this.srNo,
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
  });
}
