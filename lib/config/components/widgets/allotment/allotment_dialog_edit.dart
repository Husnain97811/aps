import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../view.dart';

class EditAllotmentDialog extends StatefulWidget {
  final Map<String, dynamic> allotment;

  const EditAllotmentDialog({super.key, required this.allotment});

  @override
  _EditAllotmentDialogState createState() => _EditAllotmentDialogState();
}

class _EditAllotmentDialogState extends State<EditAllotmentDialog> {
  final supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _plotNoController;
  late TextEditingController _streetController;
  late TextEditingController _sizeController;
  late TextEditingController _specialCategoryController;

  @override
  void initState() {
    super.initState();
    _plotNoController = TextEditingController(
      text: widget.allotment['plot_no'],
    );
    _streetController = TextEditingController(text: widget.allotment['street']);
    _sizeController = TextEditingController(text: widget.allotment['size']);
    _specialCategoryController = TextEditingController(
      text: widget.allotment['special_category'],
    );
  }

  @override
  void dispose() {
    _plotNoController.dispose();
    _streetController.dispose();
    _sizeController.dispose();
    _specialCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Allotment Details'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _plotNoController,
                decoration: const InputDecoration(labelText: 'Plot No'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter plot number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Street'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter street';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _sizeController,
                decoration: const InputDecoration(labelText: 'Size'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter size';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _specialCategoryController,
                decoration: const InputDecoration(
                  labelText: 'Special Category',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter special category';
                  }
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
        TextButton(
          onPressed: () async {
            final userId = supabase.auth.currentUser!.id;
            final userName =
                await supabase
                    .from('profiles')
                    .select('full_name')
                    .eq('id', userId)
                    .maybeSingle();
            if (_formKey.currentState!.validate()) {
              final updatedDetails = {
                'plot_no': _plotNoController.text,
                'street': _streetController.text,
                'size': _sizeController.text,
                'special_category': _specialCategoryController.text,
                'updated_by': userName?['full_name'].toString(),
              };
              Navigator.pop(context, updatedDetails);
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

Future<void> _editAllotmentDetails(
  BuildContext context,
  Map<String, dynamic> member,
) async {
  final provider = context.read<AllotmentProvider>();
  final loadingProvider = context.read<LoadingProvider>();

  try {
    loadingProvider.startLoading(); // Start loading

    final allotment = await provider.getAllotmentDetails(
      member['membership_no'],
    );

    if (allotment == null) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Allotment not found',
      );
      return;
    }

    final updatedDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditAllotmentDialog(allotment: allotment),
    );

    if (updatedDetails != null) {
      // Ensure special_category is included in the updated details
      if (updatedDetails.containsKey('special_category')) {
        await provider.updateAllotment(member['membership_no'], updatedDetails);
        SupabaseExceptionHandler.showSuccessSnackbar(
          context,
          'Allotment updated successfully',
        );
      } else {
        SupabaseExceptionHandler.showErrorSnackbar(
          context,
          'Special category is required',
        );
      }
    }
  } catch (e) {
    final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
    SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
  } finally {
    loadingProvider.stopLoading(); // Stop loading
  }
}
