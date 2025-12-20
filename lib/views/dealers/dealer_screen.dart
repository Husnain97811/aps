import 'dart:io';

import 'package:aps/config/view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shimmer/shimmer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DealerScreen extends StatefulWidget {
  const DealerScreen({super.key});

  @override
  State<DealerScreen> createState() => _DealerScreenState();
}

class _DealerScreenState extends State<DealerScreen> {
  final supabase = Supabase.instance.client;

  final DealerService _dealerService = DealerService();
  late Future<List<Map<String, dynamic>>> _dealersFuture;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() async {
    setState(() {
      _dealersFuture = _dealerService.getDealers();
    });
  }

  Future<void> _showAddDealerDialog() async {
    final provider = Provider.of<DealerProvider>(context, listen: false);
    provider.startLoading();
    try {
      final newDealerNo = await _dealerService.generateNewDealerNo();
      provider.stopLoading();

      final formKey = GlobalKey<FormState>();
      TextEditingController nameController = TextEditingController();
      TextEditingController phoneController = TextEditingController();
      TextEditingController addressController = TextEditingController();
      TextEditingController cnicController = TextEditingController();

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text(
                'Add New Dealer',
                style: TextStyle(color: Colors.black),
              ),
              backgroundColor: Colors.white,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20,
              ), // Reduces padding around the dialog
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ), // Adjust content padding
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    // Constrain the width
                    width:
                        MediaQuery.of(context).size.width *
                        0.8, // 80% of screen width
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildDisabledField('Dealer Number', newDealerNo),
                        _buildDisabledField(
                          'Date',
                          DateTime.now().toString().split(' ')[0],
                        ),
                        const SizedBox(height: 20),
                        _buildTextFormField(
                          nameController,
                          'Name',
                          Icons.person,
                        ),
                        _buildTextFormField(
                          phoneController,
                          'Phone',
                          Icons.phone,
                        ),
                        _buildTextFormField(
                          addressController,
                          'Address',
                          Icons.location_on,
                        ),
                        _buildTextFormField(
                          cnicController,
                          'cnic',
                          Icons.document_scanner_outlined,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      provider.isDisabled ? null : () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
                ElevatedButton(
                  onHover: (value) {
                    ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttoncolor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      minimumSize: const Size(120, 50), // Wider button
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 208, 217, 224),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    minimumSize: const Size(120, 50), // Wider button
                  ),
                  onPressed:
                      provider.isDisabled
                          ? null
                          : () async {
                            final userId = supabase.auth.currentUser!.id;
                            final userName =
                                await supabase
                                    .from('profiles')
                                    .select('full_name')
                                    .eq('id', userId)
                                    .maybeSingle();

                            if (formKey.currentState!.validate()) {
                              setState(() => _isAdding = true);
                              try {
                                await _dealerService.addDealer({
                                  'dealer_no': newDealerNo.toLowerCase(),
                                  'name': nameController.text.toLowerCase(),
                                  'phone': phoneController.text,
                                  'address':
                                      addressController.text.toLowerCase(),
                                  'dealer_cnic': cnicController.text,
                                  'created_at':
                                      DateTime.now().toIso8601String(),
                                  'created_by':
                                      userName?['full_name'].toString(),
                                });
                                _refreshData();
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Dealer added successfully!'),
                                  ),
                                );
                              } catch (e) {
                                final errorMessage =
                                    SupabaseExceptionHandler.handleSupabaseError(
                                      e,
                                    );
                                SupabaseExceptionHandler.showErrorSnackbar(
                                  context,
                                  errorMessage,
                                );
                              } finally {
                                setState(() => _isAdding = false);
                              }
                            }
                          },
                  child:
                      _isAdding
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                            'Add Dealer',
                            style: TextStyle(color: Colors.white),
                          ),
                ),
              ],
            ),
      );
    } catch (e) {
      provider.stopLoading();
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    }
  }

  Widget _buildDisabledField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Container(
            width: double.infinity, // Full width of parent
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(value, style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFormField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.black),
        decoration: InputDecoration(
          isDense: true, // Reduces internal padding for a compact look
          contentPadding: const EdgeInsets.all(14), // Adjust padding
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black54),
          prefixIcon: Icon(icon, color: Colors.black54),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actionsPadding: EdgeInsets.only(right: 12.sp),
        title: const Text(
          'Dealer Management',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Generate All Dealers PDF',
            icon: Icon(
              Icons.picture_as_pdf_rounded,
              // color: Colors.blue,
              size: 17.sp,
            ),
            onPressed: _generateAllDealersWithClientsPdf,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshData, // Refresh the dealer list
          ),
        ],
        centerTitle: true,
        backgroundColor: AppColors.darkbrown,
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'addDealer',
        onPressed: _showAddDealerDialog,
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.rmncolorlight),
        child: Column(
          children: [
            // Search Bar at the top of the body
            Padding(
              padding: const EdgeInsets.all(16),
              child: Consumer<DealerProvider>(
                builder:
                    (context, provider, _) => TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by Name or Dealer No...',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.grey[200],
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      onChanged: (value) => provider.setSearchQuery(value),
                    ),
              ),
            ),
            // Dealer List
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(),
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _dealersFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildShimmerEffect();
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error),

                                Text(
                                  textAlign: TextAlign.center,
                                  'Connetivity Problem ! \n Please refresh or restart your software or internet!',
                                  style: TextStyle(fontSize: 15.sp),
                                ),
                              ],
                            ),
                          );
                        }
                        final dealers = snapshot.data!;
                        return _buildDealerList(dealers);
                      },
                    ),
                  ),
                  Consumer<DealerProvider>(
                    builder: (context, provider, _) {
                      return provider.isLoading
                          ? const Center(child: ProviderLoadingWidget())
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // widget for shimmer effect
  Widget _buildShimmerEffect() {
    return Shimmer.fromColors(
      baseColor: Colors.blueGrey[800]!,
      highlightColor: Colors.blueGrey[600]!,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder:
            (_, __) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
                borderRadius: BorderRadius.circular(15),
              ),
              height: 100,
            ),
      ),
    );
  }

  // function for updating daelaer
  void _editDealer(Map<String, dynamic> dealer) async {
    final provider = Provider.of<DealerProvider>(context, listen: false);
    final formKey = GlobalKey<FormState>();
    TextEditingController nameController = TextEditingController(
      text: dealer['name'],
    );
    TextEditingController phoneController = TextEditingController(
      text: dealer['phone'],
    );
    TextEditingController addressController = TextEditingController(
      text: dealer['address'],
    );
    TextEditingController cnicController = TextEditingController(
      text: dealer['dealer_cnic'],
    );

    await showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(20),
            child: Container(
              width: Adaptive.w(50),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color.fromARGB(107, 44, 33, 17).withOpacity(0.9),
                    const Color.fromARGB(48, 208, 148, 59),
                    const Color.fromARGB(177, 172, 124, 53).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with decorative elements
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.white54, thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Edit Dealer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.white54, thickness: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25),

                      // Form Fields
                      _buildStyledFormField(
                        controller: nameController,
                        label: 'Name',
                        icon: Icons.person_outline,
                        iconColor: Colors.amber[100],
                      ),
                      const SizedBox(height: 18),
                      _buildStyledFormField(
                        controller: phoneController,
                        label: 'Phone',
                        icon: Icons.phone_iphone_rounded,
                        iconColor: Colors.cyan[100],
                      ),
                      const SizedBox(height: 18),
                      _buildStyledFormField(
                        controller: addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        iconColor: Colors.green[100],
                      ),
                      SizedBox(height: 18),
                      _buildStyledFormField(
                        controller: cnicController,
                        label: 'CNIC',
                        icon: Icons.credit_card_rounded,
                        iconColor: Colors.purple[100],
                      ),
                      const SizedBox(height: 30),

                      // Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildDialogButton(
                            text: 'Cancel',
                            color: Colors.transparent,
                            borderColor: Colors.white54,
                            onPressed: () => Navigator.pop(context),
                          ),
                          _buildDialogButton(
                            text: 'Save Changes',
                            color: Colors.white.withOpacity(0.1),
                            gradient: LinearGradient(
                              colors: [
                                Colors.blueAccent,
                                Colors.lightBlue.shade200,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            onPressed: () async {
                              final userId = supabase.auth.currentUser!.id;
                              final userName =
                                  await supabase
                                      .from('profiles')
                                      .select('full_name')
                                      .eq('id', userId)
                                      .maybeSingle();
                              if (formKey.currentState!.validate()) {
                                try {
                                  await _dealerService.updateDealer(
                                    dealer['dealer_no'],
                                    {
                                      'name': nameController.text.toLowerCase(),
                                      'phone': phoneController.text,
                                      'address':
                                          addressController.text.toLowerCase(),
                                      'dealer_cnic': cnicController.text,
                                      'updated_by':
                                          userName?['full_name'].toString(),
                                    },
                                  );
                                  _refreshData();
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Dealer updated successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  final errorMessage =
                                      SupabaseExceptionHandler.handleSupabaseError(
                                        e,
                                      );
                                  SupabaseExceptionHandler.showErrorSnackbar(
                                    context,
                                    errorMessage,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildStyledFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    Color? iconColor,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: iconColor ?? Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white24, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white54, width: 1.5),
        ),
      ),
      validator: (value) => value!.isEmpty ? 'Please enter $label' : null,
    );
  }

  Widget _buildDialogButton({
    required String text,
    required VoidCallback onPressed,
    Color? color,
    Gradient? gradient,
    Color borderColor = Colors.transparent,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          if (gradient != null)
            BoxShadow(
              color: Colors.blue.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          splashColor: Colors.white.withOpacity(0.1),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            child: Text(
              text,
              style: TextStyle(
                color: gradient != null ? Colors.white : Colors.white70,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // widget for showing dealer list

  Widget _buildDealerList(List<Map<String, dynamic>> dealers) {
    return Consumer<DealerProvider>(
      builder: (context, provider, _) {
        final sortedDealers = provider.filterDealers(dealers)
          ..sort((a, b) => a['dealer_no'].compareTo(b['dealer_no']));
        return IgnorePointer(
          ignoring: provider.isDisabled,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: sortedDealers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final dealer = sortedDealers[index];
              return Container(
                decoration: BoxDecoration(
                  color: Colors.blueGrey[800]!.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(9),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent,
                    child: Text(
                      dealer['dealer_no']
                          .toString()
                          .split('-')[1]
                          .replaceAll(RegExp(r'[^0-9]'), ''),
                      style: TextStyle(color: Colors.white, fontSize: 13.sp),
                    ),
                  ),
                  title: Text(
                    dealer['name']
                        .toString()
                        .toLowerCase()
                        .split(' ')
                        .map(
                          (word) =>
                              word.isNotEmpty
                                  ? word[0].toUpperCase() + word.substring(1)
                                  : '',
                        )
                        .join(' '),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Phone: ${dealer['phone']}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                      Text(
                        'CNIC: ${dealer['dealer_cnic']}',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showDealerDetails(dealer),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.picture_as_pdf,
                          color: Colors.blue,
                          size: 17.sp,
                        ),
                        onPressed:
                            () =>
                            // provider.isDisabled
                            //     ? null
                            //     : () =>
                            _generateDealerPdf(dealer),
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.delete, color: Colors.red),
                      //   onPressed: () => _deleteDealer(dealer['dealer_no']),
                      // ),
                      IconButton(
                        icon: Icon(
                          Icons.edit,
                          color: Colors.orange,
                          size: 17.sp,
                        ), // Changed from delete
                        onPressed:
                            () => _editDealer(dealer), // New edit handler
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Function to delete dealer

  Future<void> _deleteDealer(String dealerNo) async {
    final provider = Provider.of<DealerProvider>(context, listen: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Dealer'),
            content: const Text('Are you sure you want to delete this dealer?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      provider.startLoading();
      try {
        await _dealerService.deleteDealer(dealerNo);
        _refreshData();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dealer deleted successfully!')),
        );
      } catch (e) {
        final errorMessage = SupabaseExceptionHandler.handleSupabaseError(
          'Something went wrong contact Administration $e',
        );
        SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
      } finally {
        provider.stopLoading();
      }
    }
  }

  //---------------------------------functions to generate statement of the dealers---------------------------------

  // this method to generate PDF for all dealers
  Future<void> _generateAllDealersWithClientsPdf() async {
    final provider = Provider.of<DealerProvider>(context, listen: false);
    try {
      provider.startLoading();

      // Get all dealers data
      final dealers = await _dealerService.getDealers();

      // Create PDF document
      final pdf = pw.Document();

      // Load logo
      final apldimageBytes = await rootBundle.load(
        'assets/images/logo_reliable.png',
      );
      final logoReliable = pw.MemoryImage(apldimageBytes.buffer.asUint8List());

      // Pre-fetch all clients data for each dealer
      final Map<String, List<Map<String, dynamic>>> dealerClientsMap = {};
      for (var dealer in dealers) {
        final clients = await MembershipService().getMembershipFormsByDealer(
          dealerNo: dealer['dealer_no'],
          refStatus: true,
        );
        dealerClientsMap[dealer['dealer_no']] = clients;
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(20),
          build:
              (context) => [
                // Header with logo and title
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Image(logoReliable, width: 45),
                        pw.SizedBox(width: 8),
                        pw.Row(
                          children: [
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'Reliable Marketing Network',
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ),
                            pw.Container(
                              height: 15,
                              child: pw.Align(
                                alignment: pw.Alignment.bottomRight,
                                child: pw.Text(
                                  'Pvt ltd',
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'All Dealers with Clients Report',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.grey800,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),

                // Dealers list with separate tables
                ...dealers.map((dealer) {
                  final clients = dealerClientsMap[dealer['dealer_no']] ?? [];
                  List<pw.Widget> dealerInfo = [
                    pw.Container(
                      width: double.infinity,
                      padding: pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(5),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Dealer: ${dealer['dealer_no']?.toString().toUpperCase() ?? 'N/A'}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          pw.SizedBox(height: 5),
                          pw.Row(
                            children: [
                              pw.Text(
                                'Name: ${_formatName(dealer['name']?.toString() ?? 'N/A')}',
                                style: pw.TextStyle(fontSize: 10),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                'CNIC: ${dealer['dealer_cnic'] ?? 'N/A'}',
                                style: pw.TextStyle(fontSize: 9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 10),
                  ];

                  if (clients.isEmpty) {
                    dealerInfo.add(
                      pw.Padding(
                        padding: pw.EdgeInsets.only(left: 20, bottom: 15),
                        child: pw.Text(
                          'No clients found for this dealer',
                          style: pw.TextStyle(
                            fontStyle: pw.FontStyle.italic,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    );
                  } else {
                    // Using manual table for better control (same as previous PDF)
                    dealerInfo.add(
                      pw.Table(
                        border: pw.TableBorder.all(width: 0.5),
                        columnWidths: {
                          0: pw.FixedColumnWidth(25), // Sr. No.
                          1: pw.FixedColumnWidth(50), // No. COL
                          2: pw.FixedColumnWidth(55), // Booking Date
                          3: pw.FlexColumnWidth(1.8), // Name
                          4: pw.FixedColumnWidth(70), // Membership No
                          5: pw.FixedColumnWidth(45), // Rebate 1
                          6: pw.FixedColumnWidth(45), // Rebate 2
                          7: pw.FixedColumnWidth(45), // Rebate 3
                          8: pw.FixedColumnWidth(45), // Rebate 4
                          9: pw.FixedColumnWidth(45), // Rebate 5
                        },
                        defaultVerticalAlignment:
                            pw.TableCellVerticalAlignment.middle,
                        children: [
                          // Header Row
                          pw.TableRow(
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey300,
                            ),
                            children: [
                              // Sr. No.
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Sr. No.',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // No. COL
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'No. COL',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Booking Date
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Booking Date',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Name
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Name',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Membership No.
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Membership No.',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Rebate 1
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Rebate 1',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Rebate 2
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Rebate 2',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Rebate 3
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Rebate 3',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Rebate 4
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Rebate 4',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                              // Rebate 5
                              pw.Container(
                                alignment: pw.Alignment.center,
                                padding: pw.EdgeInsets.all(4),
                                child: pw.Text(
                                  'Rebate 5',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  textAlign: pw.TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                          // Data Rows
                          ...List.generate(clients.length, (index) {
                            final client = clients[index];

                            // Helper function to format rebate cell (amount and date merged)
                            pw.Widget formatRebateCell(
                              dynamic amount,
                              dynamic date,
                            ) {
                              final amountValue =
                                  amount?.toString().replaceAll(
                                    RegExp(r'\.0+$'),
                                    '',
                                  ) ??
                                  '0';
                              final dateValue = date?.split('T')[0] ?? '-';

                              return pw.Column(
                                mainAxisAlignment: pw.MainAxisAlignment.center,
                                crossAxisAlignment:
                                    pw.CrossAxisAlignment.center,
                                children: [
                                  pw.Text(
                                    amountValue,
                                    style: pw.TextStyle(fontSize: 7),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                  pw.SizedBox(height: 2),
                                  pw.Text(
                                    dateValue,
                                    style: pw.TextStyle(
                                      fontSize: 6.5,
                                      color: PdfColors.grey600,
                                    ),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ],
                              );
                            }

                            // Format cost of land
                            String formatCostOfLand(dynamic value) {
                              if (value == null) return '';
                              final strValue = value.toString().trim();
                              if (strValue.isEmpty ||
                                  strValue == '0' ||
                                  strValue == 'null') {
                                return '';
                              }
                              // Remove .0 if it's a whole number
                              if (strValue.contains('.') &&
                                  strValue.endsWith('.0')) {
                                return strValue.split('.')[0];
                              }
                              return strValue;
                            }

                            return pw.TableRow(
                              decoration:
                                  index % 2 == 0
                                      ? pw.BoxDecoration(
                                        color: PdfColors.grey100,
                                      )
                                      : null,
                              children: [
                                // Sr. No.
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    '${index + 1}',
                                    style: pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                // No. COL (Cost of Land)
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    formatCostOfLand(client['cost_of_land']),
                                    style: pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                // Booking Date
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    client['date']?.split('T')[0] ?? '-',
                                    style: pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                // Name
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    _formatName(
                                      client['name']?.toString() ?? 'N/A',
                                    ),
                                    style: pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.center,
                                    maxLines: 2,
                                    overflow: pw.TextOverflow.clip,
                                  ),
                                ),
                                // Membership No.
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(4),
                                  child: pw.Text(
                                    client['membership_no']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'N/A',
                                    style: pw.TextStyle(fontSize: 7.5),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                // Rebate 1 (merged amount and date)
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(2),
                                  child: formatRebateCell(
                                    client['rebate1'],
                                    client['rebate1date'],
                                  ),
                                ),
                                // Rebate 2 (merged amount and date)
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(2),
                                  child: formatRebateCell(
                                    client['rebate2'],
                                    client['rebate2date'],
                                  ),
                                ),
                                // Rebate 3 (merged amount and date)
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(2),
                                  child: formatRebateCell(
                                    client['rebate3'],
                                    client['rebate3date'],
                                  ),
                                ),
                                // Rebate 4 (merged amount and date)
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(2),
                                  child: formatRebateCell(
                                    client['rebate4'],
                                    client['rebate4date'],
                                  ),
                                ),
                                // Rebate 5 (merged amount and date)
                                pw.Container(
                                  alignment: pw.Alignment.center,
                                  padding: pw.EdgeInsets.all(2),
                                  child: formatRebateCell(
                                    client['rebate5'],
                                    client['rebate5date'],
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),
                    );

                    dealerInfo.add(pw.SizedBox(height: 10));
                    dealerInfo.add(
                      pw.Container(
                        alignment: pw.Alignment.centerRight,
                        child: pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.Text(
                              'Total Clients: ${clients.length}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(width: 20),
                            pw.Text(
                              'Total Rebate: ${_calculateTotalRebate(clients).toStringAsFixed(2)}',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  dealerInfo.add(pw.SizedBox(height: 20));
                  dealerInfo.add(pw.Divider());
                  dealerInfo.add(pw.SizedBox(height: 20));

                  return pw.Column(children: dealerInfo);
                }).toList(),

                // Summary statistics
                pw.SizedBox(height: 20),
                pw.Container(
                  padding: pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total Dealers: ${dealers.length}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      pw.Text(
                        'Grand Total Rebate: ${_calculateGrandTotalRebate(dealerClientsMap).toStringAsFixed(2)}',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Report generated by Reliable Marketing Network',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Page 1 of 1',
                      style: pw.TextStyle(
                        fontSize: 8,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
        ),
      );

      // Save and open PDF
      final output = await getDownloadsDirectory();
      final file = File('${output!.path}/all_dealers_report.pdf');
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('All dealers report generated successfully')),
      );
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      provider.stopLoading();
    }
  }

  // Helper function to format name with proper casing
  String _formatName(String name) {
    if (name.isEmpty || name == 'N/A') return name;

    // Split by space, capitalize first letter of each word, lowercase the rest
    List<String> words = name.trim().split(' ');
    List<String> formattedWords = [];

    for (String word in words) {
      if (word.isNotEmpty) {
        // First letter uppercase, rest lowercase
        String formattedWord =
            word[0].toUpperCase() +
            (word.length > 1 ? word.substring(1).toLowerCase() : '');
        formattedWords.add(formattedWord);
      }
    }

    return formattedWords.join(' ');
  }

  // Helper function to calculate total rebate for a dealer's clients
  double _calculateTotalRebate(List<Map<String, dynamic>> clients) {
    double total = 0;
    for (var client in clients) {
      total += double.tryParse(client['rebate1']?.toString() ?? '0') ?? 0;
      total += double.tryParse(client['rebate2']?.toString() ?? '0') ?? 0;
      total += double.tryParse(client['rebate3']?.toString() ?? '0') ?? 0;
      total += double.tryParse(client['rebate4']?.toString() ?? '0') ?? 0;
      total += double.tryParse(client['rebate5']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  // Helper function to calculate grand total rebate across all dealers
  double _calculateGrandTotalRebate(
    Map<String, List<Map<String, dynamic>>> dealerClientsMap,
  ) {
    double grandTotal = 0;
    for (var clients in dealerClientsMap.values) {
      grandTotal += _calculateTotalRebate(clients);
    }
    return grandTotal;
  }
  // Helper function to calculate total rebate for a dealer's clients
  // double _calculateTotalRebate(List<Map<String, dynamic>> clients) {
  //   double total = 0;
  //   for (var client in clients) {
  //     total += (double.tryParse(client['rebate1']?.toString() ?? '0')) ?? 0;
  //     total += (double.tryParse(client['rebate2']?.toString() ?? '0')) ?? 0;
  //     total += (double.tryParse(client['rebate3']?.toString() ?? '0')) ?? 0;
  //   }
  //   return total;
  // }

  // // Helper function to calculate grand total rebate across all dealers
  // double _calculateGrandTotalRebate(
  //   Map<String, List<Map<String, dynamic>>> dealerClientsMap,
  // ) {
  //   double grandTotal = 0;

  //   for (var clients in dealerClientsMap.values) {
  //     grandTotal += _calculateTotalRebate(clients);
  //   }

  //   return grandTotal;
  // }

  // PDF Generation Method for a single dealer
  Future<void> _generateDealerPdf(Map<String, dynamic> dealer) async {
    final provider = Provider.of<DealerProvider>(context, listen: false);
    try {
      provider.startLoading();

      final String dealerNo = dealer['dealer_no']?.toString() ?? '';
      if (dealerNo.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dealer number is missing')),
        );
        return;
      }

      final forms = await MembershipService().getMembershipFormsByDealer(
        dealerNo: dealerNo,
        refStatus: true,
      );

      if (forms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No clients found with reference status'),
          ),
        );
        return;
      }

      final targetedBonuses = await supabase
          .from('expenses')
          .select('amount, date, description')
          .eq('category', 'Targeted Bonus')
          .eq('dl_no', dealerNo)
          .order('date', ascending: false);

      // Create PDF document
      final pdf = pw.Document();

      final apldimageBytes = await rootBundle.load(
        'assets/images/logo_reliable.png',
      );
      final logoReliable = pw.MemoryImage(apldimageBytes.buffer.asUint8List());

      pdf.addPage(
        pw.MultiPage(
          build:
              (context) => [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      children: [
                        pw.Image(logoReliable, width: 45),
                        pw.SizedBox(width: 8),
                        pw.Row(
                          children: [
                            pw.Align(
                              alignment: pw.Alignment.center,
                              child: pw.Text(
                                'Reliable Marketing Network',
                                style: pw.TextStyle(
                                  fontSize: 18,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.black,
                                ),
                              ),
                            ),
                            pw.Container(
                              height: 15,
                              child: pw.Align(
                                alignment: pw.Alignment.bottomRight,
                                child: pw.Text(
                                  'Pvt ltd',
                                  style: pw.TextStyle(
                                    fontSize: 7,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.black,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    pw.Align(
                      alignment: pw.Alignment.center,
                      child: pw.Text(
                        'Dealer Statement',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 15),

                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Dealer Info',
                    style: pw.TextStyle(
                      decoration: pw.TextDecoration.underline,
                      fontSize: 11,
                    ),
                  ),
                ),

                pw.Container(
                  width: Adaptive.w(20),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Dealer Number:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Name:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'CNIC:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Join Date:',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Spacer(),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            dealer['dealer_no'].toString().toUpperCase() ??
                                'N/A',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            style: pw.TextStyle(fontSize: 9),
                            _formatName(dealer['name']?.toString() ?? 'N/A'),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${dealer['dealer_cnic'] ?? 'N/A'}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            '${dealer['created_at']?.split('T')[0] ?? 'N/A'}',
                            style: pw.TextStyle(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                pw.Header(
                  level: 1,
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Associated Clients'.toUpperCase(),
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),

                // FIXED: Using manual Table with proper alignment
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: pw.FixedColumnWidth(25), // Sr. No. - Fixed width
                    1: pw.FixedColumnWidth(50), // No. COL - Fixed width
                    2: pw.FixedColumnWidth(55), // Booking Date - Fixed width
                    3: pw.FlexColumnWidth(1.8), // Name - Flexible
                    4: pw.FixedColumnWidth(70), // Membership No - Fixed width
                    5: pw.FixedColumnWidth(45), // Rebate 1 - Fixed width
                    6: pw.FixedColumnWidth(45), // Rebate 2 - Fixed width
                    7: pw.FixedColumnWidth(45), // Rebate 3 - Fixed width
                    8: pw.FixedColumnWidth(45), // Rebate 4 - Fixed width
                    9: pw.FixedColumnWidth(45), // Rebate 5 - Fixed width
                  },
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    // Header Row - ALL CENTERED
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        // Sr. No.
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Sr. No.',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // No. COL
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'COL',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Booking Date
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Booking Date',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Name
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Name',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Membership No.
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Membership No.',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Rebate 1
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rebate 1',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Rebate 2
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rebate 2',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Rebate 3
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rebate 3',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Rebate 4
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rebate 4',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Rebate 5
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Rebate 5',
                            style: pw.TextStyle(
                              fontSize: 8,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Data Rows
                    ...List.generate(forms.length, (index) {
                      final form = forms[index];

                      // Helper function to format cell with amount and date
                      pw.Widget formatCell(dynamic amount, dynamic date) {
                        final amountValue =
                            amount?.toString().replaceAll(
                              RegExp(r'\.0+$'),
                              '',
                            ) ??
                            '0';
                        final dateValue = date?.split('T')[0] ?? '-';

                        return pw.Column(
                          mainAxisAlignment: pw.MainAxisAlignment.center,
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text(
                              amountValue,
                              style: pw.TextStyle(fontSize: 7),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              dateValue,
                              style: pw.TextStyle(
                                fontSize: 6.5,
                                color: PdfColors.grey600,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        );
                      }

                      // Format cost of land
                      String formatCostOfLand(dynamic value) {
                        if (value == null) return '';
                        final strValue = value.toString().trim();
                        if (strValue.isEmpty ||
                            strValue == '0' ||
                            strValue == 'null') {
                          return '';
                        }
                        // Remove .0 if it's a whole number
                        if (strValue.contains('.') && strValue.endsWith('.0')) {
                          return strValue.split('.')[0];
                        }
                        return strValue;
                      }

                      // Format name with proper casing
                      String formattedName = _formatName(
                        form['name']?.toString() ?? 'N/A',
                      );

                      return pw.TableRow(
                        decoration:
                            index % 2 == 0
                                ? pw.BoxDecoration(color: PdfColors.grey100)
                                : null,
                        children: [
                          // Sr. No. - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${index + 1}',
                              style: pw.TextStyle(fontSize: 7.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // No. COL - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              formatCostOfLand(form['cost_of_land']),
                              style: pw.TextStyle(fontSize: 7.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Booking Date - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              form['date']?.split('T')[0] ?? '-',
                              style: pw.TextStyle(fontSize: 7.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Name - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              formattedName,
                              style: pw.TextStyle(fontSize: 7.5),
                              textAlign: pw.TextAlign.center,
                              maxLines: 2,
                              overflow: pw.TextOverflow.clip,
                            ),
                          ),
                          // Membership No. - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(4),
                            child: pw.Text(
                              form['membership_no']?.toString().toUpperCase() ??
                                  'N/A',
                              style: pw.TextStyle(fontSize: 7.5),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          // Rebate 1 - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(2),
                            child: formatCell(
                              form['rebate1'],
                              form['rebate1date'],
                            ),
                          ),
                          // Rebate 2 - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(2),
                            child: formatCell(
                              form['rebate2'],
                              form['rebate2date'],
                            ),
                          ),
                          // Rebate 3 - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(2),
                            child: formatCell(
                              form['rebate3'],
                              form['rebate3date'],
                            ),
                          ),
                          // Rebate 4 - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(2),
                            child: formatCell(
                              form['rebate4'],
                              form['rebate4date'],
                            ),
                          ),
                          // Rebate 5 - CENTERED
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(2),
                            child: formatCell(
                              form['rebate5'],
                              form['rebate5date'],
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'Targeted Bonuses'.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),

                // FIXED: Targeted Bonuses table with proper alignment
                pw.Table(
                  border: pw.TableBorder.all(width: 0.5),
                  columnWidths: {
                    0: pw.FlexColumnWidth(1), // Date
                    1: pw.FlexColumnWidth(2), // Remarks

                    2: pw.FlexColumnWidth(2), // Description
                    3: pw.FlexColumnWidth(1), // Amount
                  },
                  defaultVerticalAlignment:
                      pw.TableCellVerticalAlignment.middle,
                  children: [
                    // Header Row - ALL CENTERED
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.grey300),
                      children: [
                        // Date
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(6),
                          child: pw.Text(
                            'Date',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Description
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Remarks',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Description',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        // Amount
                        pw.Container(
                          alignment: pw.Alignment.center,
                          padding: pw.EdgeInsets.all(5),
                          child: pw.Text(
                            'Amount',
                            style: pw.TextStyle(
                              fontSize: 7,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Data Rows
                    if (targetedBonuses.isNotEmpty)
                      ...targetedBonuses.map(
                        (bonus) => pw.TableRow(
                          children: [
                            // Date - CENTERED
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text(
                                bonus['date']?.split('T')[0] ?? '-',
                                style: pw.TextStyle(fontSize: 7),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text(
                                bonus['remarks']?.toString() ?? 'No Remarks',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                            ),
                            // Description - LEFT ALIGNED (better for text)
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text(
                                bonus['description']?.toString() ??
                                    'No description',
                                style: pw.TextStyle(fontSize: 7),
                              ),
                            ),
                            // Amount - CENTERED
                            pw.Container(
                              alignment: pw.Alignment.center,
                              padding: pw.EdgeInsets.all(3),
                              child: pw.Text(
                                bonus['amount']?.toString() ?? '0',
                                style: pw.TextStyle(fontSize: 7),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      pw.TableRow(
                        children: [
                          pw.Container(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(''),
                          ),
                          pw.Container(
                            alignment: pw.Alignment.center,
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(
                              'No targeted bonuses found',
                              style: pw.TextStyle(
                                fontSize: 8,
                                fontStyle: pw.FontStyle.italic,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(''),
                          ),
                          pw.Container(
                            padding: pw.EdgeInsets.all(6),
                            child: pw.Text(''),
                          ),
                        ],
                      ),
                  ],
                ),

                // Footer
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Generated on: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                    pw.Text(
                      'Page 1 of 1',
                      style: pw.TextStyle(
                        fontSize: 7,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ],
        ),
      );

      // Save and open PDF
      final output = await getDownloadsDirectory();
      final file = File('${output!.path}/${dealer['dealer_no']}_report.pdf');
      await file.writeAsBytes(await pdf.save());

      OpenFile.open(file.path);
    } catch (e) {
      final errorMessage = SupabaseExceptionHandler.handleSupabaseError(e);
      SupabaseExceptionHandler.showErrorSnackbar(context, errorMessage);
    } finally {
      provider.stopLoading();
    }
  }

  // Helper function to format name with proper casing
  // String _formatName(String name) {
  //   if (name.isEmpty || name == 'N/A') return name;

  //   // Split by space, capitalize first letter of each word, lowercase the rest
  //   List<String> words = name.trim().split(' ');
  //   List<String> formattedWords = [];

  //   for (String word in words) {
  //     if (word.isNotEmpty) {
  //       // First letter uppercase, rest lowercase
  //       String formattedWord =
  //           word[0].toUpperCase() +
  //           (word.length > 1 ? word.substring(1).toLowerCase() : '');
  //       formattedWords.add(formattedWord);
  //     }
  //   }

  //   return formattedWords.join(' ');
  // }

  // Helper function to format cost of land with thousand separators
  String _formatCostOfLandWithSeparators(dynamic value) {
    if (value == null) return '';

    final strValue = value.toString().trim();
    if (strValue.isEmpty || strValue == '0' || strValue == 'null') {
      return '';
    }

    try {
      // Remove any non-numeric characters (except decimal point)
      String cleanValue = strValue.replaceAll(RegExp(r'[^\d.]'), '');
      final numValue = double.tryParse(cleanValue);

      if (numValue != null) {
        // Format with thousand separators
        final formatter = NumberFormat('#,##0');
        return formatter.format(numValue);
      }
    } catch (e) {
      // If parsing fails, return the original string
    }

    // Remove .0 if it's a whole number
    if (strValue.contains('.') && strValue.endsWith('.0')) {
      return strValue.split('.')[0];
    }

    return strValue;
  }

  // Helper function to calculate total targeted bonus
  double _calculateTotalTargetedBonus(List<dynamic> bonuses) {
    double total = 0;
    for (final bonus in bonuses) {
      final amount = bonus['amount'];
      if (amount != null) {
        total += double.tryParse(amount.toString()) ?? 0;
      }
    }
    return total;
  }

  // Helper function to build rebate cell with amount and date
  pw.Widget _buildRebateCell(Map<String, dynamic> form, String rebateKey) {
    final amount = form[rebateKey];
    final dateKey = '${rebateKey}date';
    final date = form[dateKey];

    final amountValue =
        amount?.toString().replaceAll(RegExp(r'\.0+$'), '') ?? '0';
    final dateValue = date?.split('T')[0] ?? '-';

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(amountValue, style: pw.TextStyle(fontSize: 8)),
        pw.SizedBox(height: 2),
        pw.Text(
          dateValue,
          style: pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
      ],
    );
  }

  String _formatCostOfLand(dynamic value) {
    if (value == null) return '';

    final strValue = value.toString().trim();
    if (strValue.isEmpty || strValue == '0' || strValue == 'null') {
      return '';
    }

    // Remove decimal points if it's a whole number
    if (strValue.contains('.')) {
      final parts = strValue.split('.');
      if (parts.length == 2 && parts[1] == '0') {
        return parts[0]; // Return without .0
      }
    }

    // Format as number with commas for thousands
    try {
      final numValue = double.tryParse(strValue);
      if (numValue != null) {
        // Format with commas for thousands
        final formatter = NumberFormat('#,##0');
        return formatter.format(numValue);
      }
    } catch (e) {
      // If parsing fails, return the string as is
    }

    return strValue;
  }

  // show dealer details widget
  void _showDealerDetails(Map<String, dynamic> dealer) {
    final provider = Provider.of<DealerProvider>(context, listen: false);
    provider.setSelectedDealer(dealer);

    showDialog(
      context: context,
      builder:
          (context) => Consumer<DealerProvider>(
            builder: (context, provider, _) {
              final dealer = provider.selectedDealer;
              if (dealer == null) return const SizedBox.shrink();

              return AlertDialog(
                backgroundColor: Colors.white,
                title: Text(
                  'Dealer Details',
                  style: TextStyle(color: Colors.black),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDetailRow(
                        'Dealer Number:',
                        dealer['dealer_no'].toString().toUpperCase(),
                      ),
                      _buildDetailRow(
                        'Name:',
                        dealer['name'].toString().toUpperCase(),
                      ),
                      _buildDetailRow('Phone:', dealer['phone']),
                      _buildDetailRow('CNIC:', dealer['dealer_cnic']),
                      // _buildDetailRow(
                      //   'Join Date:',
                      //   dealer['created_at'].split('T')[0],
                      // ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close', style: TextStyle(color: Colors.blue)),
                  ),
                ],
              );
            },
          ),
    ).then((_) => provider.clearSelectedDealer());
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  //show dealer optinos to mark suspended etc

  void _showDealerOptions(Map<String, dynamic> dealer) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: Colors.blueGrey[900],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit, color: Colors.blueAccent),
                  title: const Text(
                    'Edit Dealer',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.redAccent),
                  title: const Text(
                    'Delete Dealer',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {},
                ),
              ],
            ),
          ),
    );
  }
}
