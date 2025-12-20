import 'dart:io';
import 'dart:math';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddAllotmentScreen extends StatefulWidget {
  const AddAllotmentScreen({super.key});

  @override
  State<AddAllotmentScreen> createState() => _AddAllotmentScreenState();
}

class _AddAllotmentScreenState extends State<AddAllotmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final membershipNoController = TextEditingController();
  final plotNoController = TextEditingController();
  final streetController = TextEditingController();
  final sizeController = TextEditingController();
  final specialCategoryController = TextEditingController();

  String? name;
  String? cnic;
  String? address;
  String? srNo;
  String? date;
  double? costOfLand;

  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    srNo = _generateSrNo();
    date = DateTime.now().toIso8601String();
  }

  String _generateSrNo() {
    final random = Random().nextInt(10000000).toString().padLeft(7, '0');
    return random;
  }

  Future<void> _fetchClientDetails() async {
    if (membershipNoController.text.isEmpty) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Please enter a membership number',
      );
      return;
    }

    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.startLoading(); // Start loading

    try {
      // Step 1: Fetch member details without checking is_allotted
      final response =
          await Supabase.instance.client
              .from('membership_forms')
              .select('''
          name, 
          cnic_passport_no, 
          address, 
          cost_of_land,
          plot_no,
          plot_size,
          special_category,
          is_allotted
        ''')
              .eq('membership_no', membershipNoController.text.toLowerCase())
              .single();

      // Step 2: Check if the member is already allotted
      if (response['is_allotted'] == true) {
        SupabaseExceptionHandler.showErrorSnackbar(
          context,
          'This member has already been allotted',
        );
        return;
      }

      // Step 3: Update the UI with member details
      setState(() {
        name = response['name'];
        cnic = response['cnic_passport_no'];
        address = response['address'];
        costOfLand = double.tryParse(
          response['cost_of_land']?.toString() ?? '0',
        );
        plotNoController.text = response['plot_no']?.toString() ?? '';
        sizeController.text = response['plot_size']?.toString() ?? '';
        final specialCategory =
            response['special_category']?.toString() ?? 'General';
        specialCategoryController.text =
            specialCategory.isEmpty ? 'General' : specialCategory;
      });
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        SupabaseExceptionHandler.showErrorSnackbar(context, 'Member not found');
      } else {
        final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
        SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
      }
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      loadingProvider.stopLoading(); // Stop loading
    }
  }

  Future<void> _saveAllotmentDetails() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final loadingProvider = context.read<LoadingProvider>();
    loadingProvider.startLoading(); // Start loading
    final supabase = Supabase.instance.client;

    // fetch current user id and name
    final userId = supabase.auth.currentUser!.id;
    final userName =
        await supabase
            .from('profiles')
            .select('full_name')
            .eq('id', userId)
            .maybeSingle();

    try {
      final allotmentDetails = {
        'sr_no': srNo,
        'membership_no': membershipNoController.text.toLowerCase(),
        'name': name,
        'plot_no': plotNoController.text,
        'street': streetController.text,
        'size': sizeController.text,
        'special_category': specialCategoryController.text.toLowerCase(),
        'allotment_date': DateTime.now().toLocal().toString(),
        'created_by': userName?['full_name'].toString(),
      };

      await Supabase.instance.client
          .from('allotments')
          .insert([allotmentDetails])
          .then((value) async {
            await Supabase.instance.client
                .from('membership_forms')
                .update({
                  'is_allotted': true,
                  'plot_no': plotNoController.text,
                  'special_category':
                      specialCategoryController.text.toLowerCase(),
                  'allotment_date': date,
                })
                .eq('membership_no', membershipNoController.text.toLowerCase());
          });

      setState(() => _isSaved = true);

      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Allotment details saved successfully!',
      );
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      loadingProvider.stopLoading(); // Stop loading
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Allotment Details'),
        centerTitle: true,
      ),
      body: LoadingOverlay(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sr. No and Date
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: srNo,
                          decoration: const InputDecoration(
                            labelText: 'Sr. No',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue:
                              DateTime.now().toLocal().toString().split(' ')[0],
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          readOnly: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Client Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Client Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: membershipNoController,
                        decoration: const InputDecoration(
                          labelText: 'Membership No*',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter membership number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: _fetchClientDetails,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(200, 50),
                          ),
                          child: const Text('Verify'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: TextEditingController(text: name),
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: TextEditingController(text: cnic),
                        decoration: const InputDecoration(
                          labelText: 'CNIC',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: TextEditingController(text: address),
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Plot Details
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Plot Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: plotNoController,
                        decoration: const InputDecoration(
                          labelText: 'Plot No*',
                          border: OutlineInputBorder(),
                        ),
                        // readOnly: true,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: streetController,
                        decoration: const InputDecoration(
                          labelText: 'Street*',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: sizeController,
                        decoration: const InputDecoration(
                          labelText: 'Size*',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: specialCategoryController,
                        decoration: const InputDecoration(
                          labelText: 'Special Category*',
                          border: OutlineInputBorder(),
                        ),
                        readOnly: true,
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Save Button
                  if (!_isSaved)
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveAllotmentDetails,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                        child: const Text('Generate'),
                      ),
                    ),

                  // Save as PDF Button (Visible only if data is saved)
                  if (_isSaved)
                    Center(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _saveAndGeneratePdf();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(200, 50),
                        ),
                        child: const Text('Save as PDF'),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndGeneratePdf() async {
    final allotmentDetails = {
      'sr_no': srNo,
      'date': date,
      'membership_no': membershipNoController.text.toLowerCase(),
      'name': name,
      'cnic': cnic,
      'address': address,
      'plot_no': plotNoController.text,
      'street': streetController.text,
      'size': sizeController.text,
      'special_category': specialCategoryController.text,
    };

    await _generatePdf(allotmentDetails);
  }

  Future<void> _generatePdf(Map<String, dynamic> allotmentDetails) async {
    try {
      final loadingProvider = context.read<LoadingProvider>();
      loadingProvider.startLoading();
      final imageBytes = await rootBundle.load(
        'assets/images/allotmentlettercurved.png',
      );
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build:
              (pw.Context context) => pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,

                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.SizedBox(height: 60),
                  pw.Image(
                    pw.MemoryImage(imageBytes.buffer.asUint8List()),
                    width: 300,
                  ),
                  _buildHeader(),
                  pw.SizedBox(height: 20),
                  _buildAllotmentInfo(allotmentDetails),
                  pw.SizedBox(height: 28),
                  _buildClientDetails(allotmentDetails),
                  pw.SizedBox(height: 20),
                  _buildPlotDetails(allotmentDetails),
                  pw.SizedBox(height: 20),
                  _buildNotesSection(),
                  // pw.Spacer(),
                  pw.SizedBox(height: 100),

                  _buildSignatureSection(),
                  // pw.SizedBox(height: 103),
                ],
              ),
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/allotment_${allotmentDetails['membership_no']}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'PDF generated successfully: ${file.path}',
      );
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      final loadingProvider = context.read<LoadingProvider>();
      loadingProvider.stopLoading();
    }
  }
}

pw.Widget _buildHeader() {
  return pw.Column(
    children: [
      pw.Center(
        child: pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(),
          child: pw.Column(
            children: [
              // pw.Text(
              //   'Allotment Letter',
              //   style: pw.TextStyle(
              //     fontSize: 35,
              //     fontWeight: pw.FontWeight.bold,
              //   ),
              // ),
              // pw.SizedBox(height: 4),
              pw.Text(
                'Al-Imran Garden',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 20),
    ],
  );
}

pw.Widget _buildAllotmentInfo(Map<String, dynamic> details) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
    children: [
      pw.Row(
        children: [
          pw.Text(
            'Date ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            // style: pw.TextStyle(color: PdfColors.grey600),
          ),
          pw.Container(
            alignment: pw.Alignment.center,

            width: 80,
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),
            child: pw.Text(
              DateFormat('dd/MM/yyyy').format(DateTime.parse(details['date'])),

              // '${DateTime.parse(details['date']).toLocal().toString().split(' ')[0]}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),

      pw.Row(
        children: [
          pw.Text(
            'Sr.No: ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Container(
            alignment: pw.Alignment.center,
            width: 80,
            decoration: pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(width: 1)),
            ),

            child: pw.Text(
              '${details['sr_no']}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildClientDetails(Map<String, dynamic> details) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Client Details',
        style: pw.TextStyle(
          fontSize: 17.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 1.7),
        columnWidths: {
          0: const pw.FlexColumnWidth(0.8),
          1: const pw.FlexColumnWidth(1.3),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1.8),
        },
        children: [
          pw.TableRow(
            children: [
              _buildTableCell(
                details['membership_no'].toString().toUpperCase(),
              ),
              _buildTableCell(
                details['name'] != null
                    ? details['name']
                        .toString()
                        .split(' ')
                        .map(
                          (word) =>
                              word
                                      .isEmpty // Check if word is empty
                                  ? ''
                                  : word[0].toUpperCase() +
                                      word.substring(1).toLowerCase(),
                        )
                        .join(' ')
                    : 'N/A',
              ),
              _buildTableCell(details['cnic']?.toString() ?? 'N/A'),
              _buildTableCellAddress(
                details['address'] != null
                    ? details['address']
                        .toString()
                        .split(' ')
                        .map(
                          (word) =>
                              word
                                      .isEmpty // Check if word is empty
                                  ? ''
                                  : word[0].toUpperCase() +
                                      word.substring(1).toLowerCase(),
                        )
                        .join(' ')
                    : 'N/A',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildPlotDetails(Map<String, dynamic> details) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        'Plot Details',
        style: pw.TextStyle(
          fontSize: 17.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Table(
        border: pw.TableBorder.all(color: PdfColors.black, width: 1.7),
        columnWidths: {
          0: const pw.FlexColumnWidth(1),
          1: const pw.FlexColumnWidth(1),
          2: const pw.FlexColumnWidth(1),
          3: const pw.FlexColumnWidth(1),
        },
        children: [
          pw.TableRow(
            // decoration: pw.BoxDecoration(color: PdfColors.black),
            children: [
              _buildTableHeader('Plot No'),
              _buildTableHeader('Street'),
              _buildTableHeader('Size'),
              _buildTableHeader('Category'),
            ],
          ),
          pw.TableRow(
            children: [
              _buildTableCell(
                details['plot_no']?.toString() ?? 'N/A',
              ), // Handle null plot_no
              _buildTableCell(
                details['street']?.toString().toUpperCase() ?? 'N/A',
              ), // Handle null street
              _buildTableCell('${details['size']} Marla'),
              _buildTableCell(
                (details['special_category'] == null ||
                        details['special_category'].toString().isEmpty)
                    ? 'General'
                    : details['special_category']
                        .toString()
                        .isNotEmpty // Check if non-empty
                    ? details['special_category'].toString()[0].toUpperCase() +
                        details['special_category'].toString().substring(1)
                    : 'General',
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

pw.Widget _buildTableHeader(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        // color: PdfColors.blue800,
      ),
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildTableCell(String? text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(8),
    child: pw.Text(
      text ?? 'N/A', // Handle null values
      textAlign: pw.TextAlign.center,
    ),
  );
}

pw.Widget _buildTableCellAddress(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(text, textAlign: pw.TextAlign.center),
  );
}

pw.Widget _buildNotesSection() {
  return pw.Align(
    alignment: pw.Alignment.center,
    child: pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          'Note',
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.normal,
            fontSize: 18,
            // color: PdfColors.red800,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Bullet(
          style: pw.TextStyle(fontSize: 10),

          text:
              'This allotment is temporary and is subject to the approval of the terms and conditions',
        ),
        pw.Bullet(
          style: pw.TextStyle(fontSize: 10),

          text:
              'The management of Reliable Marketing Network (Pvt) Limited reserves the right to alter the location and area of cancel the allotment until the physical possession of the plot is handed over to the allottee.',
        ),
      ],
    ),
  );
}

pw.Widget _buildSignatureSection() {
  return pw.Align(
    alignment: pw.Alignment.centerRight,
    child: pw.Column(
      children: [
        pw.Container(
          height: 1,
          width: 170,
          color: PdfColors.black,
          margin: const pw.EdgeInsets.only(bottom: 8),
        ),
        pw.Text(
          'Authorized Sign.',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    ),
  );
}
