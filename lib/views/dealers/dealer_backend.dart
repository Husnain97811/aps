import 'package:supabase_flutter/supabase_flutter.dart';

class DealerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getDealers() async {
    final response = await _supabase
        .from('dealers')
        .select('*')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateDealer(
    String dealerNo,
    Map<String, dynamic> updates,
  ) async {
    await _supabase.from('dealers').update(updates).eq('dealer_no', dealerNo);
  }

  Future<String> _getLastDealerNo() async {
    final response = await _supabase.from('dealers').select('dealer_no');

    if (response.isEmpty) {
      return 'RMN-REC-100'; // Default starting number
    }

    int maxNumber = 100; // Fallback if all parsing fails
    for (var dealer in response) {
      String dealerNo = dealer['dealer_no'];
      List<String> parts = dealerNo.split('-');
      if (parts.length >= 3) {
        String numericPart = parts[2];
        try {
          int currentNum = int.parse(numericPart);
          if (currentNum > maxNumber) {
            maxNumber = currentNum;
          }
        } catch (e) {
          print('Error parsing dealer number $dealerNo: $e');
        }
      }
    }

    return 'RMN-REC-$maxNumber';
  }

  Future<String> generateNewDealerNo() async {
    final lastNo = await _getLastDealerNo();
    final parts = lastNo.split('-');
    int lastNumber = int.parse(parts[2]);
    final newNumber = lastNumber + 1;
    return 'RMN-REC-$newNumber';
  }

  Future<void> addDealer(Map<String, dynamic> dealerData) async {
    await _supabase.from('dealers').insert(dealerData);
  }

  Future<void> deleteDealer(String dealerNo) async {
    await _supabase.from('dealers').delete().eq('dealer_no', dealerNo);
  }
}

// --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
class MembershipService {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getMembershipFormsByDealer({
    required String dealerNo,
    required bool refStatus,
  }) async {
    try {
      // Fetch data from Supabase
      final response = await supabase
          .from('membership_forms')
          .select()
          .eq('dl_no', dealerNo) // Ensure dl_no is a string in Supabase
          .eq('ref', refStatus);

      // Ensure the response is a List<Map<String, dynamic>>
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception("Supabase Error: $e");
    }
  }
}
