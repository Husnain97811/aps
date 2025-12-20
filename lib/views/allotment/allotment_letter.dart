import 'dart:io';

import 'package:aps/views/forms/allotment_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:aps/config/view.dart';

class AllotmentLetter extends StatefulWidget {
  const AllotmentLetter({super.key});

  @override
  State<AllotmentLetter> createState() => _AllotmentLetterState();
}

class _AllotmentLetterState extends State<AllotmentLetter> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildBody(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text('Allotments', style: GoogleFonts.aBeeZee(fontSize: 18.sp)),
      backgroundColor: AppColors.darkbrown,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: AppColors.whitecolor),
          onPressed: () => context.read<AllotmentProvider>().refreshData(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.rmncolorlight),
      child: Column(
        children: [
          _buildSearchBar(context),
          SizedBox(height: 1.h),
          _buildClientList(context),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2.h),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by Plot No or Name...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: AppColors.blackcolor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: AppColors.whitecolor,
        ),
        onChanged:
            (value) =>
                context.read<AllotmentProvider>().updateSearchQuery(value),
      ),
    );
  }

  // Update PDF generation with Consumer for better performance
  Widget _buildClientList(BuildContext context) {
    return Expanded(
      child: Consumer<AllotmentProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return Center(child: ProviderLoadingWidget());
          }
          return Consumer<AllotmentProvider>(
            builder: (context, provider, _) {
              return ListView.builder(
                itemCount: provider.filteredMembers.length,
                itemBuilder: (context, index) {
                  final member = provider.filteredMembers[index];
                  return Consumer<AllotmentProvider>(
                    builder: (context, provider, _) {
                      return _ClientListItem(member: member);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildClientListView(BuildContext context) {
    return Consumer<AllotmentProvider>(
      builder: (context, provider, _) {
        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 2.w),
          itemCount: provider.filteredMembers.length,
          itemBuilder: (context, index) {
            final member = provider.filteredMembers[index];
            return _ClientListItem(member: member);
          },
        );
      },
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'addAllotment',
      mini: true,
      backgroundColor: AppColors.buttoncolor,
      onPressed: () async {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => AddAllotmentScreen()),
        );
        // Fetch the list of members
        // final members = context.read<AllotmentProvider>().filteredMembers;

        // // Check if there are members available
        // if (members.isNotEmpty) {
        //   // Example: Use the first member's membership number
        //   final membershipNo =
        //       members.first['membership_no']?.toString() ?? 'N/A';

        //   // Navigate to AddAllotmentScreen with the membership number

        // } else {
        //   // Show a message if no members are available
        //   ScaffoldMessenger.of(
        //     context,
        //   ).showSnackBar(const SnackBar(content: Text('No members available')));
        // }
      },
      child: const Icon(Icons.add, color: AppColors.whitecolor),
    );
  }

  // function to add allotment details

  Future<Map<String, dynamic>?> _showAddAllotmentDialog(
    BuildContext context,
  ) async {
    final plotNoController = TextEditingController();
    final streetController = TextEditingController();
    final sizeController = TextEditingController(text: '5 Marla');
    final categoryController = TextEditingController(text: 'Residential');

    return await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Allotment Details'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: plotNoController,
                    decoration: const InputDecoration(
                      labelText: 'Plot No*',
                      hintText: 'e.g., B-12',
                    ),
                  ),
                  TextField(
                    controller: streetController,
                    decoration: const InputDecoration(
                      labelText: 'Street*',
                      hintText: 'e.g., Street 5',
                    ),
                  ),
                  TextField(
                    controller: sizeController,
                    decoration: const InputDecoration(
                      labelText: 'Size*',
                      hintText: 'e.g., 5 Marla',
                    ),
                  ),
                  TextField(
                    controller: categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category*',
                      hintText: 'e.g., Residential/Commercial',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (plotNoController.text.isEmpty ||
                      streetController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Required fields are missing'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'plot_no': plotNoController.text,
                    'street': streetController.text,
                    'size': sizeController.text,
                    'category': categoryController.text,
                  });
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveAllotmentDetails(
    BuildContext context,
    Map<String, dynamic> allotmentDetails,
  ) async {
    try {
      final allotmentProvider = context.read<AllotmentProvider>();
      // Fetch the membership number from Supabase
      final response =
          await Supabase.instance.client
              .from('membership_forms')
              .select('membership_no')
              .eq('id', allotmentDetails['form_id'])
              .maybeSingle();

      if (response == null) {
        throw Exception('Failed to fetch membership number: response is null');
      }

      final membershipNo = response['membership_no']?.toString() ?? 'N/A';

      // Save allotment details to Supabase
      await allotmentProvider.createAllotment(membershipNo, allotmentDetails);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allotment details saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save allotment details: ${e.toString()}'),
        ),
      );
    }
  }
}

class _ClientListItem extends StatelessWidget {
  final Map<String, dynamic> member;

  const _ClientListItem({required this.member});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Card(
        elevation: 10,
        margin: EdgeInsets.only(bottom: 1.5.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          tileColor: const Color.fromARGB(97, 255, 255, 255),
          title: Text(
            member['name'].toString().toUpperCase() ?? 'N/A',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13.sp,
              color: AppColors.blackcolor,
            ),
          ),
          subtitle: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Form No: ${member['form_no']}' ?? 'N/A',
                style: TextStyle(fontSize: 12.sp, color: AppColors.blackcolor),
              ),
              Text(
                'Plot No: ${member['plot_no']}' ?? 'N/A',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.blackcolor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green),
                onPressed: () async {
                  final verfied =
                      await AdminVerification.showVerificationDialog(
                        context: context,
                        action: 'edit this Allotment',
                      );
                  if (!verfied) return;
                  _editAllotmentDetails(context, member);
                },
              ),
              IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.blue),
                onPressed: () => _generateAllotmentPdf(context, member),
              ),
            ],
          ),
          onTap: () => _showClientDetailsDialog(context, member),
        ),
      ),
    );
  }

  Future<void> _generateAllotmentPdf(
    BuildContext context,
    Map<String, dynamic> member,
  ) async {
    try {
      final membershipForm = await context
          .read<AllotmentProvider>()
          .getMemberDetails(member['membership_no']);
      // Fetch the allotment details
      final allotment = await context
          .read<AllotmentProvider>()
          .getAllotmentDetails(member['membership_no']);
      if (allotment == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No allotment found for this member')),
        );
        return;
      }

      // Load the curved image
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
                  _buildPdfHeader(),
                  pw.SizedBox(height: 20),
                  _buildAllotmentInfoPdf(allotment),
                  pw.SizedBox(height: 28),
                  _buildClientDetailsPdf(member),
                  pw.SizedBox(height: 20),
                  _buildPlotDetailsPdf(allotment, member),
                  pw.SizedBox(height: 20),
                  _buildNotesSectionPdf(),
                  // pw.Spacer(),
                  pw.SizedBox(height: 100),
                  _buildSignatureSectionPdf(),
                ],
              ),
        ),
      );

      final output = await getApplicationDocumentsDirectory();
      final file = File(
        '${output.path}/allotment_${member['membership_no']}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF generated successfully: ${file.path}')),
      );
    } catch (e) {
      print('Error generating PDF: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: ${e.toString()}')),
      );
    }
  }

  Future<void> _editAllotmentDetails(
    BuildContext context,
    Map<String, dynamic> member,
  ) async {
    final provider = context.read<AllotmentProvider>();
    final allotment = await provider.getAllotmentDetails(
      member['membership_no'],
    );

    if (allotment == null) return;

    final updatedDetails = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditAllotmentDialog(allotment: allotment),
    );

    if (updatedDetails != null) {
      await provider.updateAllotment(member['membership_no'], updatedDetails);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allotment updated successfully')),
      );
    }
  }

  pw.Widget _buildPdfHeader() {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: pw.Text(
              'Al-Imran Garden',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            ),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildAllotmentInfoPdf(Map<String, dynamic> allotment) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Row(
          children: [
            pw.Text(
              'Date ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Container(
              alignment: pw.Alignment.center,
              width: 80,
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(width: 1)),
              ),
              child: pw.Text(
                _formatDate(allotment['allotment_date']), // Handle null date
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
                allotment['sr_no']?.toString() ?? 'N/A', // Handle null sr_no
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateString));
    } catch (e) {
      return 'Invalid Date';
    }
  }

  pw.Widget _buildClientDetailsPdf(Map<String, dynamic> member) {
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
                _buildTableHeader('Membership No'),
                _buildTableHeader('Name'),
                _buildTableHeader('CNIC'),
                _buildTableHeader('Address'),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell(
                  member['membership_no']?.toString().toUpperCase() ?? 'N/A',
                ),
                _buildTableCell(
                  member['name'] != null
                      ? member['name']
                          .toString()
                          .split(' ')
                          .map(
                            (word) =>
                                word.isEmpty
                                    ? ''
                                    : word[0].toUpperCase() +
                                        word.substring(1).toLowerCase(),
                          )
                          .join(' ')
                      : 'N/A',
                ),
                _buildTableCell(
                  member['cnic_passport_no']?.toString() ?? 'N/A',
                ),
                _buildTableCellAddress(
                  member['address'] != null
                      ? member['address']
                          .toString()
                          .split(' ')
                          .map(
                            (word) =>
                                word.isEmpty
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

  pw.Widget _buildPlotDetailsPdf(
    Map<String, dynamic> allotment,
    Map<String, dynamic> membershipForm,
  ) {
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
              children: [
                _buildTableHeader('Plot No'),
                _buildTableHeader('Street'),
                _buildTableHeader('Size'),
                _buildTableHeader('Category'),
              ],
            ),
            pw.TableRow(
              children: [
                _buildTableCell(allotment['plot_no']?.toString() ?? 'N/A'),
                _buildTableCell(
                  allotment['street']?.toString().toUpperCase() ?? 'N/A',
                ),
                _buildTableCell(
                  allotment['size'] != null
                      ? '${allotment['size']} Marla'
                      : 'N/A',
                ),
                _buildTableCell(
                  (allotment['special_category'] == null ||
                          allotment['special_category'].toString().isEmpty)
                      ? 'General'
                      : allotment['special_category'].toString().isNotEmpty
                      ? allotment['special_category']
                              .toString()[0]
                              .toUpperCase() +
                          allotment['special_category'].toString().substring(1)
                      : 'General',
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildNotesSectionPdf() {
    return pw.Align(
      alignment: pw.Alignment.center,
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(
            'Note',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18),
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

  pw.Widget _buildSignatureSectionPdf() {
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

  pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCell(dynamic value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: pw.Text(
        value?.toString() ?? 'N/A', // Handle null values
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildTableCellAddress(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(fontSize: 8),
      ),
    );
  }

  void _showClientDetailsDialog(
    BuildContext context,
    Map<String, dynamic> member,
  ) {
    showDialog(
      context: context,
      builder: (context) => ClientDetailsDialog(client: member),
    );
  }
}

class ClientDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> client;

  const ClientDetailsDialog({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        client['membership_no']?.toString().toUpperCase() ?? 'N/A',
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: AppColors.textcolor,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', client['name']),
            _buildDetailRow('Mobile', client['mobile_no']),
            _buildDetailRow(
              'Membership No',
              client['membership_no'].toString().toUpperCase(),
            ),
            _buildDetailRow('Alottment Date', client['allotment_date']),
            SizedBox(height: 2.h),
            Text(
              'Plot Info:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: AppColors.textcolor,
              ),
            ),
            _buildDetailRow(
              'Category',
              client['special_category'] ?? 'General',
            ),
            _buildDetailRow('Plot No.', client['plot_no']),
            _buildDetailRow('Plot Size', '${client['plot_size']} Marla'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: TextStyle(color: AppColors.buttoncolor)),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      backgroundColor: AppColors.whitecolor,
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    String formattedValue =
        (label == 'Membership No')
            ? value?.toString() ?? 'N/A'
            : capitalizeEachWord(value?.toString() ?? 'N/A');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '$label: ',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(flex: 1, child: Text(formattedValue)),
        ],
      ),
    );
  }

  String capitalizeEachWord(String input) {
    if (input.isEmpty) return input;
    return input
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
