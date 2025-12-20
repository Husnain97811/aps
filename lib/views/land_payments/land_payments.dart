import 'dart:io';
import 'dart:math';
import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class LandPaymentRecordScreen extends StatefulWidget {
  const LandPaymentRecordScreen({super.key});

  @override
  State<LandPaymentRecordScreen> createState() =>
      _LandPaymentRecordScreenState();
}

class _LandPaymentRecordScreenState extends State<LandPaymentRecordScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<LandPaymentProvider>(
        context,
        listen: false,
      ).fetchRecords(_supabase);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _generateSrNo() {
    final random = Random();
    return 'LP${random.nextInt(900) + 100}';
  }

  void _showAddPaymentDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AddRecordDialog(
            srNo: _generateSrNo(),
            onRecordAdded: () {
              Provider.of<LandPaymentProvider>(
                context,
                listen: false,
              ).refreshRecords(_supabase);
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Land Payment Records',
          style: GoogleFonts.aBeeZee(
            fontSize: 18.sp,
            color: AppColors.whitecolor,
          ),
        ),
        centerTitle: true,
        backgroundColor: AppColors.darkbrown,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.whitecolor),
            onPressed: () {
              Provider.of<LandPaymentProvider>(
                context,
                listen: false,
              ).refreshRecords(_supabase);
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.rmncolorlight),
        child: Column(
          children: [
            _buildSearchBar(context),
            Expanded(
              child: Consumer<LandPaymentProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return Center(child: ProviderLoadingWidget());
                  }
                  if (provider.filteredRecords.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 80,
                            color: AppColors.whitecolor,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            provider.searchQuery.isEmpty
                                ? 'No Payment Records'
                                : 'No matching records found',
                            style: GoogleFonts.aBeeZee(
                              fontSize: 12.sp,
                              color: AppColors.textcolor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (provider.searchQuery.isEmpty)
                            Column(
                              children: [
                                SizedBox(height: 1.h),
                                Text(
                                  'Add your first payment record',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: AppColors.whitecolor,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.only(bottom: 8.h),
                    itemCount: provider.filteredRecords.length,
                    itemBuilder: (context, index) {
                      final record = provider.filteredRecords[index];
                      return _buildRecordCard(record);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addLandPayment',
        backgroundColor: AppColors.buttoncolor,
        onPressed: _showAddPaymentDialog,
        child: Icon(Icons.add, color: AppColors.whitecolor),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(2.h),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by title, description, amount or SR No...',
          hintStyle: TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search, color: AppColors.blackcolor),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          filled: true,
          fillColor: AppColors.whitecolor,
          // suffixIcon:
          //     _searchController.text.isNotEmpty
          //         ? IconButton(
          //           icon: Icon(Icons.clear, color: AppColors.blackcolor),
          //           onPressed: () {
          //             _searchController.clear();
          //             Provider.of<LandPaymentProvider>(
          //               context,
          //               listen: false,
          //             ).updateSearchQuery('');
          //           },
          //         )
          //         : null,
        ),
        onChanged: (value) {
          Provider.of<LandPaymentProvider>(
            context,
            listen: false,
          ).updateSearchQuery(value);
        },
      ),
    );
  }

  // Add this method to _LandPaymentRecordScreenState
  Future<void> _confirmDeleteRecord(LandPaymentRecord record) async {
    // Verify admin first
    // final isVerified = await AdminVerification.showVerificationDialog(
    //   context: context,
    //   action: 'delete this installment',
    // );

    // if (!isVerified) return;

    final provider = Provider.of<LandPaymentProvider>(context, listen: false);
    await _deleteRecord(record, provider);
    // if (confirmed == true) {
    // }
  }

  Future<void> _deleteRecord(
    LandPaymentRecord record,
    LandPaymentProvider provider,
  ) async {
    try {
      debugPrint('Starting deletion for record ${record.id}');

      // 1. Get associated documents
      final documents = await _supabase
          .from('land_payment_documents')
          .select()
          .eq('record_id', record.id);

      debugPrint('Found ${documents.length} documents to delete');

      // 2. Delete files from storage using direct REST API
      final failedDeletions = <String>[];
      final storageBucket = 'land-payment-documents';
      final supabaseUrl = 'https://vodmeztkbdssrripiamu.supabase.co';
      final accessToken = _supabase.auth.currentSession?.accessToken ?? '';

      for (final doc in documents) {
        try {
          final filePath = doc['file_path'];
          debugPrint('Attempting to delete file: $filePath');

          // Use direct REST API to delete the file
          final response = await http.delete(
            Uri.parse(
              '$supabaseUrl/storage/v1/object/$storageBucket/$filePath',
            ),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'apikey':
                  'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZvZG1lenRrYmRzc3JyaXBpYW11Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mzc3ODU4OTIsImV4cCI6MjA1MzM2MTg5Mn0.tEXOZkKXYIaroTPW9yC-8Q-qw_K-sasIzg1WKFZj8bA',
            },
          );

          if (response.statusCode == 200) {
            debugPrint('REST API deletion successful for $filePath');

            // Verify deletion by trying to get the file
            final verifyResponse = await http.get(
              Uri.parse(
                '$supabaseUrl/storage/v1/object/public/$storageBucket/$filePath',
              ),
            );

            if (verifyResponse.statusCode == 200) {
              debugPrint('File still exists after deletion: $filePath');
              failedDeletions.add(filePath);
            } else {
              debugPrint('Verified file deleted: $filePath');
            }
          } else {
            debugPrint('Deletion failed with status: ${response.statusCode}');
            debugPrint('Response body: ${response.body}');
            failedDeletions.add(filePath);
          }
        } catch (e) {
          debugPrint('Error deleting file: $e');
          failedDeletions.add(doc['file_path']);
        }
      }

      // 3. Delete database records
      await _supabase
          .from('land_payment_documents')
          .delete()
          .eq('record_id', record.id);
      await _supabase.from('land_payment_records').delete().eq('id', record.id);

      // 3. Delete all related database records in a transaction
      await _supabase.rpc(
        'delete_land_payment_with_related',
        params: {'p_record_id': record.id, 'p_sr_no': record.srNo},
      );

      // 4. Refresh data
      provider.refreshRecords(_supabase);

      // 5. Show appropriate message
      if (failedDeletions.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Record deleted but ${failedDeletions.length} files failed',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Record and all files deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Deletion failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deletion failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Add these methods to _LandPaymentRecordScreenState
  Future<void> _generateRecordPdf(LandPaymentRecord record) async {
    try {
      // 1. Get document details
      final documents = await _supabase
          .from('land_payment_documents')
          .select()
          .eq('record_id', record.id);

      // 2. Generate PDF
      final pdfFile = await _createPdfDocument(record, documents);

      // 3. Open the PDF
      await OpenFile.open(pdfFile.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<File> _createPdfDocument(
    LandPaymentRecord record,
    List<dynamic> documents,
  ) async {
    final pdf = pw.Document();
    final pdfWidgets = <pw.Widget>[];

    // Add header and record details
    pdfWidgets.addAll([
      pw.Header(
        level: 0,
        child: pw.Text(
          'Land Payment Record',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 20),
      _buildPdfRecordDetails(record),
      pw.SizedBox(height: 30),
    ]);

    // Add documents section
    final documentsSection = await _buildPdfDocumentsSectionWithImages(
      documents,
    );
    pdfWidgets.add(documentsSection);

    // Add to PDF
    pdf.addPage(
      pw.Page(
        build:
            (context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: pdfWidgets,
            ),
      ),
    );

    // Save to file
    final output = await getDownloadsDirectory();
    final file = File('${output!.path}/record_${record.srNo}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  Future<pw.Widget> _buildPdfDocumentsSectionWithImages(
    List<dynamic> documents,
  ) async {
    final children = <pw.Widget>[
      pw.Header(level: 1, child: pw.Text('Attached Documents')),
      pw.SizedBox(height: 10),
    ];

    if (documents.isEmpty) {
      children.add(pw.Text('No documents attached for this record'));
    } else {
      // Add table with document info
      children.add(
        pw.Table.fromTextArray(
          headers: ['File Name', 'Type', 'Size'],
          data:
              documents.map((doc) {
                final fileSizeBytes =
                    int.tryParse(doc['file_size'].toString()) ?? 0;
                final fileSizeKB = fileSizeBytes / 1024;
                return [
                  doc['file_name'],
                  doc['mime_type'],
                  '${fileSizeKB.toStringAsFixed(1)} KB',
                ];
              }).toList(),
        ),
      );

      // Add images to the PDF
      for (final doc in documents) {
        if (doc['mime_type'].startsWith('image/')) {
          try {
            // Download the image from Supabase storage
            final fileBytes = await _supabase.storage
                .from('land-payment-documents')
                .download(doc['file_path']);

            // Add the image to the PDF
            children.addAll([
              pw.SizedBox(height: 20),
              // pw.Text(
              //   doc['file_name'],
              //   style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              // ),
              pw.SizedBox(height: 10),
              pw.Image(
                pw.MemoryImage(fileBytes),
                width: 300,
                height: 300,
                fit: pw.BoxFit.contain,
              ),
            ]);
          } catch (e) {
            children.add(pw.Text('Failed to load image: ${doc['file_name']}'));
          }
        }
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: children,
    );
  }

  pw.Widget _buildPdfRecordDetails(LandPaymentRecord record) {
    return pw.Container(
      width: 250, // Use a fixed width or set to null for auto width
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Serial Number:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(record.srNo),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Title:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(record.title),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Description:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(record.description),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Amount:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(record.amount.toStringAsFixed(0)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Date:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(DateFormat.yMMMd().format(record.date)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPdfDocumentsSection(List<dynamic> documents) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(level: 1, child: pw.Text('Attached Documents')),
        pw.SizedBox(height: 10),
        if (documents.isEmpty)
          pw.Text('No documents attached for this record')
        else
          pw.Table.fromTextArray(
            headers: ['File Name', 'Type', 'Size'],
            data:
                documents.map((doc) {
                  // Convert file_size to int before calculation
                  final fileSizeBytes =
                      int.tryParse(doc['file_size'].toString()) ?? 0;
                  final fileSizeKB = fileSizeBytes / 1024;
                  return [
                    doc['file_name'],
                    doc['mime_type'],
                    '${fileSizeKB.toStringAsFixed(1)} KB',
                  ];
                }).toList(),
          ),
      ],
    );
  }

  Widget _buildRecordCard(LandPaymentRecord record) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
      child: Card(
        elevation: 10,
        margin: EdgeInsets.only(bottom: 1.5.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: ListTile(
          // tileColor: Color.fromARGB(97, 255, 255, 255),
          title: Text(
            record.title,
            style: GoogleFonts.aBeeZee(
              fontSize: 13.sp,
              fontWeight: FontWeight.w500,
              color: AppColors.textcolor,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0.5.h),
              Text(
                record.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.sp, color: AppColors.textcolor),
              ),
              SizedBox(height: 0.5.h),
              Text(
                'Amount: ${record.amount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textcolor,
                ),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: AppColors.darkbrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  record.srNo,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkbrown,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'View Document',
                icon: Icon(Icons.visibility),
                onPressed: () {
                  _generateRecordPdf(record);
                },
              ),
              IconButton(
                tooltip: 'Delete',
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  AdminVerification.showVerificationDialog(
                    context: context,
                    action: 'Do you want to delete this record?',
                  ).then((verified) {
                    if (verified == true) {
                      _confirmDeleteRecord(record);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
