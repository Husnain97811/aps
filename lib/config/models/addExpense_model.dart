import 'package:flutter/material.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;

  ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
  });
}

class Expense {
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final String? dealerNo; // Make dealerNo nullable
  final String? membershipNo; // Make membershipNo nullable

  Expense({
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.dealerNo, // Make dealerNo optional
    this.membershipNo, // Make membershipNo optional
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      description: json['description'] ?? '',
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      date: DateTime.tryParse(json['date']) ?? DateTime.now(),
      category: json['category'] ?? 'Unknown',
      dealerNo: json['dealer_no'], // Read from JSON
      membershipNo: json['membership_no'], // Read from JSON
    );
  }
}
