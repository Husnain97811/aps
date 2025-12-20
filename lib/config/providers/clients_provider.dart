import 'dart:math';

import 'package:aps/config/components/widgets/Exceptions/supabase_exception_handler.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClientsProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allClients = [];
  List<Map<String, dynamic>> _filteredClients = [];
  String _searchQuery = '';
  String activeFilter = 'all';
  bool _isLoading = true;
  final Map<String, bool> _overdueStatus = {};
  String? errorMessage;

  final Map<String, bool> _overdueStatusMap = {};

  // Add this getter
  bool isOverdue(String membershipNo) {
    return _overdueStatusMap[membershipNo] ?? false;
  }

  List<Map<String, dynamic>> get filteredClients => _filteredClients;
  bool get isLoading => _isLoading;

  ClientsProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchClients();
    _applyFilters();
  }

  Future<void> _fetchClients() async {
    // debugPrint('Starting client fetch...');
    try {
      _isLoading = true;
      notifyListeners();

      // debugPrint('Querying Supabase...');
      final response = await _supabase
          .from('membership_forms')
          .select()
          .order('form_no', ascending: true);

      // debugPrint('Received ${response.length} clients');
      _allClients = List<Map<String, dynamic>>.from(response);

      // debugPrint('Checking overdue status...');
      final membershipNos =
          _allClients.map((c) => c['membership_no'].toString()).toList();
      final overdueStatus = await _batchCheckOverdue(membershipNos);

      for (int i = 0; i < _allClients.length; i++) {
        _allClients[i]['_isOverdue'] = overdueStatus[i];
      }
      // After fetching clients, check their overdue status
      for (final client in _allClients) {
        final membershipNo = client['membership_no'].toString();
        _overdueStatusMap[membershipNo] = await hasOverdueInstallments(
          membershipNo,
        );
      }

      // debugPrint('Client data processed successfully');
    } catch (e) {
      // debugPrint('Error in _fetchClients: $e');
      errorMessage = 'Error loading data';
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      // debugPrint('Fetch completed. Loading: $_isLoading');
    }
  }

  Future<List<bool>> _batchCheckOverdue(List<String> membershipNos) async {
    // Implement batch checking logic
    // Could use Supabase RPC for better performance
    return await Future.wait(
      membershipNos.map((no) => hasOverdueInstallments(no)),
    );
  }

  Future<bool> hasOverdueInstallments(String membershipNo) async {
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final currentDay = now.day;

      // 1. Get all client data in a single query
      final clientData =
          await supabase
              .from('membership_forms')
              .select('''
          name,
          date, 
          payment_plan,
          cost_of_land,
          additional_charges,
          downpayment,
          monthly_installment,
          halfYear_Installment,
          suspended,
          winned,
          refunded,
          installment_receipts!inner(
            date, 
            received_amount,
            installment_no
          )
        ''')
              .eq('membership_no', membershipNo)
              .single();

      final clientName = clientData['name'] as String? ?? 'Unknown';
      final bookingDate = DateTime.parse(clientData['date'] as String);
      final paymentPlan =
          clientData['payment_plan'] as String? ?? 'Simple Plan';
      final receipts = clientData['installment_receipts'] as List;

      // Skip check for special status clients
      if (clientData['suspended'] == true ||
          clientData['winned'] == true ||
          clientData['refunded'] == true) {
        // debugPrint('$clientName ($membershipNo): Skipped - Special status');
        return false;
      }

      // 2. Calculate total amount paid and total cost
      double totalPaid = receipts.fold(0.0, (sum, receipt) {
        return sum +
            (double.tryParse(receipt['received_amount']?.toString() ?? '0') ??
                0);
      });

      final totalCost =
          (double.tryParse(clientData['cost_of_land']?.toString() ?? '0') ??
              0 +
                  (double.tryParse(
                        clientData['additional_charges']?.toString() ?? '0',
                      ) ??
                      0));

      // 3. If client has paid full amount, never overdue
      if (totalPaid >= totalCost) {
        // debugPrint('$clientName ($membershipNo): Fully paid - Not overdue');
        return false;
      }

      // 4. For Cash plan - only check full payment
      if (paymentPlan == 'Cash') {
        return false;
      }

      // 5. Calculate months since booking (adjusted for booking after 20th)
      int monthsSinceBooking =
          (now.year - bookingDate.year) * 12 + now.month - bookingDate.month;
      if (bookingDate.day > 20) {
        monthsSinceBooking = max(0, monthsSinceBooking - 1);
      }

      // 6. Only check overdue after the 10th of the month
      if (currentDay <= 10) {
        // debugPrint('$clientName ($membershipNo): Before 10th - Not overdue');
        return false;
      }

      // 7. Calculate expected payment schedule
      double expectedPayment = 0;
      final downpayment =
          double.tryParse(clientData['downpayment']?.toString() ?? '0') ?? 0;
      final monthlyInstallment =
          double.tryParse(
            clientData['monthly_installment']?.toString() ?? '0',
          ) ??
          0;
      final hyInstallment =
          double.tryParse(
            clientData['halfYear_Installment']?.toString() ?? '0',
          ) ??
          0;

      // Add downpayment
      expectedPayment += downpayment;

      // Add installments
      if (monthsSinceBooking > 0) {
        if (paymentPlan == 'Simple Plan') {
          expectedPayment += min(monthsSinceBooking, 35) * monthlyInstallment;
        } else if (paymentPlan == 'H.Y Installment Plan') {
          int hyCount = min(monthsSinceBooking ~/ 6, 5);
          int monthlyCount = monthsSinceBooking - (hyCount * 6);
          expectedPayment +=
              (hyCount * hyInstallment) + (monthlyCount * monthlyInstallment);
        }
      }

      // 8. Final overdue decision
      final isOverdue = totalPaid < expectedPayment;

      // Detailed debug output
      //       debugPrint('''
      // $clientName ($membershipNo) Payment Analysis:
      // ----------------------------------------
      // Booking Date:    ${bookingDate.toString()}
      // Payment Plan:    $paymentPlan
      // Months Since:    $monthsSinceBooking
      // Current Date:    ${now.toString()}
      // Total Cost:      $totalCost
      // Total Paid:      $totalPaid
      // Downpayment:     $downpayment
      // Monthly Install: $monthlyInstallment
      // HY Install:      $hyInstallment
      // Expected Paid:   $expectedPayment
      // Overdue:         $isOverdue
      // Receipts:
      // ${receipts.map((r) => '  - ${r['date']}: ${r['received_amount']}').join('\n')}
      // ----------------------------------------
      // ''');

      return isOverdue;
    } catch (e) {
      // debugPrint('Error checking overdue for $membershipNo: $e');
      return false;
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void updateFilter(String filter) {
    activeFilter = filter;
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result =
        _allClients.where((client) {
          final matchesSearch = _matchesSearchCriteria(client);
          final matchesFilter = _matchesFilterCriteria(client);
          return matchesSearch && matchesFilter;
        }).toList();

    _filteredClients = result;
    notifyListeners();
  }

  bool _matchesSearchCriteria(Map<String, dynamic> client) {
    if (_searchQuery.isEmpty) return true;
    return client['form_no'].toString().contains(_searchQuery) ||
        client['name'].toString().toLowerCase().contains(_searchQuery);
  }

  bool _matchesFilterCriteria(Map<String, dynamic> client) {
    switch (activeFilter) {
      case 'winned':
        return client['winned'] == true;
      case 'suspended':
        return client['suspended'] == true;
      default:
        return true;
    }
  }

  void refreshData() {
    _isLoading = true;
    notifyListeners();
    _initializeData();
  }

  // Update client status for winner or suspended
  Future<void> updateClientStatus(
    String membershipNo,
    String status, {
    String? plotNo,
    String? specialCategory,
    double additionalCharges = 0,
    String? statusRemarks, // Add this new parameter
  }) async {
    try {
      final updateData = <String, dynamic>{};

      // Add status remarks to update data
      if (statusRemarks != null && statusRemarks.isNotEmpty) {
        updateData['status_remarks'] = statusRemarks;
      }

      switch (status) {
        case 'Mark Suspended':
          updateData['suspended'] = true;
          updateData['winned'] = false;
          break;

        case 'Mark Fileclosed':
          updateData['winned'] = true;
          updateData['suspended'] = false;
          if (plotNo != null && plotNo.isNotEmpty) {
            updateData['plot_no'] = plotNo;
          }
          if (specialCategory != null) {
            updateData['special_category'] = specialCategory;
          }
          updateData['additional_charges'] = additionalCharges;
          break;

        case 'Mark Normal (Suspended)':
          updateData['suspended'] = false;
          break;

        case 'Mark Normal (Fileclosed)':
          updateData['winned'] = false;
          updateData['plot_no'] = null;
          updateData['special_category'] = null;
          updateData['additional_charges'] = null;
          break;
      }

      await _supabase
          .from('membership_forms')
          .update(updateData)
          .eq('membership_no', membershipNo);

      // Update local state
      final index = _allClients.indexWhere(
        (c) => c['membership_no'] == membershipNo,
      );

      if (index != -1) {
        _allClients[index] = {
          ..._allClients[index],
          ...updateData,
          // Handle potential null values
          'plot_no': updateData['plot_no'] ?? _allClients[index]['plot_no'],
          'special_category':
              updateData['special_category'] ??
              _allClients[index]['special_category'],
          'additional_charges':
              updateData['additional_charges'] ??
              _allClients[index]['additional_charges'],
          'status_remarks':
              updateData['status_remarks'] ??
              _allClients[index]['status_remarks'],
        };
        _applyFilters();
      }
    } catch (e) {
      throw Exception('Failed to update. Error: ${e.toString()}');
    }
  }
}
