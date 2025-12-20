// widgets/edit_customer_dialog.dart
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';

class EditInvestorDialog extends StatefulWidget {
  final Investor investor;

  const EditInvestorDialog({super.key, required this.investor});

  @override
  State<EditInvestorDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<EditInvestorDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _cnicController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.investor.name);
    _cnicController = TextEditingController(text: widget.investor.cnic);
    _phoneController = TextEditingController(text: widget.investor.phone);
    _emailController = TextEditingController(text: widget.investor.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Investor'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _cnicController,
              decoration: const InputDecoration(labelText: 'CNIC'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedCustomer = widget.investor.copyWith(
              name: _nameController.text,
              cnic: _cnicController.text,
              phone: _phoneController.text,
              email:
                  _emailController.text.isEmpty ? null : _emailController.text,
            );
            Navigator.pop(context, updatedCustomer);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cnicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
