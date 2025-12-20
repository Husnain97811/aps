import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';

class CategoryProvider with ChangeNotifier {
  ExpenseCategory? _selectedCategory;

  ExpenseCategory? get selectedCategory => _selectedCategory;

  void setSelectedCategory(ExpenseCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
