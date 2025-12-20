// dealer_provider.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart' show Consumer;
import 'package:supabase_flutter/supabase_flutter.dart';

class DealerProvider with ChangeNotifier {
  bool _isLoading = false;
  bool _isDisabled = false;

  List<Map<String, dynamic>> _allDealers = [];
  List<Map<String, dynamic>> get filteredDealers => filterDealers(_allDealers);

  // Getter for isLoading
  bool get isLoading => _isLoading;

  // Getter for isDisabled
  bool get isDisabled => _isDisabled;

  // Method to start loading
  void startLoading() {
    _isLoading = true;
    _isDisabled = true; // Disable buttons when loading starts
    notifyListeners();
  }

  // Method to stop loading
  void stopLoading() {
    _isLoading = false;
    _isDisabled = false; // Re-enable buttons when loading stops
    notifyListeners();
  }

  // // Set dealer info from selected dealer
  // void setDealerInfoFromDealer(Map<String, dynamic> dealer) {
  //   _dlNo = dealer['dealer_no'];
  //   _refStatus = true;
  //   _dealerInfo = {
  //     'name': dealer['name'],
  //     'cnic': dealer['dealer_cnic']?.toString() ?? '',
  //     'ref': dealer['ref'],
  //     'dl_no': dealer['dealer_no'],
  //     'rebate1': 0,
  //     'rebate2': 0,
  //     'rebate3': 0,
  //   };
  //   notifyListeners();
  // }

  // function ;to show dealer information
  Map<String, dynamic>? _selectedDealer;

  Map<String, dynamic>? get selectedDealer => _selectedDealer;

  void setSelectedDealer(Map<String, dynamic> dealer) {
    _selectedDealer = dealer;
    notifyListeners();
  }

  void clearSelectedDealer() {
    _selectedDealer = null;
    notifyListeners();
  }

  // search form field functinality

  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  List<Map<String, dynamic>> filterDealers(List<Map<String, dynamic>> dealers) {
    if (_searchQuery.isEmpty) return dealers;
    return dealers.where((dealer) {
      final name = dealer['name']?.toString().toLowerCase() ?? '';
      final dealerNo = dealer['dealer_no']?.toString().toLowerCase() ?? '';
      return name.contains(_searchQuery.toLowerCase()) ||
          dealerNo.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // function to store dealer information

  final SupabaseClient _supabase = Supabase.instance.client;
  String? _dlNo; // Private variable to store DL number
  bool _refStatus = false; // Private variable to store reference status
  Map<String, dynamic> _dealerInfo =
      {}; // Private variable to store dealer info

  // Public getter for DL number
  String? get dlNo => _dlNo;

  // Public getter for reference status
  bool get refStatus => _refStatus;

  // Public getter for dealer info
  Map<String, dynamic> get dealerInfo => _dealerInfo;

  // Fetch dealer data from Supabase
  Future<void> fetchAllDealers() async {
    try {
      startLoading();
      final response = await _supabase
          .from('dealers')
          .select('dealer_no, name, dealer_cnic');
      _allDealers = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching all dealers: $e');
      _allDealers = [];
    } finally {
      stopLoading();
      notifyListeners();
    }
  }

  // Set dealer info from selected dealer
  void setDealerInfoFromDealer(Map<String, dynamic> dealer) {
    _dlNo = dealer['dealer_no'];
    _refStatus = true;
    _dealerInfo = {
      'name': dealer['name'],
      'cnic': dealer['dealer_cnic']?.toString() ?? '',
      'dl_no': dealer['dealer_no'],
      'rebate1': 0,
      'rebate2': 0,
      'rebate3': 0,
    };
    notifyListeners();
  }

  // Update existing fetchDealer method to remove 'ref'
  Future<void> fetchDealer(String dlNo) async {
    try {
      final response =
          await _supabase
              .from('dealers')
              .select('dealer_no, name, dealer_cnic')
              .eq('dealer_no', dlNo)
              .maybeSingle();

      if (response != null) {
        _dlNo = response['dealer_no'];
        _refStatus = true;
        _dealerInfo = {
          'name': response['name'],
          'cnic': response['dealer_cnic']?.toString() ?? '',
          'dl_no': response['dealer_no'],
          'rebate1': 0,
          'rebate2': 0,
          'rebate3': 0,
        };
      } else {
        clearDealerData();
      }
    } catch (e) {
      print('Error fetching dealer: $e');
      clearDealerData();
    }
    notifyListeners();
  }

  // Clear dealer data
  void clearDealerData() {
    _dlNo = null;
    _refStatus = false;
    _dealerInfo = {};
    notifyListeners();
  }
}

// / New DealerListDialog Widget
class DealerListDialog extends StatelessWidget {
  final DealerProvider dealerProvider;

  const DealerListDialog({super.key, required this.dealerProvider});

  @override
  Widget build(BuildContext context) {
    return Consumer<DealerProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Search Bar
            TextField(
              onChanged: provider.setSearchQuery,
              decoration: InputDecoration(
                labelText: 'Search by name or DL number',
                suffixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),

            // Dealers List
            Expanded(
              child:
                  provider.isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                        itemCount: provider.filteredDealers.length,
                        itemBuilder: (context, index) {
                          final dealer = provider.filteredDealers[index];
                          return ListTile(
                            title: Text(
                              dealer['name'].toString().toUpperCase() ?? '',
                            ),
                            subtitle: Text(
                              dealer['dealer_no'].toString().toUpperCase() ??
                                  '',
                            ),
                            onTap: () {
                              provider.setDealerInfoFromDealer(dealer);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
            ),
          ],
        );
      },
    );
  }
}
