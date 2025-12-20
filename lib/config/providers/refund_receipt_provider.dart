// refund_receipts_provider.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RefundReceiptsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allReceipts = [];
  List<Map<String, dynamic>> _filteredReceipts = [];
  String _searchQuery = '';
  bool _isLoading = false;

  List<Map<String, dynamic>> get filteredReceipts => _filteredReceipts;
  bool get isLoading => _isLoading;

  RefundReceiptsProvider() {
    fetchRefundReceipts();
  }

  Future<void> fetchRefundReceipts() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Fetch receipts with client name from membership_forms
      final response = await _supabase
          .from('refund_receipts')
          .select('*, membership_forms:membership_no(name)')
          .order('generated_date', ascending: false);

      _allReceipts = List<Map<String, dynamic>>.from(response);
      _applySearch();
    } catch (e) {
      _allReceipts = [];
      _filteredReceipts = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applySearch();
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filteredReceipts = _allReceipts;
    } else {
      _filteredReceipts =
          _allReceipts.where((receipt) {
            final name =
                receipt['membership_forms']?['name']
                    ?.toString()
                    .toLowerCase() ??
                '';
            final receiptNo =
                receipt['receipt_no']?.toString().toLowerCase() ?? '';
            return name.contains(_searchQuery) ||
                receiptNo.contains(_searchQuery);
          }).toList();
    }
    notifyListeners();
  }

  Future<void> refreshData() async {
    await fetchRefundReceipts();
  }
}
