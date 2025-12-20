import 'package:aps/config/providers/clients_refund_provider.dart';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RefundDialog extends StatefulWidget {
  final String membershipNo;
  final ClientsRefundProvider provider;

  const RefundDialog({
    super.key,
    required this.membershipNo,
    required this.provider,
  });

  @override
  State<RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends State<RefundDialog> {
  String? _selectedReason;
  double _totalPaid = 0.0;
  double _refundAmount = 0.0;
  int _installments = 1;
  int _periodMonths = 1;
  bool _isLoading = true;

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController(text: '1');
  final _periodController = TextEditingController(text: '1');

  @override
  void initState() {
    super.initState();
    _loadReceipts();
    _installmentsController.addListener(_updateInstallments);
    _periodController.addListener(_updatePeriod);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    final receipts = await widget.provider.fetchPaidReceipts(
      widget.membershipNo,
    );

    if (mounted) {
      setState(() {
        _totalPaid = receipts.fold(0.0, (sum, receipt) {
          final amount = receipt['received_amount'];
          final parsedAmount =
              (amount is num)
                  ? amount.toDouble()
                  : (amount is String)
                  ? double.tryParse(amount) ?? 0.0
                  : 0.0;
          return sum + parsedAmount;
        });
        _isLoading = false;
      });
    }
  }

  void _updateInstallments() {
    setState(() {
      _installments = int.tryParse(_installmentsController.text) ?? 1;
    });
  }

  void _updatePeriod() {
    setState(() {
      _periodMonths = int.tryParse(_periodController.text) ?? 1;
    });
  }

  Future<void> _submitRefund() async {
    if (_formKey.currentState!.validate()) {
      try {
        await widget.provider.processRefund(
          membershipNo: widget.membershipNo,
          reason: _selectedReason!,
          totalPaid: _totalPaid,
          refundAmount: _refundAmount,
          installments: _installments,
          periodMonths: _periodMonths,
        );

        if (mounted) {
          SupabaseExceptionHandler.showSuccessSnackbar(
            context,
            'Refund processed successfully!',
          );
          Navigator.pop(context); // Close dialog on success
        }
      } catch (e) {
        if (mounted) {
          final error = SupabaseExceptionHandler.handleSupabaseError(e);
          SupabaseExceptionHandler.showErrorSnackbar(context, error);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Process Refund'),
      content:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: _selectedReason,
                        decoration: const InputDecoration(
                          labelText: 'Reason for Refund',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'accidental',
                            child: Text('Accidental Payment'),
                          ),
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text('Normal Refund'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedReason = value;
                          });
                        },
                        validator: (value) {
                          if (value == null) return 'Please select a reason';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text('Total Paid:'),
                          const Spacer(),
                          Text(
                            NumberFormat.currency(
                              symbol: '',
                            ).format(_totalPaid),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Refund Amount',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter amount';
                          }
                          final amount = double.tryParse(value) ?? 0;
                          if (amount <= 0) return 'Amount must be positive';
                          if (amount > _totalPaid) {
                            return 'Cannot exceed total paid';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            _refundAmount = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _installmentsController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Installments',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter installments';
                          }
                          final installments = int.tryParse(value) ?? 0;
                          if (installments <= 0) return 'Must be at least 1';
                          if (installments > 12)
                            return 'Maximum 12 installments';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _periodController,
                        decoration: const InputDecoration(
                          labelText: 'Refund Period (Months)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter period';
                          }
                          final months = int.tryParse(value) ?? 0;
                          if (months <= 0) return 'Must be at least 1 month';
                          if (months > 24) return 'Maximum 24 months';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitRefund,
          child: const Text('Confirm Refund'),
        ),
      ],
    );
  }
}
