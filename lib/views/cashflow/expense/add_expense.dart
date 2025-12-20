import 'dart:io';
import 'dart:math';

import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  String description = '';
  double amount = 0.0;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  bool showDealerRebateFields = false;
  bool showTargetedBonusFields = false;

  String? errorMessage;
  bool isManagingCategories = false;
  String newCategoryName = '';
  IconData selectedIcon = Icons.category;
  Color selectedColor = Colors.grey;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dealerNoController = TextEditingController();
  final TextEditingController _membershipNoController = TextEditingController();
  final TextEditingController _categoryNameController = TextEditingController();
  final TextEditingController _remarksController =
      TextEditingController(); // NEW: Remarks controller

  List<ExpenseCategory> categories = [];
  List<ExpenseCategory> defaultCategories = [
    ExpenseCategory(
      name: 'Fuel Expense',
      icon: Icons.local_gas_station,
      color: Colors.orange,
    ),
    ExpenseCategory(name: 'Food', icon: Icons.fastfood, color: Colors.green),
    ExpenseCategory(
      name: 'Land Payments',
      icon: Icons.landscape,
      color: Colors.brown,
    ),
    ExpenseCategory(name: 'Stationary', icon: Icons.edit, color: Colors.blue),
    ExpenseCategory(
      name: 'Advertisement',
      icon: Icons.ads_click,
      color: Colors.purple,
    ),
    ExpenseCategory(
      name: 'Targeted Bonus', // Make sure this is uncommented
      icon: Icons.star,
      color: Colors.amber,
    ),
    ExpenseCategory(
      name: 'Dealer Rebate',
      icon: Icons.money_off,
      color: Colors.red,
    ),
    ExpenseCategory(
      name: 'Staff Rebate',
      icon: Icons.people,
      color: Colors.teal,
    ),
    ExpenseCategory(name: 'Others', icon: Icons.category, color: Colors.grey),
  ];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await _supabase.from('expense_categories').select('*');

      if (response != null && response.isNotEmpty) {
        setState(() {
          categories =
              (response as List)
                  .map(
                    (category) => ExpenseCategory(
                      name: category['name'],
                      icon: _getIconFromString(category['icon']),
                      color: _getColorFromString(category['color']),
                    ),
                  )
                  .toList();
        });
      } else {
        // If no categories in DB, use defaults and insert them
        setState(() {
          categories = List.from(defaultCategories);
        });
        await _insertDefaultCategories();
      }
    } catch (e) {
      setState(() {
        categories = List.from(defaultCategories);
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'fastfood':
        return Icons.fastfood;
      case 'landscape':
        return Icons.landscape;
      case 'edit':
        return Icons.edit;
      case 'ads_click':
        return Icons.ads_click;
      case 'money_off':
        return Icons.money_off;
      case 'people':
        return Icons.people;
      case 'star': // NEW: Add star icon for Targeted Bonus
        return Icons.star;
      default:
        return Icons.category;
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName) {
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      case 'brown':
        return Colors.brown;
      case 'blue':
        return Colors.blue;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      case 'amber': // NEW: Add amber color for Targeted Bonus
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  Future<void> _insertDefaultCategories() async {
    try {
      for (var category in defaultCategories) {
        await _supabase.from('expense_categories').insert({
          'name': category.name,
          'icon': _getIconString(category.icon),
          'color': _getColorString(category.color),
        });
      }
    } catch (e) {
      print('Error inserting default categories: $e');
    }
  }

  String _getIconString(IconData icon) {
    switch (icon) {
      case Icons.local_gas_station:
        return 'local_gas_station';
      case Icons.fastfood:
        return 'fastfood';
      case Icons.landscape:
        return 'landscape';
      case Icons.edit:
        return 'edit';
      case Icons.ads_click:
        return 'ads_click';
      case Icons.money_off:
        return 'money_off';
      case Icons.people:
        return 'people';
      case Icons.star: // NEW: Add star icon string
        return 'star';
      default:
        return 'category';
    }
  }

  String _getColorString(Color color) {
    if (color == Colors.orange) return 'orange';
    if (color == Colors.green) return 'green';
    if (color == Colors.brown) return 'brown';
    if (color == Colors.blue) return 'blue';
    if (color == Colors.purple) return 'purple';
    if (color == Colors.red) return 'red';
    if (color == Colors.teal) return 'teal';
    if (color == Colors.amber) return 'amber'; // NEW: Add amber color
    return 'grey';
  }

  Future<void> _addNewCategory() async {
    if (newCategoryName.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a category name')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Check if category already exists
      final existing =
          await _supabase
              .from('expense_categories')
              .select('name')
              .eq('name', newCategoryName)
              .maybeSingle();

      if (existing != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Category already exists')));
        return;
      }

      // Insert new category
      await _supabase.from('expense_categories').insert({
        'name': newCategoryName,
        'icon': _getIconString(selectedIcon),
        'color': _getColorString(selectedColor),
      });

      // Reload categories
      await _loadCategories();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category added successfully')));

      setState(() {
        newCategoryName = '';
        isManagingCategories = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding category: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _deleteCategory(String categoryName) async {
    setState(() {
      isLoading = true;
    });

    try {
      // Check if category is used in any expenses
      final expenses = await _supabase
          .from('expenses')
          .select('id')
          .eq('category', categoryName);

      if (expenses.isNotEmpty && expenses.length > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot delete category - it is used in existing expenses',
            ),
          ),
        );
        return;
      }

      // Delete category
      await _supabase
          .from('expense_categories')
          .delete()
          .eq('name', categoryName);

      // Reload categories
      await _loadCategories();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Category deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting category: $e')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveExpense() async {
    // First check internet connection
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isEmpty || result[0].rawAddress.isEmpty) {
        SupabaseExceptionHandler.showErrorSnackbar(
          context,
          'No Internet Connection',
        );

        return;
      }
    } on SocketException catch (_) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'No Internet Connection',
      );
      return;
    }

    // Rest of your existing save logic
    String generateCustomId() {
      final now = DateTime.now();
      final milliseconds = now.millisecondsSinceEpoch;
      final paddedId = milliseconds.toString().substring(7, 13);
      return paddedId.padLeft(6, '0');
    }

    Future<bool> isIdUnique(String id) async {
      final result =
          await _supabase
              .from('expenses')
              .select('id')
              .eq('id', id)
              .maybeSingle();
      return result == null;
    }

    String customId = generateCustomId();
    bool isUnique = await isIdUnique(customId);

    if (!isUnique) {
      final random = Random();
      customId = '${customId.substring(0, 5)}${random.nextInt(10)}';
      isUnique = await isIdUnique(customId);
    }

    if (!isUnique) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to generate unique ID. Try again.'),
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      if (categoryProvider.selectedCategory == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Please select a category')));
        return;
      }

      int? rebateSlot;
      if (categoryProvider.selectedCategory?.name == 'Dealer Rebate') {
        if (_dealerNoController.text.isEmpty ||
            _membershipNoController.text.isEmpty) {
          setState(() {
            errorMessage =
                "Dealer Number and Membership Number are required for Dealer Rebate.";
          });
          return;
        }

        final updateResult = await _validateAndUpdateRebate(
          _dealerNoController.text.toString().toLowerCase(),
          _membershipNoController.text.toString().toLowerCase(),
          amount,
        );

        if (updateResult is String) {
          setState(() {
            errorMessage = updateResult;
          });
          return;
        } else if (updateResult is int) {
          rebateSlot = updateResult;
        }
      }

      // NEW: Check for Targeted Bonus category - dealer number is required
      if (categoryProvider.selectedCategory?.name == 'Targeted Bonus') {
        if (_dealerNoController.text.isEmpty) {
          setState(() {
            errorMessage = "Dealer Number is required for Targeted Bonus.";
          });
          return;
        }
      }

      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      try {
        // Create base expense data
        final expenseData = {
          'id': customId,
          'description': description,
          'amount': amount,
          'date': selectedDate.toIso8601String(),
          'category': categoryProvider.selectedCategory!.name,
        };

        // NEW: Add remarks for Targeted Bonus (optional)
        if (categoryProvider.selectedCategory?.name == 'Targeted Bonus') {
          // Add remarks if provided
          if (_remarksController.text.isNotEmpty) {
            expenseData['remarks'] = _remarksController.text;
          }
          // Add dealer number for Targeted Bonus
          expenseData['dl_no'] =
              _dealerNoController.text.toString().toLowerCase();
        }
        // Add dealer and membership info for Dealer Rebate
        else if (categoryProvider.selectedCategory?.name == 'Dealer Rebate') {
          expenseData['dl_no'] =
              _dealerNoController.text.toString().toLowerCase();
          expenseData['membership_no'] =
              _membershipNoController.text.toString().toLowerCase();

          if (rebateSlot != null) {
            expenseData['rebate_slot'] = rebateSlot;
          }
        }

        await _supabase.from('expenses').insert([expenseData]);

        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Expense added successfully with ID: $customId',
        );
        Navigator.pop(context);
      } catch (e) {
        final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
        SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<dynamic> _validateAndUpdateRebate(
    String dealerNo,
    String membershipNo,
    double amount,
  ) async {
    try {
      final response =
          await _supabase
              .from('membership_forms')
              .select('rebate1, rebate2, rebate3, rebate4, rebate5')
              .eq('dl_no', dealerNo)
              .eq('membership_no', membershipNo)
              .maybeSingle();

      if (response == null) {
        return "Reference not found. Dealer Number and Membership Number do not match in the database.";
      }

      double rebate1 =
          double.tryParse(response['rebate1']?.toString() ?? '0') ?? 0;
      double rebate2 =
          double.tryParse(response['rebate2']?.toString() ?? '0') ?? 0;
      double rebate3 =
          double.tryParse(response['rebate3']?.toString() ?? '0') ?? 0;
      double rebate4 =
          double.tryParse(response['rebate4']?.toString() ?? '0') ?? 0;
      double rebate5 =
          double.tryParse(response['rebate5']?.toString() ?? '0') ?? 0;

      int? slot;
      String? rebateFieldToUpdate;

      if (rebate1 == 0) {
        rebateFieldToUpdate = 'rebate1';
        slot = 1;
      } else if (rebate2 == 0) {
        rebateFieldToUpdate = 'rebate2';
        slot = 2;
      } else if (rebate3 == 0) {
        rebateFieldToUpdate = 'rebate3';
        slot = 3;
      } else if (rebate4 == 0) {
        rebateFieldToUpdate = 'rebate4';
        slot = 4;
      } else if (rebate5 == 0) {
        rebateFieldToUpdate = 'rebate5';
        slot = 5;
      } else {
        return "Rebate already fully distributed.";
      }

      final rebateDateField = '${rebateFieldToUpdate}date';

      await _supabase
          .from('membership_forms')
          .update({
            rebateFieldToUpdate: amount.toString(),
            rebateDateField: selectedDate.toIso8601String(),
          })
          .eq('dl_no', dealerNo)
          .eq('membership_no', membershipNo);

      return slot;
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(
        "Error validating/updating rebate: $e",
      );
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
      return null;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _dealerNoController.dispose();
    _membershipNoController.dispose();
    _categoryNameController.dispose();
    _remarksController.dispose(); // NEW: Dispose remarks controller

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        backgroundColor: AppColors.darkbrown,
        actions: [
          IconButton(
            tooltip: 'Categories',
            icon: Icon(isManagingCategories ? Icons.close : Icons.category),
            onPressed: () {
              setState(() {
                isManagingCategories = !isManagingCategories;
                if (!isManagingCategories) {
                  newCategoryName = '';
                }
              });
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child:
              isManagingCategories
                  ? _buildCategoryManagementUI()
                  : ListView(
                    children: [
                      Text(
                        'Expense Details',
                        style: GoogleFonts.aBeeZee(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Category Section
                      Text(
                        'Select Category',
                        style: GoogleFonts.aBeeZee(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          return Consumer<CategoryProvider>(
                            builder: (context, categoryProvider, child) {
                              return GestureDetector(
                                onTap: () {
                                  categoryProvider.setSelectedCategory(
                                    category,
                                  );
                                  setState(() {
                                    showDealerRebateFields =
                                        category.name == 'Dealer Rebate';
                                    showTargetedBonusFields =
                                        category.name == 'Targeted Bonus';
                                    // Clear remarks when switching away from Targeted Bonus
                                    if (category.name != 'Targeted Bonus') {
                                      _remarksController.clear();
                                    }
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color:
                                        categoryProvider.selectedCategory ==
                                                category
                                            ? category.color.withOpacity(0.3)
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          categoryProvider.selectedCategory ==
                                                  category
                                              ? category.color
                                              : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        category.icon,
                                        color: category.color,
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        category.name,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.aBeeZee(
                                          fontSize: 12.sp,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Conditional Fields for Dealer Rebate
                      if (showDealerRebateFields) ...[
                        TextFormField(
                          controller: _dealerNoController,
                          decoration: InputDecoration(
                            labelText: 'Dealer Number',
                            hintText: 'Enter dealer number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter valid reference';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                        TextFormField(
                          controller: _membershipNoController,
                          decoration: InputDecoration(
                            labelText: 'Membership Number',
                            hintText: 'Enter membership number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a valid membership number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),
                      ],

                      // Conditional Field for Targeted Bonus (dealer number + remarks)
                      if (showTargetedBonusFields) ...[
                        TextFormField(
                          controller: _dealerNoController,
                          decoration: InputDecoration(
                            labelText: 'Dealer Number *',
                            hintText: 'Enter dealer number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter dealer number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 10),

                        // NEW: Remarks field for Targeted Bonus (optional)
                        TextFormField(
                          controller: _remarksController,
                          decoration: InputDecoration(
                            labelText: 'Remarks (Optional)',
                            hintText: 'Enter any remarks for this bonus',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          maxLines: 2,
                          minLines: 1,
                        ),
                        SizedBox(height: 10),
                      ],

                      // Show Error Message
                      if (errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),

                      // Description Input
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter expense description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            description = value;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Amount Input
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'Enter expense amount',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an amount';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          setState(() {
                            amount = double.tryParse(value) ?? 0.0;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date Picker
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Expense Date: ${selectedDate.toLocal()}'.split(
                              ' ',
                            )[0],
                            style: GoogleFonts.aBeeZee(fontSize: 14.sp),
                          ),
                          IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () => _selectDate(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Save Button or Loading Indicator
                      isLoading
                          ? Center(child: ProviderLoadingWidget())
                          : Center(
                            child: ElevatedButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                  AppColors.darkbrown,
                                ),
                              ),
                              onPressed: _saveExpense,
                              child: Text(
                                'Save',
                                style: TextStyle(color: AppColors.whitecolor),
                              ),
                            ),
                          ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildCategoryManagementUI() {
    return Column(
      children: [
        Text(
          'Manage Categories',
          style: GoogleFonts.aBeeZee(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 20),

        // Add new category section
        TextFormField(
          controller: _categoryNameController,
          decoration: InputDecoration(
            labelText: 'New Category Name',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => setState(() => newCategoryName = value),
        ),
        SizedBox(height: 10),

        // Icon selection
        Text('Select Icon:', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8,
          children: [
            _buildIconOption(Icons.local_gas_station),
            _buildIconOption(Icons.fastfood),
            _buildIconOption(Icons.landscape),
            _buildIconOption(Icons.edit),
            _buildIconOption(Icons.ads_click),
            _buildIconOption(Icons.money_off),
            _buildIconOption(Icons.people),
            _buildIconOption(Icons.category),
            _buildIconOption(Icons.trending_up),
            _buildIconOption(Icons.receipt),
            _buildIconOption(Icons.subscriptions),
            _buildIconOption(Icons.handyman),
            _buildIconOption(Icons.coffee),
            _buildIconOption(Icons.star), // NEW: Add star icon option
          ],
        ),
        SizedBox(height: 10),

        // Color selection
        Text('Select Color:', style: TextStyle(fontSize: 16)),
        Wrap(
          spacing: 8,
          children: [
            _buildColorOption(Colors.orange),
            _buildColorOption(Colors.green),
            _buildColorOption(Colors.brown),
            _buildColorOption(Colors.blue),
            _buildColorOption(Colors.purple),
            _buildColorOption(Colors.red),
            _buildColorOption(Colors.teal),
            _buildColorOption(Colors.grey),
            _buildColorOption(Colors.amber), // NEW: Add amber color option
          ],
        ),
        SizedBox(height: 20),

        ElevatedButton(onPressed: _addNewCategory, child: Text('Add Category')),
        SizedBox(height: 20),

        // List of existing categories
        Expanded(
          child: ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return ListTile(
                leading: Icon(category.icon, color: category.color),
                title: Text(category.name),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteCategory(category.name),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIconOption(IconData icon) {
    return GestureDetector(
      onTap: () => setState(() => selectedIcon = icon),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selectedIcon == icon ? Colors.blue.withOpacity(0.3) : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () => setState(() => selectedColor = color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border:
              selectedColor == color
                  ? Border.all(width: 3, color: Colors.black)
                  : null,
        ),
      ),
    );
  }
}

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

class CategoryProvider extends ChangeNotifier {
  ExpenseCategory? _selectedCategory;

  ExpenseCategory? get selectedCategory => _selectedCategory;

  void setSelectedCategory(ExpenseCategory category) {
    _selectedCategory = category;
    notifyListeners();
  }
}
