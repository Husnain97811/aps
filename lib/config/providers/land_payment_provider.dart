import 'package:aps/views/land_payments/land_record_model.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LandPaymentProvider extends ChangeNotifier {
  List<LandPaymentRecord> _allRecords = [];
  List<LandPaymentRecord> _filteredRecords = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<LandPaymentRecord> get filteredRecords => _filteredRecords;
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;

  Future<void> fetchRecords(SupabaseClient supabase) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await supabase
          .from('land_payment_records')
          .select('id, sr_no, title, description, amount, date')
          .order('date', ascending: false);

      _allRecords =
          (response as List).map((record) {
            return LandPaymentRecord(
              id: record['id'],
              srNo: record['sr_no'],
              title: record['title'],
              description: record['description'],
              amount: record['amount'],
              date: DateTime.parse(record['date']),
            );
          }).toList();

      _filteredRecords = _allRecords;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _filterRecords();
    notifyListeners();
  }

  void _filterRecords() {
    if (_searchQuery.isEmpty) {
      _filteredRecords = _allRecords;
    } else {
      final query = _searchQuery.toLowerCase();
      _filteredRecords =
          _allRecords.where((record) {
            return record.title.toLowerCase().contains(query) ||
                record.description.toLowerCase().contains(query) ||
                record.srNo.toLowerCase().contains(query) ||
                record.amount.toString().contains(query);
          }).toList();
    }
  }

  void refreshRecords(SupabaseClient supabase) {
    fetchRecords(supabase);
  }
}
