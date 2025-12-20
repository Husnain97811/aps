import 'dart:io';
import 'dart:math';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:mime/mime.dart';

class AddRecordDialog extends StatefulWidget {
  final String srNo;
  final VoidCallback onRecordAdded;

  const AddRecordDialog({
    super.key,
    required this.srNo,
    required this.onRecordAdded,
  });

  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final List<File> _documents = [];
  final _dateController = TextEditingController(
    text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
  );

  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _addDocuments() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'tiff'],
      );

      if (result == null || result.files.isEmpty) return;

      for (final platformFile in result.files) {
        if (platformFile.path == null) continue;

        final file = File(platformFile.path!);
        try {
          final processedFile = await FileUtils.processFile(file);
          setState(() => _documents.add(processedFile));
        } catch (e) {
          debugPrint(e.toString());

          SupabaseExceptionHandler.showErrorSnackbar(
            context,
            'Error processing file: $e',
          );
        }
      }
    } catch (e) {
      debugPrint(e.toString());

      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Error processing file: $e',
      );
    }
  }

  void _removeDocument(int index) {
    setState(() => _documents.removeAt(index));
  }

  Future<bool> _bucketExists() async {
    try {
      final response = await _supabase.storage.listBuckets();
      return response.contains('land-payment-documents');
    } catch (e) {
      print('Error checking buckets: $e');
      return false;
    }
  }

  Future<bool> _verifyBucketExists() async {
    try {
      final response = await _supabase.storage.listBuckets();
      return response.contains('land-payment-documents');
    } catch (e) {
      debugPrint('Bucket check error: $e');
      return false;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
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

        // create record in expenses table

        final expenseData = {
          'id': customId, // Use custom ID
          'description': _descriptionController.text,
          'amount': double.parse(_amountController.text),
          'date': _dateController.text,
          'category': 'Land Payment',
          'sr_no': widget.srNo,
          // 'title': _titleController.text,
          // 'custom_id': customId, // Add custom ID
        };

        // Create record in land payment records table
        final recordData = {
          'sr_no': widget.srNo,
          'title': _titleController.text,
          'description': _descriptionController.text,
          'amount': double.parse(_amountController.text),
          'date': _dateController.text,
        };

        final response =
            await _supabase
                .from('land_payment_records')
                .insert(recordData)
                .select()
                .single();

        final recordId = response['id'] as String;

        try {
          // save data to expense
          await _supabase.from('expenses').insert(expenseData);
        } catch (e) {
          print('Error inserting record: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving record: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Upload documents with optimized storage approach
        for (final file in _documents) {
          try {
            // Generate unique filename without path
            final originalName = file.path.split('/').last;
            final extension =
                originalName.contains('.')
                    ? originalName.substring(originalName.lastIndexOf('.'))
                    : '';
            final uniqueFileName =
                'doc_${recordId}_${DateTime.now().millisecondsSinceEpoch}$extension';

            // Upload directly to bucket root
            final uploadResponse = await _supabase.storage
                .from('land-payment-documents')
                .uploadBinary(
                  uniqueFileName, // No path = no folders
                  await file.readAsBytes(),
                  fileOptions: FileOptions(
                    contentType:
                        lookupMimeType(file.path) ?? 'application/octet-stream',
                    upsert: false,
                  ),
                );

            // Save document reference with unique filename
            await _supabase.from('land_payment_documents').insert({
              'record_id': recordId,
              'file_name': originalName, // Original name for display
              'file_path': uniqueFileName, // Unique name for storage
              'file_size': await file.length(),
              'mime_type': lookupMimeType(file.path),
            });
          } catch (e) {
            print('Failed to upload document: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to upload document: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }

        // Success
        widget.onRecordAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Record saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Overall error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving record: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / 1048576).toStringAsFixed(1)} MB';
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.all(3.w),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 8,
      child: Container(
        decoration: BoxDecoration(
          // gradient: AppColors.rmncolorlight,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Payment Record',
                    style: GoogleFonts.aBeeZee(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textcolor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textcolor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: AppColors.darkbrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: AppColors.darkbrown.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.confirmation_number, color: AppColors.darkbrown),
                    SizedBox(width: 3.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Serial Number',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppColors.blackcolor,
                          ),
                        ),
                        Text(
                          widget.srNo,
                          style: GoogleFonts.aBeeZee(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.darkbrown,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: 'Title',
                      icon: Icons.title,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 2.h),
                    _buildTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      icon: Icons.description,
                      maxLines: 3,
                      validator: (value) => value!.isEmpty ? 'Required' : null,
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _amountController,
                            label: 'Amount',
                            icon: Icons.attach_money,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty)
                                return 'Enter amount';
                              if (double.tryParse(value) == null)
                                return 'Invalid number';
                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 3.w),
                        Expanded(child: _buildDateField()),
                      ],
                    ),
                    SizedBox(height: 2.h),
                    _buildDocumentSection(),
                    SizedBox(height: 3.h),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.buttoncolor,
                        padding: EdgeInsets.symmetric(vertical: 1.8.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: Text(
                        'Save Payment Record',
                        style: GoogleFonts.aBeeZee(
                          fontSize: 14.sp,
                          color: AppColors.whitecolor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: AppColors.textcolor, fontSize: 12.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textcolor),
        prefixIcon: Icon(icon, color: AppColors.darkbrown),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.whitecolor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.darkbrown),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDateField() {
    return TextFormField(
      controller: _dateController,
      style: TextStyle(color: AppColors.textcolor, fontSize: 12.sp),
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Date',
        labelStyle: TextStyle(color: AppColors.textcolor),
        prefixIcon: Icon(Icons.calendar_today, color: AppColors.darkbrown),
        suffixIcon: IconButton(
          icon: Icon(Icons.calendar_month, color: AppColors.darkbrown),
          onPressed: _selectDate,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.whitecolor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: AppColors.darkbrown),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      ),
    );
  }

  Widget _buildDocumentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Attached Documents',
          style: GoogleFonts.aBeeZee(
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: AppColors.textcolor,
          ),
        ),
        SizedBox(height: 1.h),
        if (_documents.isEmpty)
          Center(
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppColors.whitecolor),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 12.sp,
                    color: AppColors.blackcolor,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'No documents attached',
                    style: TextStyle(
                      color: AppColors.blackcolor,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children:
                _documents.asMap().entries.map((entry) {
                  final index = entry.key;
                  final file = entry.value;
                  final fileName = file.path.split('/').last;
                  final fileSize = _formatFileSize(file.lengthSync());

                  return Container(
                    margin: EdgeInsets.only(bottom: 1.h),
                    padding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 1.5.h,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(color: AppColors.whitecolor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.description, color: AppColors.darkbrown),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fileName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textcolor,
                                  fontSize: 11.sp,
                                ),
                              ),
                              Text(
                                fileSize,
                                style: TextStyle(
                                  color: AppColors.whitecolor,
                                  fontSize: 10.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red[400]),
                          onPressed: () => _removeDocument(index),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        SizedBox(height: 1.h),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: AppColors.buttoncolor,
            ),
            child: TextButton.icon(
              icon: Icon(Icons.add, color: AppColors.blackcolor),
              label: Text(
                'Add Document',
                style: TextStyle(color: AppColors.whitecolor, fontSize: 11.sp),
              ),
              onPressed: _addDocuments,
            ),
          ),
        ),
      ],
    );
  }
}
