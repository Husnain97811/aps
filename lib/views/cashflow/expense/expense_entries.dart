import 'package:aps/config/components/widgets/loadin_widget.dart';
import 'package:aps/config/models/modify_expense_model.dart';
import 'package:aps/config/providers/expense_entries_provider.dart';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExpenseEntriesScreen extends StatefulWidget {
  const ExpenseEntriesScreen({super.key});

  @override
  State<ExpenseEntriesScreen> createState() => _ExpenseEntriesScreenState();
}

class _ExpenseEntriesScreenState extends State<ExpenseEntriesScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late Future<List<ModifyExpenseModel>> _expensesFuture;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _expensesFuture = _fetchAllExpenses();
    });
  }

  Future<List<ModifyExpenseModel>> _fetchAllExpenses() async {
    try {
      // Fetch regular expenses
      final regularExpenses = await _fetchRegularExpenses();

      // Fetch installment discounts
      final installmentDiscounts = await _fetchInstallmentDiscounts();

      // Combine and sort
      final allExpenses = [...regularExpenses, ...installmentDiscounts];
      allExpenses.sort((a, b) => b.date.compareTo(a.date));

      // Update provider
      if (mounted) {
        Provider.of<ExpenseProvider>(
          context,
          listen: false,
        ).setExpenses(allExpenses);
      }

      return allExpenses;
    } catch (e) {
      throw Exception('Failed to load expenses: $e');
    }
  }

  Future<List<ModifyExpenseModel>> _fetchRegularExpenses() async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .order('date', ascending: false);
      return List<ModifyExpenseModel>.from(
        response.map((e) => ModifyExpenseModel.fromJson(e)),
      );
    } catch (e) {
      print('Error fetching regular expenses: $e');
      return [];
    }
  }

  Future<List<ModifyExpenseModel>> _fetchInstallmentDiscounts() async {
    try {
      final response = await _supabase
          .from('installment_receipts')
          .select('''
            receipt_no,
            membership_no,
            name,
            date,
            discount,
            offer_discount_amount,
            installment_no
          ''')
          .or('discount.gt.0,offer_discount_amount.gt.0')
          .order('date', ascending: false);

      List<ModifyExpenseModel> discountExpenses = [];

      for (var item in response) {
        final receiptNo = item['receipt_no']?.toString() ?? '';
        final membershipNo = item['membership_no']?.toString() ?? '';
        final name = item['name']?.toString() ?? '';
        final installmentNo = item['installment_no']?.toString() ?? '';

        // Parse date
        DateTime date;
        try {
          date = DateTime.parse(item['date'].toString());
        } catch (e) {
          date = DateTime.now();
        }

        // Regular discount
        final regularDiscount =
            double.tryParse(item['discount'].toString()) ?? 0.0;
        if (regularDiscount > 0) {
          discountExpenses.add(
            ModifyExpenseModel(
              id: 'discount_${receiptNo}_regular',
              amount: regularDiscount,
              description:
                  'Regular Discount - Installment $installmentNo for $name',
              membership_no: membershipNo,
              sr_no: '',
              category: 'Installment Discount',
              date: date,
            ),
          );
        }

        // Offer discount
        final offerDiscount =
            double.tryParse(item['offer_discount_amount'].toString()) ?? 0.0;
        if (offerDiscount > 0) {
          discountExpenses.add(
            ModifyExpenseModel(
              id: 'discount_${receiptNo}_offer',
              amount: offerDiscount,
              description:
                  'Offer Discount - Installment $installmentNo for $name',
              membership_no: membershipNo,
              sr_no: '',
              category: 'Installment Discount',
              date: date,
            ),
          );
        }
      }

      return discountExpenses;
    } catch (e) {
      print('Error fetching installment discounts: $e');
      return [];
    }
  }

  Future<void> _deleteExpense(String id) async {
    // Don't allow deletion of discount expenses
    if (id.startsWith('discount_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discount expenses cannot be deleted from here.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final expense =
          await _supabase
              .from('expenses')
              .select('''
          category, 
          rebate_slot,
          dl_no, 
          membership_no
        ''')
              .eq('id', id)
              .maybeSingle();

      if (expense != null && expense['category'] == 'Dealer Rebate') {
        final rebateSlot = expense['rebate_slot'] as int?;
        final dealerNo = expense['dl_no'] as String?;
        final membershipNo = expense['membership_no'] as String?;

        if (rebateSlot != null &&
            dealerNo != null &&
            membershipNo != null &&
            rebateSlot >= 1 &&
            rebateSlot <= 3) {
          final rebateField = 'rebate$rebateSlot';
          final dateField = '${rebateField}date';

          await _supabase
              .from('membership_forms')
              .update({rebateField: 0, dateField: null})
              .eq('dl_no', dealerNo)
              .eq('membership_no', membershipNo);
        }
      }

      await _supabase.from('expenses').delete().eq('id', id);
      _refreshData();
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Expense deleted successfully',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting expense: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Entries'),
        backgroundColor: AppColors.darkbrown,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.rmncolor),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by description or Membership no...',
                  hintStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.search, color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white54),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  filled: true,
                  fillColor: Colors.blueGrey[800]!.withOpacity(0.5),
                ),
                style: const TextStyle(color: Colors.white),
                onChanged: (value) {
                  Provider.of<ExpenseProvider>(
                    context,
                    listen: false,
                  ).setSearchQuery(value);
                },
              ),
            ),
            Expanded(
              child: FutureBuilder<List<ModifyExpenseModel>>(
                future: _expensesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: ProviderLoadingWidget());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load expenses\n${snapshot.error}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return Consumer<ExpenseProvider>(
                    builder: (context, provider, child) {
                      final expenses = provider.filteredExpenses;

                      if (expenses.isEmpty && provider.searchQuery.isNotEmpty) {
                        return const Center(
                          child: Text(
                            'No matching expenses found',
                            style: TextStyle(color: Colors.white),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: expenses.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final expense = expenses[index];
                          final isDiscount = expense.id.startsWith('discount_');

                          return _ExpenseCard(
                            expense: expense,
                            isDiscount: isDiscount,
                            onDelete:
                                isDiscount
                                    ? null
                                    : () => _showDeleteDialog(expense.id),
                            onEdit:
                                isDiscount
                                    ? null
                                    : () => _showEditDialog(expense),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(ModifyExpenseModel expense) {
    // Don't allow editing discount expenses
    if (expense.id.startsWith('discount_')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Discount expenses cannot be edited.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController(
      text: expense.amount.toString(),
    );
    final descriptionController = TextEditingController(
      text: expense.description,
    );
    final categoryController = TextEditingController(text: expense.category);
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(expense.date),
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[900],
          title: const Text(
            'Edit Expense',
            style: TextStyle(color: Colors.white),
          ),
          content: SizedBox(
            width: Adaptive.w(50),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAmountField(amountController),
                  const SizedBox(height: 16),
                  _buildDescriptionField(descriptionController),
                  const SizedBox(height: 16),
                  _buildCategoryField(categoryController),
                  const SizedBox(height: 16),
                  _buildDateField(dateController, context),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  try {
                    await _supabase
                        .from('expenses')
                        .update({
                          'amount': double.parse(amountController.text),
                          'description': descriptionController.text,
                          'category': categoryController.text,
                          'date': dateController.text,
                        })
                        .eq('id', expense.id);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Expense updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context);
                    _refreshData();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating expense: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Amount',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _membershipField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Membership No.',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.attach_money, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter the amount';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Description',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.description, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a description';
        }
        return null;
      },
    );
  }

  Widget _buildCategoryField(TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Category',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.category, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a category';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(
    TextEditingController controller,
    BuildContext context,
  ) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Date',
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: const Icon(Icons.calendar_today, color: Colors.white70),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white54),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white),
        ),
      ),
      readOnly: true,
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: DateTime.parse(controller.text),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (picked != null) {
          controller.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a date';
        }
        return null;
      },
    );
  }

  void _showDeleteDialog(String id) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Delete'),
            content: const Text(
              'Are you sure you want to delete this expense?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteExpense(id);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  final ModifyExpenseModel expense;
  final bool isDiscount;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const _ExpenseCard({
    required this.expense,
    required this.isDiscount,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:
            isDiscount
                ? Colors.blueGrey[700]!.withOpacity(0.8)
                : Colors.blueGrey[800]!.withOpacity(0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDiscount ? Colors.orange.withOpacity(0.5) : Colors.white24,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(
          children: [
            Expanded(
              child: Text(
                expense.description,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isDiscount)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange),
                ),
                child: Text(
                  'Discount',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            (expense.sr_no != null && expense.sr_no.toString().isNotEmpty)
                ? _buildDetailRow(
                  'Sr No.',
                  expense.sr_no.toString().toUpperCase(),
                )
                : _buildDetailRow(
                  'Membership No.',
                  expense.membership_no.toString().toUpperCase(),
                ),
            _buildDetailRow(
              'Amount:',
              'Rs ${expense.amount.toStringAsFixed(2)}',
            ),
            _buildDetailRow('Category:', expense.category),
            _buildDetailRow(
              'Date:',
              DateFormat('dd MMM yyyy').format(expense.date),
            ),
          ],
        ),
        trailing:
            isDiscount
                ? Icon(
                  Icons.lock_outline,
                  color: Colors.orange.withOpacity(0.7),
                  size: 20,
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: AppColors.lightgolden),
                      onPressed: onEdit,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.redAccent),
                      onPressed: onDelete,
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
