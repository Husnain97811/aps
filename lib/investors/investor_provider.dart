import 'package:aps/config/view.dart';
import 'package:aps/investors/edit_investor_dialog.dart';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class InvestorProvider with ChangeNotifier {
  final Uuid _uuid = Uuid(); // Add this
  bool _hasError = false;
  final SupabaseClient _supabase;
  List<Investor> _investors = [];
  bool _isLoading = false;
  // final AdminAuthService _adminAuthService = AdminAuthService(); // Add this
  late LoadingProvider loadingProvider;

  List<Investor> get investors => _investors;
  InvestorProvider(this._supabase);

  void initialize(BuildContext context) {
    loadingProvider = Provider.of<LoadingProvider>(context, listen: false);
  }

  bool get hasError => _hasError;

  Future<void> getInvestorsWithSchedules(BuildContext context) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );

    try {
      loadingProvider.startLoading();
      final response = await _supabase
          .from('investors')
          .select()
          .order('created_at', ascending: false);

      _investors =
          (response as List).map((json) => Investor.fromJson(json)).toList();
      _hasError = false;
    } catch (e) {
      _hasError = true;
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        SupabaseExceptionHandler.handleSupabaseError(e),
      );
    } finally {
      loadingProvider.stopLoading();
      notifyListeners();
    }
  }

  Future<void> addInvestorWithSchedules(
    Investor investor,
    List<ProfitSchedule> schedules,
  ) async {
    try {
      await _supabase.rpc(
        'add_investor_with_schedules',
        params: {
          'p_name': investor.name,
          'p_investor_id_code': investor.investorIdCode,
          'p_email': investor.email,
          'p_phone': investor.phone,
          'p_cnic': investor.cnic,
          'p_address': investor.address,
          'p_initial_investment': investor.initialInvestmentAmount,
          'p_investment_date': DateFormat(
            'yyyy-MM-dd',
          ).format(investor.investmentDate),
          'p_schedules':
              schedules
                  .map(
                    (s) => ({
                      // 'effective_after_months': s.effectiveAfterMonths,
                      'calculation_type': s.calculationType,
                      'value': s.value,
                      'profit_duration': s.profitDuration,
                    }),
                  )
                  .toList(),
        },
      );

      await getInvestorsWithSchedules(context as BuildContext);
    } catch (e) {
      print('Error adding investor: $e');
      rethrow;
    }
  }

  Investor? searchInvestor(String query) {
    final cleanQuery = query.trim().toLowerCase();
    try {
      return _investors.firstWhere(
        (investor) =>
            investor.cnic.toLowerCase() == cleanQuery ||
            investor.investorIdCode.toLowerCase() == cleanQuery,
      );
    } catch (e) {
      return null;
    }
  }

  Future<void> processPayment({
    required BuildContext context,
    required String investorId,
    required double amount,
    required int installmentNumber,
  }) async {
    try {
      final investor = _investors.firstWhere((i) => i.id == investorId);
      final updatedPaid = Map<String, bool>.from(investor.paidInstallments);
      updatedPaid['m$installmentNumber'] = true;

      await _supabase
          .from('investors')
          .update({
            'paid_installments': updatedPaid,
            'unpaid_profit_balance': investor.unpaidProfitBalance - amount,
            'return_amount': investor.returnAmount + amount,
          })
          .eq('id', investorId);

      await _refreshInvestors();
      notifyListeners();
    } catch (e) {
      throw Exception('Payment failed: $e');
    }
  }

  Future<void> processReturn({
    required String investorId,
    required double amount,
  }) async {
    try {
      final user = _supabase.auth.currentUser;

      // 1. Create transaction record
      await _supabase.from('return_transactions').insert({
        'investor_id': investorId,
        'amount': amount,
        'processed_by': user?.id,
        'return_date': DateTime.now().toIso8601String(),
      });

      // 2. Call PostgreSQL function with correct parameter names
      await _supabase.rpc(
        'process_investor_return',
        params: {'p_investor_id': investorId, 'p_amount': amount},
      );

      // 3. Refresh data
      await _refreshInvestors();
      notifyListeners();
    } catch (e) {
      print('Return error: $e');
      throw Exception('Return failed: ${e.toString()}');
    }
  }

  Future<void> _refreshInvestors() async {
    try {
      final response = await _supabase
          .from('investors')
          .select('*') // Remove the trailing comma
          .order('created_at', ascending: false);

      _investors =
          (response as List).map((json) => Investor.fromJson(json)).toList();
    } catch (e) {
      print('Refresh error: $e');
    }
  }

  Future<void> addInvestor(Investor investor, BuildContext context) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    try {
      loadingProvider.startLoading();

      // Insert investor
      // / Debug: Print investor details
      print('Adding investor: ${investor.toJson()}');

      await _supabase.from('investors').insert(investor.toJson()).select('*');

      await getInvestorsWithSchedules(context);

      await getInvestorsWithSchedules(context);

      _investors.add(investor);
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Investor added successfully',
      );
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        SupabaseExceptionHandler.handleSupabaseError(e),
      );
      rethrow;
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Future<void> processPayout({
    required String investorId,
    required double amount,
    required String payoutType,
    String? notes,
  }) async {
    try {
      await _supabase.rpc(
        'process_investor_payout',
        params: {
          'p_investor_id': investorId,
          'p_amount': amount,
          'p_payout_type': payoutType,
          'p_notes': notes,
        },
      );

      await getInvestorsWithSchedules(context as BuildContext);
    } catch (e) {
      print('Error processing payout: $e');
      rethrow;
    }
  }

  Future<void> updateStatus({
    required Investor investor,
    required String newStatus,
    DateTime? expireDate,
  }) async {
    try {
      final updates = {
        'status': newStatus,
        'expire_date': expireDate?.toIso8601String(),
      };

      // Use proper update syntax with error handling
      await _supabase.from('investors').update(updates).eq('id', investor.id);

      // If we reach here, the update was successful
      final index = _investors.indexWhere((i) => i.id == investor.id);
      if (index != -1) {
        _investors[index] = investor.copyWith(
          status: newStatus,
          expireDate: expireDate,
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error updating investor status: $e');
      rethrow;
    }
  }

  Future<void> updateInvestor(Investor investor) async {
    try {
      final response = await _supabase
          .from('investors')
          .update(investor.toJson())
          .eq('id', investor.id);

      if (response.error == null) {
        final index = _investors.indexWhere((i) => i.id == investor.id);
        if (index != -1) {
          _investors[index] = investor;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating investor: $e');
    }
  }

  Future<void> deleteWithVerification({
    required String investorId,
    required BuildContext context,
    required String deletedBy,
  }) async {
    // Verify admin again for security
    final verified = await verifyAdmin(context);
    if (!verified) return;

    try {
      await _supabase.from('investors').delete().eq('id', investorId);
      // Add any additional cleanup or related deletions here
      // You might want to update audit trail with deletedBy information
    } catch (e) {
      throw Exception('Delete failed: $e');
    }
  }

  // Add similar methods for update/delete and schedule management

  Future<void> updateCustomer(Investor investor) async {
    try {
      final response = await _supabase
          .from('customers')
          .update({
            'name': investor.name,
            'cnic': investor.cnic,
            'phone': investor.phone,
            'email': investor.email,
            'address': investor.address,

            // Investment Details
            'initial_investment_amount': investor.initialInvestmentAmount,
            'investment_date': investor.investmentDate.toIso8601String(),

            // Profit Configuration
            // 'profit_calculation_type': investor.profitCalculationType,
            'profit_value': investor.profitValue,

            // Tracking Fields
            'edited_by': investor.editedBy,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', investor.id);

      if (response.error == null) {
        final index = _investors.indexWhere((c) => c.id == investor.id);
        if (index != -1) {
          _investors[index] = investor;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error updating customer: $e');
    }
  }

  // customer_provider.dart
  Future<void> editWithVerification({
    required Investor originalInvestor,
    required BuildContext context,
  }) async {
    try {
      if (!await verifyAdmin(context)) return;

      final updateData = {
        'name': originalInvestor.name,
        'cnic': originalInvestor.cnic,
        'phone': originalInvestor.phone,
        'email': originalInvestor.email,
        'address': originalInvestor.address,
        'initial_investment_amount': originalInvestor.initialInvestmentAmount,
        'profit_value': originalInvestor.profitValue,
        'investment_date': originalInvestor.investmentDate.toIso8601String(),
        'end_date': originalInvestor.endDate.toIso8601String(),
        'profit_duration': originalInvestor.profitDuration,
        'time_duration': originalInvestor.timeDuration,
        'total_installments': originalInvestor.totalInstallments,
        'paid_installments': originalInvestor.paidInstallments,
        'edited_by': originalInvestor.editedBy,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('investors')
          .update(updateData)
          .eq('id', originalInvestor.id);

      // Refresh the investor list
      await getInvestorsWithSchedules(context);
    } catch (e) {
      debugPrint('Error updating investor: $e');
      rethrow;
    }
  }

  Future<Investor?> _showEditDialog(
    BuildContext context,
    Investor investor,
  ) async {
    return await showDialog<Investor>(
      context: context,
      builder: (context) => EditInvestorDialog(investor: investor),
    );
  }

  Future<bool> _showAdminVerificationDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool isVerified = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Admin Verification Required'),

            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final isValid =
                        await AdminVerification.showVerificationDialog(
                          action: 'Edit investor',
                          context: context,
                        );
                    if (isValid & context.mounted) {
                      isVerified = true;
                      Navigator.pop(context);
                    } else {
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invalid admin password')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Verification error: ${e.toString()}'),
                      ),
                    );
                  }
                },
                child: const Text('Verify'),
              ),
            ],
          ),
    );

    return isVerified;
  }

  Future<bool> verifyAdmin(BuildContext context) async {
    try {
      return await _showAdminVerificationDialog(context);
    } catch (e) {
      return false;
    }
  }
}
