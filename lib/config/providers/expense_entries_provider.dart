import 'package:aps/config/models/modify_expense_model.dart';
import 'package:flutter/foundation.dart';

class ExpenseProvider with ChangeNotifier {
  List<ModifyExpenseModel> _allExpenses = [];
  List<ModifyExpenseModel> _filteredExpenses = [];
  String _searchQuery = '';

  List<ModifyExpenseModel> get filteredExpenses => _filteredExpenses;
  String get searchQuery => _searchQuery;

  void setExpenses(List<ModifyExpenseModel> expenses) {
    _allExpenses = expenses;
    _applyFilter();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilter();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredExpenses = List.from(_allExpenses);
    } else {
      _filteredExpenses =
          _allExpenses.where((expense) {
            final descriptionMatch = expense.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            );

            // Check if membership_no exists and matches
            final membershipMatch =
                expense.membership_no != null &&
                expense.membership_no!.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                );

            return descriptionMatch || membershipMatch;
          }).toList();
    }
    notifyListeners();
  }
}
