import 'dart:io';

import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';

class DocumentManagerDialog extends StatefulWidget {
  final String membershipNo;
  final LoadingProvider loadingProvider;

  const DocumentManagerDialog({
    super.key,
    required this.membershipNo,
    required this.loadingProvider,
  });

  @override
  State<DocumentManagerDialog> createState() => _DocumentManagerDialogState();
}

class _DocumentManagerDialogState extends State<DocumentManagerDialog> {
  late Future<List<Map<String, dynamic>>> _documentsFuture;
  late final DocumentsProvider _documentsProvider;

  @override
  void initState() {
    super.initState();
    _documentsProvider = DocumentsProvider();
    _documentsProvider.setLoadingProvider(widget.loadingProvider);
    _refreshDocuments();
  }

  void _refreshDocuments() {
    setState(() {
      _documentsFuture = _documentsProvider.getDocuments(widget.membershipNo);
    });
  }

  Future<void> _uploadDocument() async {
    final file = await _documentsProvider.pickDocument();
    if (file == null) return;

    try {
      widget.loadingProvider.startLoading();
      await _documentsProvider.uploadDocument(widget.membershipNo, file);
      _refreshDocuments();
      SupabaseExceptionHandler.showSuccessSnackbar(
        context,
        'Document uploaded successfully',
      );
    } catch (e) {
      debugPrint(e.toString());
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Upload failed: ${e.toString()}',
      );
    } finally {
      widget.loadingProvider.stopLoading();
    }
  }

  Future<void> _previewDocument(String storagePath) async {
    try {
      widget.loadingProvider.startLoading();
      final bytes = await _documentsProvider.getDocumentBytes(storagePath);

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/preview_${DateTime.now().millisecondsSinceEpoch}',
      );
      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);
    } catch (e) {
      SupabaseExceptionHandler.showErrorSnackbar(
        context,
        'Preview failed: ${e.toString()}',
      );
    } finally {
      widget.loadingProvider.stopLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70.h,
      child: Dialog(
        insetPadding: EdgeInsets.all(20.sp),
        child: Padding(
          padding: EdgeInsets.all(6.sp),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Documents: ${widget.membershipNo}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _uploadDocument,
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _documentsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text('Error loading documents'),
                      );
                    }

                    final documents = snapshot.data!;

                    if (documents.isEmpty) {
                      return const Center(child: Text('No documents found'));
                    }

                    return ListView.builder(
                      itemCount: documents.length,
                      itemBuilder: (context, index) {
                        final doc = documents[index];
                        return ListTile(
                          title: Text(doc['file_name']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.preview),
                                onPressed:
                                    () => _previewDocument(doc['storage_path']),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () async {
                                  try {
                                    widget.loadingProvider.startLoading();
                                    await _documentsProvider.deleteDocument(
                                      doc['id'],
                                      doc['storage_path'],
                                    );
                                    _refreshDocuments();
                                    SupabaseExceptionHandler.showSuccessSnackbar(
                                      context,
                                      'Document deleted successfully',
                                    );
                                  } catch (e) {
                                    SupabaseExceptionHandler.showErrorSnackbar(
                                      context,
                                      'Delete failed: ${e.toString()}',
                                    );
                                  } finally {
                                    widget.loadingProvider.stopLoading();
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
