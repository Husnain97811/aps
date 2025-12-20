import 'dart:io';
import 'dart:math';

// import 'package:pdf_render/pdf_render.dart' as prefix;
import 'package:aps/config/view.dart';
import 'package:aps/investors/investor_model.dart';
import 'package:aps/investors/investor_provider.dart';
import 'package:aps/investors/profit_schedule.dart';
import 'package:aps/services/supabase_storage_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:provider/provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:uuid/uuid.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen>
    with AutomaticKeepAliveClientMixin {
  final SupabaseClient _supabase = Supabase.instance.client;
  final userid = Supabase.instance.client.auth.currentUser?.id ?? 'Unknown';
  // final _verificationService = VerificationService();
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Schedule the data fetch after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCustomers();
    });
  }

  Future<void> _fetchCustomers() async {
    final investorProvider = Provider.of<InvestorProvider>(
      context,
      listen: false,
    );
    await investorProvider.getInvestorsWithSchedules(context);
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final investorProvider = Provider.of<InvestorProvider>(context);
    // final user = Supabase.instance.client.auth.currentUser;

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: ChangeNotifierProvider(
        create: (_) => InvestorProvider(Supabase.instance.client),
        child: LoadingOverlay(
          child: Scaffold(
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'add_investor',
              onPressed: () => _showAddInvestorDialog(context),
              label: const Text('Add Investor'),
              icon: const Icon(Icons.person_add_alt_1),
              backgroundColor: Colors.blue,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/background_image.png',
                    fit: BoxFit.cover,
                    color: Colors.black.withOpacity(0.3),
                    colorBlendMode: BlendMode.darken,
                  ),
                ),
                Column(
                  children: [
                    // Updated App Bar Section
                    Container(
                      color: const Color.fromARGB(255, 208, 148, 59),
                      height: 24.sp,
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 23.sp),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Investors',
                            style: GoogleFonts.aBeeZee(fontSize: 18.sp),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  Icons.credit_card,
                                  color: Colors.blue,
                                ),
                                onPressed: () => _showInvestorActions(context),
                                tooltip: 'Investor Actions',
                              ),
                              IconButton(
                                icon: Icon(Icons.refresh, color: Colors.blue),
                                onPressed:
                                    () => investorProvider
                                        .getInvestorsWithSchedules(context),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildInvestorList(investorProvider)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showInvestorActions(BuildContext context) {
    final searchController = TextEditingController();
    Investor? foundInvestor;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Investor Actions'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      labelText: 'Enter CNIC or Investor ID',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.search),
                        onPressed: () async {
                          final provider = Provider.of<InvestorProvider>(
                            context,
                            listen: false,
                          );
                          final result = provider.searchInvestor(
                            searchController.text,
                          );

                          if (result != null) {
                            setState(() => foundInvestor = result);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Investor not found'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  if (foundInvestor != null) ...[
                    const SizedBox(height: 20),
                    _buildInvestorInfoCard(foundInvestor!),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          context,
                          icon: Icons.payment,
                          label: 'Pay Profit',
                          onTap: () {
                            Navigator.pop(context); // Close search dialog
                            _showPayProfitDialog(context, foundInvestor!);
                          },
                          color: Colors.green,
                        ),
                        SizedBox(width: 12.sp),
                        _buildActionButton(
                          context,
                          icon: Icons.assignment_return,
                          label: 'Return Amount',
                          onTap: () {
                            Navigator.pop(context); // Close search dialog
                            _showReturnDialog(context, foundInvestor!);
                          },
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Chip(
      label: Text(text, style: TextStyle(color: Colors.white, fontSize: 12)),
      backgroundColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildInvestorInfoCard(Investor investor) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Name: ${investor.name}',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('CNIC: ${investor.cnic}'),
            Text('Investor ID: ${investor.investorIdCode}'),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildInfoChip(
                  'Balance: ${investor.balanceAmount.toStringAsFixed(0)}',
                  Colors.blue,
                ),
                // const SizedBox(width: 8),
                // _buildInfoChip(
                //   'Pending Profit: ${investor.unpaidProfitBalance.toStringAsFixed(2)}',
                //   Colors.green,
                // ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // void _showActionSelectionDialog(BuildContext context, Investor investor) {
  //   showDialog(
  //     context: context,
  //     builder:
  //         (ctx) => AlertDialog(
  //           title: Text('Select Action for ${investor.name}'),
  //           content: Column(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               _buildActionButton(
  //                 context,
  //                 icon: Icons.payment,
  //                 label: 'Pay Profit',
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   _showPayProfitDialog(context, investor);
  //                 },
  //                 color: Colors.green,
  //               ),
  //               const SizedBox(height: 10),
  //               _buildActionButton(
  //                 context,
  //                 icon: Icons.assignment_return,
  //                 label: 'Return Amount',
  //                 onTap: () {
  //                   Navigator.pop(context);
  //                   _showReturnDialog(context, investor);
  //                 },
  //                 color: Colors.blue,
  //               ),
  //             ],
  //           ),
  //         ),
  //   );
  // }

  void _showPayProfitDialog(BuildContext context, Investor investor) {
    final totalInstallments = investor.timeDuration! ~/ investor.profitDuration;
    int? selectedInstallment;

    showDialog(
      context: context,
      builder:
          (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text('Pay Installment for ${investor.name}'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedInstallment,
                      items:
                          List.generate(totalInstallments, (i) => i + 1)
                              .where(
                                (i) =>
                                    !(investor.paidInstallments['m$i'] == true),
                              )
                              .map(
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text('Installment M$i'),
                                ),
                              )
                              .toList(),
                      onChanged:
                          (value) =>
                              setState(() => selectedInstallment = value),
                      decoration: InputDecoration(
                        labelText: 'Select Installment',
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Amount: ${_calculateMonthlyProfit(investor).toStringAsFixed(0)}',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed:
                        selectedInstallment == null
                            ? null
                            : () async {
                              final provider = Provider.of<InvestorProvider>(
                                context,
                                listen: false,
                              );
                              try {
                                await provider.processPayment(
                                  context: context,
                                  investorId: investor.id,
                                  amount: _calculateMonthlyProfit(investor),
                                  installmentNumber: selectedInstallment!,
                                );
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Payment successful')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString()}'),
                                  ),
                                );
                              }
                            },
                    child: Text('Confirm Payment'),
                  ),
                ],
              );
            },
          ),
    );
  }

  void _showReturnDialog(BuildContext context, Investor investor) {
    final amountController = TextEditingController();
    final provider = Provider.of<InvestorProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Return Amount to ${investor.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Current Balance: ${investor.balanceAmount.toStringAsFixed(0)}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Amount to Return',
                    prefixText: ' ',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text) ?? 0;

                  if (amount <= 0) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid positive amount'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  try {
                    await provider.processReturn(
                      investorId: investor.id,
                      amount: amount,
                    );

                    // Close dialog first
                    Navigator.pop(ctx);

                    // Then show success message using the saved scaffoldMessenger
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Return processed successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    // Show error using the dialog's context
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('Return failed: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Confirm Return'),
              ),
            ],
          ),
    );
  }

  // Add this helper widget for action buttons
  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: TextStyle(color: Colors.white)),
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Future<void> _updateInvestorProfilePicture(Investor investor) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result == null) return;

    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      var file = File(result.files.single.path!);

      // Compress and validate
      file = await FileUtils.compressAndValidateFile(
        file,
        isImage: true,
        quality: 80,
      );

      final url = await SupabaseStorageService.uploadFile(
        bucket: 'investorprofilepictures',
        userId: investor.id,
        file: file,
      );

      if (url != null) {
        await _supabase
            .from('investors')
            .update({'profile_picture_url': url})
            .eq('id', investor.id);

        // Refresh investor data
        final investorProvider = Provider.of<InvestorProvider>(
          context,
          listen: false,
        );
        await investorProvider.getInvestorsWithSchedules(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile picture: $e')),
      );
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Future<void> _updateInvestorDocuments(Investor investor) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'tiff'],
      allowMultiple: true,
    );

    if (result == null || result.files.isEmpty) return;

    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      for (var platformFile in result.files) {
        if (platformFile.path == null) continue;

        var file = File(platformFile.path!);

        // Validate document type
        if (!await FileUtils.isScannedDocument(file)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Only scanned jpg/JPEG/PNG/TIFF documents allowed'),
            ),
          );
          continue;
        }

        // Compress and validate size
        file = await documentsFileUtils.compressAndValidateFile(
          file,
          isImage: true,
          quality: 70,
        );

        final url = await SupabaseStorageService.uploadFile(
          bucket: 'investordocuments',
          userId: investor.id,
          file: file,
        );

        if (url != null) {
          // Insert into new documents table
          await _supabase.from('investor_documents').insert({
            'investor_id': investor.id,
            'document_url': url,
            'document_name': platformFile.name,
          });
        }
      }

      // Refresh investor data
      final investorProvider = Provider.of<InvestorProvider>(
        context,
        listen: false,
      );
      await investorProvider.getInvestorsWithSchedules(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to upload document: $e')));
    } finally {
      loadingProvider.stopLoading();
    }
  }

  Widget _buildInvestorList(InvestorProvider provider) {
    if (provider.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            Text(
              'Error loading investors',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(
              onPressed: () => provider.getInvestorsWithSchedules(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    } else if (provider.investors.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.castle_sharp, color: Colors.white, size: 32.sp),
          Text(
            'No investors found.',
            style: GoogleFonts.aBeeZee(
              fontSize: 13.sp,
              color: AppColors.whitecolor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      );
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.75,
        mainAxisSpacing: 4.h, // 28 -> 4.h
        crossAxisSpacing: 98, // 115 -> 25.w
      ),
      padding: EdgeInsets.symmetric(
        horizontal: 5.w,
        vertical: 2.h,
      ), // 28.sp -> 5.w
      itemCount: provider.investors.length,
      itemBuilder: (context, index) {
        final investor = provider.investors[index];
        final random = Random(investor.name.hashCode);
        final backgroundColor = Color.fromARGB(
          80,
          random.nextInt(100),
          random.nextInt(200),
          random.nextInt(200),
        );

        return Card(
          color:
              investor.status == 'active'
                  ? Colors.white
                  : const Color.fromARGB(255, 229, 209, 208),
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 11.sp,
                  vertical: 8.sp,
                ), // 16.0 -> 4.w
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Circular Avatar with Initial
                    Container(
                      height: 40.sp, // 35.sp -> 15.w
                      width: 40.sp,
                      padding: EdgeInsets.all(0.5.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.fromARGB(255, 251, 176, 64),
                          width: 0.2.w, // 2 -> 0.5.w
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 6.w,
                        backgroundColor: backgroundColor,
                        backgroundImage:
                            investor.profileImage != null &&
                                    investor.profileImage!.isNotEmpty
                                ? NetworkImage(investor.profileImage!)
                                : null,
                        child:
                            investor.profileImage == null ||
                                    investor.profileImage!.isEmpty
                                ? Text(
                                  investor.name.isNotEmpty
                                      ? investor.name
                                          .split(' ')
                                          .map(
                                            (word) =>
                                                word.isNotEmpty
                                                    ? word[0].toUpperCase()
                                                    : '',
                                          )
                                          .take(2)
                                          .join()
                                      : '?',
                                  style: TextStyle(
                                    fontSize: 20.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                )
                                : null,
                      ),
                    ),
                    SizedBox(height: 13.3.sp), // 16 -> 2.h
                    Column(
                      children: [
                        Text(
                          investor.name,
                          style: TextStyle(
                            fontSize: 14.2.sp,
                            fontWeight: FontWeight.bold,
                            // color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 3.3.sp), // 16 -> 2.h

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Investor ID: ',
                              style: TextStyle(
                                fontSize: 12.sp,
                                // color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              investor.investorIdCode,
                              style: TextStyle(
                                fontSize: 12.sp,
                                // color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 13.3.sp), // 16 -> 2.h

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            investor.phone == null || investor.phone == ''
                                ? Icon(Icons.e_mobiledata, color: Colors.white)
                                : Icon(Icons.phone),
                            SizedBox(width: 5.sp),
                            Text(
                              investor.phone,
                              style: TextStyle(
                                fontSize: 12.sp, // 14 -> 12.sp
                                // color: Colors.grey[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 10.sp),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          tooltip: 'Generate Documents Pdf',
                          onPressed: () async {
                            final verified =
                                await AdminVerification.showVerificationDialog(
                                  context: context,
                                  action: 'view documents for ${investor.name}',
                                );
                            if (!verified) {
                              SupabaseExceptionHandler.showErrorSnackbar(
                                context,
                                'Admin verification failed',
                              );
                              return;
                            }

                            await _generateInvestorDocumentsPdf(investor);
                          },
                          icon: Icon(Icons.document_scanner),
                        ),

                        InkWell(
                          onTap:
                              () => _showInvestorsDetailsDialog(
                                context,
                                investor,
                              ),
                          child: Container(
                            alignment: Alignment.center,
                            height: 5.5.h,
                            width: 8.5.w,
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 250, 168, 37),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              'More Info',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert,
                            color: Colors.black,
                            size: 15.sp,
                          ), // Add size
                          itemBuilder:
                              (context) => [
                                PopupMenuItem(
                                  value: 'active/unactive',
                                  child: ListTile(
                                    leading: Icon(Icons.edit, size: 12.sp),
                                    title: Text(
                                      'Active/Non-Active',
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit, size: 12.sp),
                                    title: Text(
                                      'Edit Profile',
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'update_profile_picture',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.camera_alt,
                                      size: 12.sp,
                                    ),
                                    title: Text(
                                      'Update Profile Picture',
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'add/update_documents',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.description,
                                      size: 12.sp,
                                    ),
                                    title: Text(
                                      'Add/Update Documents',
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(Icons.delete, size: 12.sp),
                                    title: Text(
                                      'Delete',
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'pdf',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.picture_as_pdf,
                                      size: 12.sp,
                                    ),
                                    title: Text(
                                      'Generate PDF',
                                      style: TextStyle(fontSize: 10.sp),
                                    ),
                                  ),
                                ),
                              ],
                          onSelected: (value) async {
                            if (value == 'active/unactive') {
                              _handleInvestorStatusChange(investor);
                            } else if (value == 'edit') {
                              // Get current user properly
                              final user =
                                  Supabase.instance.client.auth.currentUser;
                              _showEditInvestorDialog(
                                context,
                                investor,
                                user,
                              ); // Pass user directly
                            } else if (value == 'update_profile_picture') {
                              final verified =
                                  await AdminVerification.showVerificationDialog(
                                    context: context,
                                    action:
                                        'update profile picture for ${investor.name}',
                                  );
                              if (verified && context.mounted) {
                                await _updateInvestorProfilePicture(investor);
                              }
                            } else if (value == 'add/update_documents') {
                              final verified =
                                  await AdminVerification.showVerificationDialog(
                                    context: context,
                                    action:
                                        'update documents for ${investor.name}',
                                  );
                              if (verified && context.mounted) {
                                await _updateInvestorDocuments(investor);
                              }
                            } else if (value == 'delete') {
                              final currentUser =
                                  Supabase.instance.client.auth.currentUser;

                              _showDeleteInvestorDialog(
                                context,
                                investor,
                                currentUser,
                              );
                            } else if (value == 'pdf') {
                              _generateCustomerPdf(investor);
                            }
                          },
                        ),
                      ],
                    ),
                    // Additional Info
                    // SizedBox(height: 1.h),
                    // _buildInfoRow(
                    //   'Invested',
                    //   '${investor.initialInvestmentAmount.toStringAsFixed(2)}',
                    // ),
                    // _buildInfoRow(
                    //   'Balance',
                    //   '${investor.unpaidProfitBalance.toStringAsFixed(2)}',
                    // ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  final Uuid uuid = Uuid(); // Add this
  void _showAddInvestorDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final _uuid = Uuid();
    final Map<String, dynamic> formData = {
      'name': '',
      'idCode': '',
      'investment': 0.0,
      'balance_amount': 0.0,
      'investmen_date': DateTime.now(),
      'end_date': DateTime.now().add(const Duration(days: 90)), // Add default
      'calcType': 'approx',
      'profitValue': 0.0,
      // 'effectiveAfter': 0,
      'profit_duration': 0,
      'phone': '',
      'cnic': '',
      'email': '',
      'address': '',
    };

    final startDateController = TextEditingController(
      text: DateFormat(
        'yyyy-MM-dd',
      ).format(formData['investmentDate'] as DateTime? ?? DateTime.now()),
    );

    final endDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(
        formData['end_date'] as DateTime? ??
            DateTime.now().add(const Duration(days: 180)),
      ),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Investor'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    _buildFormField(
                      label: 'Name *',
                      onSaved: (v) => formData['name'] = v!,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    _buildFormField(
                      label: 'Investor ID *',
                      onSaved: (v) => formData['idCode'] = v!,
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),

                    _buildFormField(
                      label: 'Phone *',
                      onSaved: (v) => formData['phone'] = v!,
                      validator: (v) => v!.length < 11 ? 'Invalid phone' : null,
                    ),
                    _buildFormField(
                      label: 'CNIC *',
                      onSaved: (v) => formData['cnic'] = v!,
                      validator: (v) => v!.length != 13 ? 'Invalid CNIC' : null,
                    ),
                    _buildFormField(
                      label: 'Email',
                      onSaved: (v) => formData['email'] = v ?? '',
                    ),
                    _buildFormField(
                      label: 'Address',
                      onSaved: (v) => formData['address'] = v ?? '',
                    ),

                    _buildFormField(
                      label: 'Investment Amount *',
                      keyboardType: TextInputType.number,
                      onSaved:
                          (v) =>
                              formData['investment'] =
                                  double.tryParse(v!) ?? 0.0,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final value = double.tryParse(v);
                        if (value == null) return 'Must be a number';
                        if (value <= 0) return 'Must be greater than 0';
                        return null;
                      },
                    ),
                    // _buildFormField(
                    //   label: 'Balance Amount *',
                    //   keyboardType: TextInputType.number,
                    //   onSaved:
                    //       (v) => formData['balance_amount'] = double.parse(v!),
                    //   validator: (v) => v!.isEmpty ? 'Required' : null,
                    // ),
                    _buildDateField(
                      context,
                      label: 'Start Date *',
                      controller: startDateController,
                      initialDate: formData['investmentDate'],
                      onSaved: (v) => formData['investmentDate'] = v!,
                    ),
                    _buildDateField(
                      context,
                      label: 'End Date *',
                      controller: endDateController,
                      initialDate: formData['end_date'],
                      onSaved: (v) => formData['end_date'] = v!,
                    ),
                    // const Divider(),
                    // const Text(
                    //   'Profit Schedule Configuration',
                    //   style: TextStyle(fontWeight: FontWeight.bold),
                    // ),
                    // DropdownButtonFormField<String>(
                    //   value: 'percentage',
                    //   items: const [
                    //     DropdownMenuItem(
                    //       value: 'fixed',
                    //       child: Text('Fixed Amount'),
                    //     ),
                    //     DropdownMenuItem(
                    //       value: 'percentage',
                    //       child: Text('Percentage'),
                    //     ),
                    //   ],
                    //   onChanged: (v) => formData['calcType'] = v,
                    //   decoration: const InputDecoration(
                    //     labelText: 'Calculation Type *',
                    //   ),
                    // ),
                    _buildFormField(
                      label: 'Profit Value(Approx)*',
                      keyboardType: TextInputType.number,
                      onSaved:
                          (v) =>
                              formData['profitValue'] =
                                  double.tryParse(v!) ?? 0.0,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final value = double.tryParse(v);
                        if (value == null) return 'Must be a number';
                        if (value <= 0) return 'Must be greater than 0';
                        return null;
                      },
                    ),
                    // _buildFormField(
                    //   label: 'Effective After (Months) *',
                    //   keyboardType: TextInputType.number,
                    //   onSaved:
                    //       (v) => formData['effectiveAfter'] = int.parse(v!),
                    //   validator: (v) => v!.isEmpty ? 'Required' : null,
                    // ),
                    _buildFormField(
                      label: 'Profit Duration *',
                      keyboardType: TextInputType.number,
                      onSaved:
                          (v) =>
                              formData['profit_duration'] =
                                  int.tryParse(v!) ?? 1,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final value = int.tryParse(v);
                        if (value == null) return 'Must be a whole number';
                        if (value <= 0) return 'Must be greater than 0';
                        return null;
                      },
                    ),

                    _buildFormField(
                      label: 'Agreement Time Duration *',
                      keyboardType: TextInputType.number,
                      onSaved:
                          (v) =>
                              formData['time_duration'] = int.tryParse(v!) ?? 6,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final value = int.tryParse(v);
                        if (value == null) return 'Must be a whole number';
                        if (value <= 0) return 'Must be greater than 0';
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
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    formKey.currentState!.save();

                    // Debug: Print all form values
                    formData.forEach((key, value) {});

                    final investorProvider = context.read<InvestorProvider>();
                    final loadingProvider = context.read<LoadingProvider>();
                    final userId = _supabase.auth.currentUser?.id ?? '';
                    final userEmail = _supabase.auth.currentUser?.email ?? '';

                    try {
                      loadingProvider.startLoading();

                      final newInvestor = Investor(
                        id: _uuid.v4(),
                        name: formData['name'] as String,
                        investorIdCode: formData['idCode'] as String,
                        phone: formData['phone'] as String,
                        cnic: formData['cnic'] as String,
                        email: formData['email'] as String? ?? '',
                        address: formData['address'] as String? ?? '',
                        initialInvestmentAmount:
                            (formData['investment'] as num?)?.toDouble() ?? 0.0,
                        investmentDate:
                            formData['investmentDate'] as DateTime? ??
                            DateTime.now(),
                        endDate:
                            formData['end_date'] as DateTime? ??
                            DateTime.now().add(
                              Duration(days: 180),
                            ), // 6 months default
                        profitCalculationType:
                            formData['calcType'] as String? ?? 'approx',
                        profitDuration:
                            (formData['profit_duration'] as num?)?.toInt() ?? 1,
                        timeDuration:
                            (formData['time_duration'] as num?)?.toInt() ?? 6,
                        totalInstallments:
                            (formData['time_duration'] != null &&
                                    formData['profit_duration'] != null)
                                ? (formData['time_duration'] as int) ~/
                                    (formData['profit_duration'] as int)
                                : 0,
                        paidInstallments: {},
                        unpaidProfitBalance:
                            (formData['investment'] != null &&
                                    formData['profit_duration'] != null &&
                                    formData['time_duration'] != null)
                                ? (formData['investment'] as double) *
                                    ((formData['profit_duration'] as int) /
                                        (formData['time_duration'] as int))
                                : 0.0,
                        profitValue:
                            (formData['profitValue'] as num?)?.toDouble() ??
                            0.0,
                        isProfitPaidForCycle: false,
                        status: 'active',
                        createdBy: userId,
                        editedBy: '',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                        profitSchedules: [
                          ProfitSchedule(
                            id: _uuid.v4(),
                            calculationType:
                                formData['calcType'] as String? ?? 'approx',
                            value:
                                (formData['profitValue'] as num?)?.toDouble() ??
                                0.0,
                            profitDuration:
                                (formData['profit_duration'] as num?)
                                    ?.toInt() ??
                                1,
                            agreementDuration:
                                (formData['time_duration'] as num?)?.toInt() ??
                                6,
                            isActive: true,
                          ),
                        ],
                      );
                      await investorProvider.addInvestor(newInvestor, context);

                      if (context.mounted) {
                        Navigator.pop(context);
                        SupabaseExceptionHandler.showSuccessSnackbar(
                          context,
                          'Investor added successfully',
                        );
                      }
                    } catch (e) {
                      loadingProvider.stopLoading();

                      if (context.mounted) {
                        SupabaseExceptionHandler.showErrorSnackbar(
                          context,
                          SupabaseExceptionHandler.handleSupabaseError(e),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        loadingProvider.stopLoading();
                      }
                    }
                  }
                },
                child: const Text('Add Investor'),
              ),
            ],
          ),
    );
  }

  Widget _buildFormField({
    TextEditingController? controller,
    IconData? icon,
    required String label,
    FormFieldSetter<String>? onSaved,
    FormFieldValidator<String>? validator,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,

          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        onSaved: onSaved,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context, {
    required String label,
    TextEditingController? controller,
    required FormFieldSetter<DateTime> onSaved,
    DateTime? initialDate,
  }) {
    controller ??= TextEditingController();
    if (initialDate != null) {
      controller.text = DateFormat('yyyy-MM-dd').format(initialDate);
    }

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        readOnly: true,
        onTap: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: initialDate ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (date != null) {
            controller!.text = DateFormat('yyyy-MM-dd').format(date);
            onSaved(date);
          }
        },
      ),
    );
  }

  void _handleInvestorStatusChange(Investor investor) async {
    final verified = await AdminVerification.showVerificationDialog(
      context: context,
      action:
          '${investor.status == 'active' ? 'deactivate' : 'activate'} investor ${investor.name}',
    );

    if (verified && context.mounted) {
      final newStatus = investor.status == 'active' ? 'inactive' : 'active';
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Confirm Status Change'),
              content: Text(
                'Do you want to ${newStatus == 'active' ? 'activate' : 'deactivate'} ${investor.name.toString().toUpperCase()}?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
      );

      if (confirmed == true) {
        try {
          final provider = Provider.of<InvestorProvider>(
            context,
            listen: false,
          );
          await provider.updateStatus(
            investor: investor,
            newStatus: newStatus,
            expireDate: newStatus == 'inactive' ? DateTime.now() : null,
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Status updated to ${newStatus}')),
            );
            _fetchCustomers();
          }
        } catch (e) {
          if (context.mounted) {
            SupabaseExceptionHandler.showErrorSnackbar(
              context,
              'Error updating status: ${e.toString()}',
            );
          }
        }
      }
    }
  }

  void _showEditInvestorDialog(
    BuildContext context,
    Investor customer,
    User? user,
  ) async {
    final customerProvider = Provider.of<InvestorProvider>(
      context,
      listen: false,
    );

    // Verify admin first
    // final verified = await customerProvider.verifyAdmin(context);
    // if (!verified) return;
    // Controllers with existing values
    final nameController = TextEditingController(text: customer.name);
    final cnicController = TextEditingController(text: customer.cnic);
    final phoneController = TextEditingController(text: customer.phone);
    final emailController = TextEditingController(text: customer.email);
    final addressController = TextEditingController(text: customer.address);
    // final idCodeController = TextEditingController(text: customer.investorIdCode);
    final investmentAmountController = TextEditingController(
      text: customer.initialInvestmentAmount.toStringAsFixed(0),
    );
    final profitValueController = TextEditingController(
      text: customer.profitValue.toStringAsFixed(0),
    );
    final investmentDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(customer.investmentDate),
    );
    final endDateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(customer.endDate),
    );

    String selectedCalcType = customer.profitCalculationType;

    final profitDurationController = TextEditingController(
      text: customer.profitDuration.toString(),
    );
    final timeDurationController = TextEditingController(
      text: customer.timeDuration.toString(),
    );

    // Fetch current user name from profiles table
    String currentUserName = 'Unknown';
    if (user != null) {
      try {
        final profile =
            await Supabase.instance.client
                .from('profiles')
                .select('full_name')
                .eq('user_id', user.id)
                .single();

        currentUserName = profile['full_name'] ?? 'Unknown';
      } catch (e) {
        // Fallback to email if name not found
        currentUserName = user.email?.split('@').first ?? 'Unknown';
      }
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Investor'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildFormField(
                    controller: nameController,
                    label: 'Name',
                    icon: Icons.person,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _buildFormField(
                    controller: cnicController,
                    label: 'CNIC',
                    icon: Icons.credit_card,
                    validator: (v) => v!.length != 13 ? 'Invalid CNIC' : null,
                  ),
                  _buildFormField(
                    controller: phoneController,
                    label: 'Phone',
                    icon: Icons.phone,
                    validator: (v) => v!.length < 11 ? 'Invalid phone' : null,
                  ),
                  _buildFormField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email,
                  ),

                  _buildFormField(
                    controller: addressController,
                    label: 'Address',
                  ),
                  _buildFormField(
                    controller: investmentAmountController,
                    label: 'Investment Amount *',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  _buildDateField(
                    context,
                    controller: investmentDateController,
                    label: 'Investment Date *',
                    onSaved: (DateTime? newValue) {},
                  ),
                  _buildDateField(
                    context,
                    controller: endDateController,
                    label: 'End Date *',
                    onSaved: (DateTime? newValue) {},
                  ),
                  // DropdownButtonFormField<String>(
                  //   value: selectedCalcType,
                  //   items: const [
                  //     DropdownMenuItem(
                  //       value: 'fixed',
                  //       child: Text('Fixed Amount'),
                  //     ),
                  //     DropdownMenuItem(
                  //       value: 'approx',
                  //       child: Text('Percentage'),
                  //     ),
                  //   ],
                  //   onChanged: (v) => selectedCalcType = v!,
                  //   decoration: const InputDecoration(
                  //     labelText: 'Calculation Type *',
                  //   ),
                  // ),
                  _buildFormField(
                    controller: profitValueController,
                    label: 'Profit Value *',
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),

                  _buildFormField(
                    controller: profitDurationController,
                    label: 'Profit Duration (months) *',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final value = int.tryParse(v);
                      if (value == null) return 'Must be a whole number';
                      if (value <= 0) return 'Must be greater than 0';
                      return null;
                    },
                  ),

                  _buildFormField(
                    controller: timeDurationController,
                    label: 'Total Agreement Duration (months) *',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      final value = int.tryParse(v);
                      if (value == null) return 'Must be a whole number';
                      if (value <= 0) return 'Must be greater than 0';
                      // Add validation to ensure it's a multiple of profit duration
                      final profitDuration =
                          int.tryParse(profitDurationController.text) ?? 1;
                      if (value % profitDuration != 0) {
                        return 'Must be a multiple of profit duration';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              // Update your edit dialog's save button
              ElevatedButton(
                onPressed: () async {
                  // Parse dates from controllers
                  final investmentDate = DateFormat(
                    'yyyy-MM-dd',
                  ).parse(investmentDateController.text);
                  final endDate = DateFormat(
                    'yyyy-MM-dd',
                  ).parse(endDateController.text);

                  // Parse numeric values
                  final investmentAmount =
                      double.tryParse(investmentAmountController.text) ?? 0;
                  final profitValue =
                      double.tryParse(profitValueController.text) ?? 0;
                  final profitDuration =
                      int.tryParse(profitDurationController.text) ?? 1;
                  final timeDuration =
                      int.tryParse(timeDurationController.text) ?? 6;

                  debugPrint('Parsed values:');
                  debugPrint('Investment Amount: $investmentAmount');
                  debugPrint('Investment Date: $investmentDate');
                  debugPrint('End Date: $endDate');

                  final updatedInvestor = customer
                      .updateAgreementDetails(
                        newProfitValue: profitValue,
                        newTimeDuration: timeDuration,
                        newProfitDuration: profitDuration,
                      )
                      .copyWith(
                        name: nameController.text,
                        cnic: cnicController.text,
                        phone: phoneController.text,
                        email: emailController.text,
                        address: addressController.text,
                        initialInvestmentAmount: investmentAmount,
                        profitValue: profitValue,
                        investmentDate: investmentDate,
                        endDate: endDate,
                        profitCalculationType: selectedCalcType,
                        editedBy: currentUserName,
                      );

                  debugPrint('Updated Investor before save:');
                  debugPrint(updatedInvestor.toString());

                  try {
                    await customerProvider.editWithVerification(
                      originalInvestor: updatedInvestor,
                      context: context,
                    );
                    Navigator.pop(context);
                    SupabaseExceptionHandler.showSuccessSnackbar(
                      context,
                      'Successfully Updated',
                    );
                  } catch (e) {
                    debugPrint('Error updating investor: $e');
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Failed to Update: ${e.toString()}',
                    );
                  }
                },
                child: const Text('Save Changes'),
              ),
            ],
          ),
    );
  }

  void _showDeleteInvestorDialog(
    BuildContext context,
    Investor customer,
    User? user,
  ) async {
    final customerProvider = Provider.of<InvestorProvider>(
      context,
      listen: false,
    );

    // Verify admin first
    // final verified = await customerProvider.verifyAdmin(context);
    // // if (!verified) return;

    // // Fetch current user name for audit trail
    String currentUserName = 'Unknown';
    // if (user != null) {
    //   try {
    //     final profile =
    //         await Supabase.instance.client
    //             .from('profiles')
    //             .select('name')
    //             .eq('user_id', user.id)
    //             .single();

    //     currentUserName = profile['name'] ?? 'Unknown';
    //   } catch (e) {
    //     print('Error fetching user profile: $e');
    //     currentUserName = user.email?.split('@').first ?? 'Unknown';
    //   }
    // }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Investor'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('You are about to delete:'),
                SizedBox(height: 10),
                Text(
                  'Name: ${customer.name}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('CNIC: ${customer.cnic}'),
                SizedBox(height: 20),
                Text(
                  'This action cannot be undone!',
                  style: TextStyle(color: Colors.red),
                ),
                SizedBox(height: 10),
                Text(
                  'Deleted by: $currentUserName',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await customerProvider.deleteWithVerification(
                      investorId: customer.id,
                      context: context,
                      deletedBy: currentUserName,
                    );
                    Navigator.pop(context);
                    SupabaseExceptionHandler.showSuccessSnackbar(
                      context,
                      '${customer.name.toString().toUpperCase()} successfully deleted',
                    );
                  } catch (e) {
                    SupabaseExceptionHandler.showErrorSnackbar(
                      context,
                      'Deletion failed: ${e.toString()}',
                    );
                    Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm Delete'),
              ),
            ],
          ),
    );
  }

  void _showInvestorsDetailsDialog(BuildContext context, Investor customer) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.sp),
            ),
            child: Container(
              width: 50.sw,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blueGrey[50]!,
                    Colors.blueGrey[50]!,
                    Color.fromARGB(255, 194, 174, 106),
                    const Color.fromARGB(255, 157, 167, 172)!,
                    const Color.fromARGB(255, 157, 167, 172)!,
                  ],
                ),
                borderRadius: BorderRadius.circular(16.sp),
              ),
              padding: EdgeInsets.all(4.w),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 22.sp,
                      backgroundColor: Colors.white,
                      child: Text(
                        customer.name.isNotEmpty
                            ? customer.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[800],
                        ),
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[900],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    _buildDetailRow('Investor ID:', customer.investorIdCode),
                    _buildDetailRow('CNIC:', customer.cnic),
                    _buildDetailRow('Phone:', customer.phone),
                    _buildDetailRow('Email:', customer.email ?? 'N/A'),
                    _buildDetailRow('Address:', customer.address ?? 'N/A'),
                    _buildDetailRow(
                      'Investment Amount:',
                      '${customer.initialInvestmentAmount.toStringAsFixed(0)}',
                    ),
                    _buildDetailRow(
                      'Agreement Duration:',
                      '${customer.timeDuration} months',
                    ),
                    _buildDetailRow(
                      'Created on:',
                      DateFormat(
                        'MMMM d, y - h:mm a',
                      ).format(customer.createdAt),
                    ),
                    FutureBuilder(
                      future:
                          Supabase.instance.client
                              .from('profiles')
                              .select('name')
                              .eq('user_id', customer.createdBy)
                              .maybeSingle(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildDetailRow('Created by:', 'Loading...');
                        }
                        if (snapshot.hasError) {
                          return _buildDetailRow('Created by:', 'Unknown');
                        }
                        final data = snapshot.data;
                        final name =
                            data != null &&
                                    data['name'] != null &&
                                    data['name'].toString().isNotEmpty
                                ? data['name'].toString()
                                : 'Unknown';
                        return _buildDetailRow(
                          'Created by:',
                          name.toString().toUpperCase(),
                        );
                      },
                    ),
                    _buildDetailRow(
                      'Last edited by:',
                      customer.editedBy.isNotEmpty
                          ? customer.editedBy[0].toUpperCase() +
                              customer.editedBy.substring(1)
                          : 'Not edited',
                    ),
                    SizedBox(height: 2.h),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.sp),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 6.w,
                          vertical: 1.5.h,
                        ),
                      ),
                      child: Text('Close', style: TextStyle(fontSize: 12.sp)),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        // crossAxisAlignment: CrossAxisAlignment.,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 2.w),
          Text(
            value ?? 'Not available',
            style: TextStyle(fontSize: 12.sp, color: Colors.black),
          ),
        ],
      ),
    );
  }

  void _showPayoutDialog(BuildContext context, Investor investor) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Process Payout'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Available Balance: ${investor.unpaidProfitBalance.toStringAsFixed(0)}',
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  items: const [
                    DropdownMenuItem(value: 'full', child: Text('Full Payout')),
                    DropdownMenuItem(
                      value: 'partial',
                      child: Text('Partial Payout'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == 'full') {
                      amountController.text = investor.unpaidProfitBalance
                          .toStringAsFixed(0);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount > 0 && amount <= investor.unpaidProfitBalance) {
                    context.read<InvestorProvider>().processPayout(
                      investorId: investor.id,
                      amount: amount,
                      payoutType:
                          amount == investor.unpaidProfitBalance
                              ? 'full_accrued_payout'
                              : 'partial_payout',
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.008.h), // Increased by 20% more
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 15.84.sp,
            color: Colors.white70,
          ), // Increased by 20% more
          SizedBox(width: 3.168.w), // Increased by 20% more
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.08.sp, // Increased by 20% more
                    color: Colors.white70,
                  ),
                ),
                SizedBox(height: 0.5544.h), // Increased by 20% more
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.856.sp, // Increased by 20% more

                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _generateCustomerPdf(Investor investor) async {
    final pdf = pw.Document();
    final currencyFormat = NumberFormat("#,##0.00");
    final dateFormat = DateFormat('dd-MMM-yyyy');

    // Helper functions
    String formatAmount(double amount) => '${currencyFormat.format(amount)}';
    String formatDate(DateTime date) => dateFormat.format(date);
    String safeDate(DateTime? date) => date != null ? formatDate(date) : 'N/A';

    // Calculate installments
    final totalMonths = investor.timeDuration;
    final interval = investor.profitDuration;
    final totalInstallments = totalMonths! ~/ interval;
    final monthlyProfit = _calculateMonthlyProfit(investor);

    // Add return transactions table if any returns exist
    final returns = await _supabase
        .from('return_transactions')
        .select()
        .eq('investor_id', investor.id);

    // Get all unique processed_by UIDs
    final processedByUids =
        returns
            .map((t) => t['processed_by']?.toString())
            .whereType<String>()
            .toSet()
            .toList();

    // Fetch profiles for these UIDs
    final profiles =
        processedByUids.isNotEmpty
            ? await _supabase
                .from('profiles')
                .select()
                .inFilter('user_id', processedByUids)
            : [];

    // Create a map of UID to profile name
    final profileMap = {
      for (var profile in profiles)
        profile['user_id']: '${profile['name'] ?? ''}'.trim(),
    };

    try {
      pdf.addPage(
        pw.Page(
          margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header Section
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'RELIABLE MARKETING NETWORK PVT LTD.',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'A P S',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Investor Account Statement',
                        style: pw.TextStyle(fontSize: 16),
                      ),
                      pw.SizedBox(height: 20),
                    ],
                  ),
                ),

                // Investor Information
                pw.Text(
                  'Investor Information',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1.5),
                    1: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    _buildInfoRow(
                      'Name:',
                      investor.status == 'active'
                          ? investor.name.toString().toUpperCase()
                          : investor.name.toString().toLowerCase() +
                              ' (Inactive)',
                    ),
                    _buildInfoRow('CNIC No.:', investor.cnic),
                    _buildInfoRow('Phone No.:', investor.phone),
                  ],
                ),
                pw.SizedBox(height: 20),

                // File/Plot Information
                pw.Text(
                  'File/Plot Information',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  columnWidths: {
                    0: const pw.FlexColumnWidth(2),
                    1: const pw.FlexColumnWidth(3),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(3),
                  },
                  children: [
                    _buildFilePlotRow(
                      'Investment Amount:',
                      formatAmount(investor.initialInvestmentAmount),
                      'Start Date:',
                      safeDate(investor.investmentDate),
                    ),
                    _buildFilePlotRow(
                      'Time Duration:',
                      investor.timeDuration != null
                          ? '${investor.timeDuration} Months'
                          : 'N/A',
                      'End Date:',
                      safeDate(investor.endDate),
                    ),
                    _buildFilePlotRow(
                      'Profit Duration',
                      investor.profitDuration.toString(),
                      'Monthly Profit:',
                      formatAmount(investor.profitValue) + '  Approx.',
                    ),
                  ],
                ),

                pw.SizedBox(height: 10),

                // Amount Details
                pw.Text(
                  'Amount Details',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Row(
                          children: [
                            pw.Text(
                              'Investment Amount:',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(width: 15),
                            pw.Text(
                              investor.initialInvestmentAmount.toString(),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Return Amount',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(width: 15),
                            pw.Text(
                              investor.returnAmount.toString(),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Text(
                              'Balance Amount',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                            pw.SizedBox(width: 15),
                            pw.Text(
                              investor.balanceAmount.toString(),
                              style: pw.TextStyle(fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Installment Table
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children:
                          [
                            'Sr.No',
                            'Month',
                            'Due Date',
                            'Amount',
                            'Status',
                          ].map((t) => _buildHeaderCell(t)).toList(),
                    ),
                    for (int i = 1; i <= totalInstallments; i++)
                      pw.TableRow(
                        children:
                            [
                                  i.toString(),
                                  'M$i',
                                  dateFormat.format(
                                    _getDueDate(
                                      investor.investmentDate,
                                      i,
                                      interval,
                                    ),
                                  ),
                                  '${NumberFormat.currency(symbol: '', decimalDigits: 0).format(_calculateMonthlyProfit(investor))}', // '${monthlyProfit.toStringAsFixed(0)}',
                                  investor.paidInstallments['m$i'] == true
                                      ? 'Paid'
                                      : 'Pending',
                                ]
                                .map(
                                  (t) => _buildDataCell(
                                    t,
                                    alignment: pw.Alignment.center,
                                  ),
                                )
                                .toList(),
                      ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Add Return Transactions Section
                if (investor.returnAmount > 0)
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 20),
                      pw.Table(
                        border: pw.TableBorder.all(),
                        children: [
                          pw.TableRow(
                            children:
                                [
                                  'Date',
                                  'Processed By',
                                  'Amount',
                                ].map((t) => _buildHeaderCell(t)).toList(),
                          ),
                          ...returns.map((transaction) {
                            final processedByUid =
                                transaction['processed_by']?.toString();
                            final processedByName =
                                processedByUid != null
                                    ? profileMap[processedByUid] ?? 'Unknown'
                                    : 'N/A';

                            return pw.TableRow(
                              children:
                                  [
                                        safeDate(
                                          transaction['return_date'] != null
                                              ? DateTime.parse(
                                                transaction['return_date'],
                                              )
                                              : null,
                                        ),
                                        processedByName,
                                        currencyFormat.format(
                                          transaction['amount'] ?? 0,
                                        ),
                                      ]
                                      .map(
                                        (t) => _buildDataCell(
                                          t,
                                          alignment: pw.Alignment.center,
                                        ),
                                      )
                                      .toList(),
                            );
                          }).toList(),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      pw.Table(
                        border: pw.TableBorder.all(
                          color: PdfColors.black,
                          width: 1,
                        ),
                        columnWidths: {
                          0: const pw.FlexColumnWidth(2),
                          1: const pw.FlexColumnWidth(2),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                alignment: pw.Alignment.center,
                                child: pw.Text(
                                  'Total Returns:',
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              pw.Container(
                                padding: const pw.EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 10,
                                ),
                                alignment: pw.Alignment.center,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border(
                                    left: pw.BorderSide(
                                      color: PdfColors.grey700,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: pw.Text(
                                  currencyFormat.format(investor.returnAmount),
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.normal,
                                    fontSize: 12,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                    ],
                  ),

                // Spacer to push the footer to the bottom
                pw.Spacer(),

                // Footer aligned at the page end
                pw.Align(
                  alignment: pw.Alignment.bottomRight,
                  child: pw.Text(
                    'Generated at: ${DateTime.now().toString()}',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Save PDF
      final directory = await getDownloadsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = investor.name.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final filePath = '${directory!.path}/${cleanName}_$timestamp.pdf';

      await File(filePath).writeAsBytes(await pdf.save());

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('PDF saved to: $filePath')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _generateInvestorDocumentsPdf(Investor investor) async {
    final loadingProvider = Provider.of<LoadingProvider>(
      context,
      listen: false,
    );
    loadingProvider.startLoading();

    try {
      // Fetch all documents for this investor
      final response = await _supabase
          .from('investor_documents')
          .select()
          .eq('investor_id', investor.id)
          .order('created_at');

      final documents = List<Map<String, dynamic>>.from(response);

      if (documents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No documents found for this investor')),
        );
        return;
      }

      // Create PDF
      final pdf = pw.Document();
      final investorName = investor.name ?? 'Investor';

      // Add cover page
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'Documents for $investorName',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 40),
                pw.Text(
                  'Total Documents: ${documents.length}',
                  style: pw.TextStyle(fontSize: 16),
                ),
              ],
            );
          },
        ),
      );

      // Process each document
      for (var doc in documents) {
        final mimeType = lookupMimeType(doc['document_name'] ?? '') ?? '';
        final docName = doc['document_name'] ?? 'Document';
        final docUrl = doc['document_url'];

        if (mimeType.startsWith('image/')) {
          try {
            final imageBytes = await _downloadFile(docUrl);
            if (imageBytes != null) {
              final image = pw.MemoryImage(imageBytes);
              pdf.addPage(
                pw.Page(
                  build:
                      (context) => pw.Column(
                        children: [
                          pw.Text(
                            docName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.SizedBox(height: 20),
                          pw.Expanded(
                            child: pw.Image(image, fit: pw.BoxFit.contain),
                          ),
                        ],
                      ),
                ),
              );
            }
          } catch (e) {
            pdf.addPage(
              pw.Page(
                build:
                    (context) => pw.Column(
                      children: [
                        pw.Text(
                          docName,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 20),
                        pw.Text('Failed to load image'),
                      ],
                    ),
              ),
            );
          }
        } else if (mimeType == 'application/pdf') {
          // For PDFs, we'll just list them since embedding is problematic
          pdf.addPage(
            pw.Page(
              build:
                  (context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        docName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text('PDF document (cannot be embedded)'),
                      pw.SizedBox(height: 10),
                      pw.Text('Document URL: $docUrl'),
                    ],
                  ),
            ),
          );
        } else {
          // For other file types
          pdf.addPage(
            pw.Page(
              build:
                  (context) => pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        docName,
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 20),
                      pw.Text('File type: $mimeType'),
                      pw.SizedBox(height: 10),
                      pw.Text('Document URL: $docUrl'),
                    ],
                  ),
            ),
          );
        }
      }

      // Save PDF to downloads
      final dir = await getDownloadsDirectory();
      if (dir == null) throw Exception('Could not access downloads directory');

      final fileName =
          '${investorName.replaceAll(' ', '_')}_Documents_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final filePath = path.join(dir.path, fileName);
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      // Open the PDF
      OpenFile.open(filePath);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF saved to Downloads: $fileName')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate PDF: $e')));
    } finally {
      loadingProvider.stopLoading();
    }
  }

  // Add this helper method for downloading files
  Future<Uint8List?> _downloadFile(String url) async {
    try {
      final httpClient = HttpClient();
      final request = await httpClient.getUrl(Uri.parse(url));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        return await consolidateHttpClientResponseBytes(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  DateTime _getDueDate(DateTime startDate, int installment, int interval) {
    return DateTime(
      startDate.year,
      startDate.month + (installment * interval),
      startDate.day,
    );
  }

  double _calculateMonthlyProfit(Investor investor) {
    // Simply return the manually entered profit value
    return investor.profitValue;
  }

  // Helper functions
  pw.TableRow _buildInfoRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value, style: pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  pw.TableRow _buildFilePlotRow(
    String label1,
    String value1,
    String label2,
    String value2,
  ) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            label1,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value1, style: pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(
            label2,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Text(value2, style: pw.TextStyle(fontSize: 8)),
        ),
      ],
    );
  }

  pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Center(
        child: pw.Text(
          text,
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ),
    );
  }

  pw.Widget _buildDataCell(String text, {pw.Alignment? alignment}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Align(
        alignment: alignment ?? pw.Alignment.centerLeft,
        child: pw.Text(text),
      ),
    );
  }

  // // Update helper functions
  // // Updated helper functions
  // double _calculateReturnAmount(Investor investor) {
  //   return investor.profitSchedules.fold(0.0, (sum, schedule) {
  //     final amount =
  //         schedule!.calculationType == 'percentage'
  //             ? investor.initialInvestmentAmount * (schedule.value / 100)
  //             : schedule.value;
  //     return sum + amount;
  //   });
  // }

  // String _getProfitMonth(int effectiveMonths) {
  //   return 'Month $effectiveMonths';
  // }
}
