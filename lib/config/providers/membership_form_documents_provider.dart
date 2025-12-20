import 'dart:io';
import 'dart:typed_data';
import 'package:aps/config/view.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/widgets.dart' as pdfWidgets;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:mime/mime.dart';

class DocumentsProvider {
  final SupabaseClient _supabase = Supabase.instance.client;
  LoadingProvider? _loadingProvider;

  DocumentsProvider();

  void setLoadingProvider(LoadingProvider loadingProvider) {
    _loadingProvider = loadingProvider;
  }

  Future<List<Map<String, dynamic>>> getDocuments(String membershipNo) async {
    try {
      final response = await _supabase
          .from('client_documents')
          .select()
          .eq('membership_no', membershipNo)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  Future<void> uploadDocument(String membershipNo, File file) async {
    try {
      final processedFile = await FileUtils.processFile(file);
      final fileBytes = await processedFile.readAsBytes();
      final fileName = file.path.split('/').last;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Generate unique storage path
      final storagePath =
          '$membershipNo/${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

      // Upload to storage bucket
      await _supabase.storage
          .from('client_documents')
          .uploadBinary(storagePath, fileBytes);

      // Insert document metadata into table
      await _supabase.from('client_documents').insert({
        'membership_no': membershipNo,
        'file_name': fileName,
        'storage_path': storagePath,
      });
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  Future<void> deleteDocument(String documentId, String storagePath) async {
    try {
      // Delete from database
      await _supabase.from('client_documents').delete().eq('id', documentId);

      // Delete from storage
      await _supabase.storage.from('client_documents').remove([storagePath]);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  Future<Uint8List> getDocumentBytes(String storagePath) async {
    try {
      return await _supabase.storage
          .from('client_documents')
          .download(storagePath);
    } catch (e) {
      throw Exception('Failed to download document: $e');
    }
  }

  Future<void> generatePdf(String membershipNo) async {
    try {
      // 1. Get client details
      final clientResponse =
          await _supabase
              .from('membership_forms')
              .select()
              .eq('membership_no', membershipNo)
              .single();

      // 2. Get all documents
      final documents = await getDocuments(membershipNo);
      if (documents.isEmpty) throw Exception('No documents found');

      final pdf = pdfWidgets.Document();
      final List<pdfWidgets.Widget> contentWidgets = [];

      // 3. Add client information at the top
      contentWidgets.addAll([
        pdfWidgets.Header(
          level: 0,
          child: pdfWidgets.Text(
            'Client Documents',
            style: pdfWidgets.TextStyle(
              fontSize: 20,
              fontWeight: pdfWidgets.FontWeight.bold,
            ),
          ),
        ),
        pdfWidgets.SizedBox(height: 15),
        _buildClientInfo(clientResponse),
        pdfWidgets.SizedBox(height: 20),
        pdfWidgets.Text(
          'Document List (${documents.length})',
          style: pdfWidgets.TextStyle(
            fontSize: 16,
            fontWeight: pdfWidgets.FontWeight.bold,
          ),
        ),
        pdfWidgets.Divider(thickness: 1),
        pdfWidgets.SizedBox(height: 15),
      ]);

      // 4. Add all documents
      for (final doc in documents) {
        try {
          final bytes = await getDocumentBytes(doc['storage_path']);
          final mimeType = lookupMimeType(doc['file_name']);

          contentWidgets.addAll([
            // _buildDocumentHeader(doc),
            // pdfWidgets.SizedBox(height: 10),
            _buildDocumentPreview(bytes, mimeType),
            pdfWidgets.Divider(color: PdfColors.grey300),
            pdfWidgets.SizedBox(height: 20),
          ]);
        } catch (e) {
          contentWidgets.add(
            pdfWidgets.Text(
              'Error loading ${doc['file_name']}: $e',
              style: const pdfWidgets.TextStyle(color: PdfColors.red),
            ),
          );
        }
      }

      // 5. Add all content to PDF pages (will auto-paginate)
      pdf.addPage(
        pdfWidgets.Page(
          margin: const pdfWidgets.EdgeInsets.all(30),
          build:
              (context) => pdfWidgets.Column(
                crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
                children: contentWidgets,
              ),
        ),
      );

      // 6. Save and open PDF
      final output = await getTemporaryDirectory();
      final file = File('${output.path}/$membershipNo-documents.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      throw Exception('Failed to generate PDF: $e');
    }
  }

  // Helper for document headers
  pdfWidgets.Widget _buildDocumentHeader(Map<String, dynamic> doc) {
    return pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
      children: [
        pdfWidgets.Text(
          doc['file_name'],
          style: pdfWidgets.TextStyle(
            fontSize: 14,
            fontWeight: pdfWidgets.FontWeight.bold,
          ),
        ),
        pdfWidgets.SizedBox(height: 5),
        pdfWidgets.Text(
          'Uploaded: ${DateFormat('yyyy-MM-dd – HH:mm').format(DateTime.parse(doc['created_at']))}',
          style: const pdfWidgets.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  // Helper for client info
  pdfWidgets.Widget _buildClientInfo(Map<String, dynamic> client) {
    return pdfWidgets.Column(
      crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
      children: [
        pdfWidgets.Text(
          'Client Details',
          style: pdfWidgets.TextStyle(
            fontSize: 16,
            fontWeight: pdfWidgets.FontWeight.bold,
          ),
        ),
        pdfWidgets.SizedBox(height: 8),
        pdfWidgets.Text('Name: ${client['name']}'),
        pdfWidgets.Text('Membership No: ${client['membership_no']}'),
        if (client['phone'] != null)
          pdfWidgets.Text('Phone: ${client['phone']}'),
        if (client['email'] != null)
          pdfWidgets.Text('Email: ${client['email']}'),
      ],
    );
  }

  // Helper for document previews
  pdfWidgets.Widget _buildDocumentPreview(Uint8List bytes, String? mimeType) {
    if (mimeType == 'application/pdf') {
      return pdfWidgets.Column(
        crossAxisAlignment: pdfWidgets.CrossAxisAlignment.start,
        children: [
          pdfWidgets.Text(
            '[PDF Content Preview Not Available]',
            style: const pdfWidgets.TextStyle(color: PdfColors.blue),
          ),
          pdfWidgets.SizedBox(height: 5),
          pdfWidgets.Text(
            'Open the original file to view full content',
            style: const pdfWidgets.TextStyle(fontSize: 10),
          ),
        ],
      );
    } else if (mimeType?.startsWith('image/') ?? false) {
      return pdfWidgets.Center(
        child: pdfWidgets.Image(
          pdfWidgets.MemoryImage(bytes),
          width: 250,
          height: 250,
          fit: pdfWidgets.BoxFit.contain,
        ),
      );
    }
    return pdfWidgets.Text(
      '[Unsupported file type for preview]',
      style: const pdfWidgets.TextStyle(color: PdfColors.red),
    );
  }

  Future<File?> pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'tiff'],
    );

    if (result == null) return null;
    return File(result.files.single.path!);
  }
}
