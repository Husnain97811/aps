import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../view.dart';

class AllotmentProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _allMembers = [];
  List<Map<String, dynamic>> _filteredMembers = [];
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSaved = false;
  bool _showPdfButton = false;
  bool _showSavingAnimation = false;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSaved => _isSaved;
  bool get showPdfButton => _showPdfButton;
  bool get showSavingAnimation => _showSavingAnimation;
  List<Map<String, dynamic>> get filteredMembers => _filteredMembers;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void setSaved(bool value) {
    _isSaved = value;
    notifyListeners();
  }

  void setShowPdfButton(bool value) {
    _showPdfButton = value;
    notifyListeners();
  }

  void setShowSavingAnimation(bool value) {
    _showSavingAnimation = value;
    notifyListeners();
  }

  AllotmentProvider() {
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _fetchMembers();
    _applyFilters();
  }

  Future<void> _fetchMembers() async {
    try {
      // Fetch only members with is_allotted = true
      final response = await _supabase
          .from('membership_forms')
          .select()
          .eq('is_allotted', true) // Only allotted members
          .order('form_no', ascending: true);

      _allMembers = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result =
        _allMembers.where((member) {
          return _matchesSearchCriteria(member);
        }).toList();

    _filteredMembers = result;
    notifyListeners();
  }

  bool _matchesSearchCriteria(Map<String, dynamic> member) {
    if (_searchQuery.isEmpty) return true;
    return member['plot_no'].toString().contains(_searchQuery) ||
        member['name'].toString().toLowerCase().contains(_searchQuery);
  }

  void refreshData() {
    _isLoading = true;
    notifyListeners();
    _initializeData();
  }

  Future<Map<String, dynamic>?> getAllotmentDetails(String membershipNo) async {
    try {
      final response =
          await _supabase
              .from('allotments')
              .select()
              .eq('membership_no', membershipNo)
              .single();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getMemberDetails(String membershipNo) async {
    try {
      final response =
          await _supabase
              .from('membership_forms')
              .select()
              .eq('membership_no', membershipNo)
              .single();

      return response;
    } catch (e) {
      print('Error fetching allotment details: $e');

      return null;
    }
  }

  Future<void> createAllotment(
    String membershipNo,
    Map<String, dynamic> allotmentDetails,
  ) async {
    final allotmentNo = _generateAllotmentNumber();

    await _supabase.from('allotments').insert({
      'membership_no': membershipNo,
      'allotment_no': allotmentNo,
      'plot_no': allotmentDetails['plotNo'],
      'street': allotmentDetails['street'],
      'size': allotmentDetails['size'],
      'allotment_date': DateTime.now().toIso8601String(),
    });

    // Update membership_forms table to mark as allotted
    await _supabase
        .from('membership_forms')
        .update({'is_allotted': true})
        .eq('membership_no', membershipNo);

    refreshData();
  }

  String _generateAllotmentNumber() {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final random = Random().nextInt(10000).toString().padLeft(4, '0');
    return 'AL-$date-$random';
  }

  String generateAllotmentNumber() {
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    final random = Random().nextInt(10000).toString().padLeft(4, '0');
    return 'AL-$date-$random';
  }

  Future<void> updateAllotment(
    String membershipNo,
    Map<String, dynamic> updatedDetails,
  ) async {
    try {
      await _supabase
          .from('allotments')
          .update({
            'plot_no': updatedDetails['plot_no'],
            'street': updatedDetails['street'],
            'size': updatedDetails['size'],
            'special_category': updatedDetails['special_category'],
          })
          .eq('membership_no', membershipNo);

      refreshData();
    } catch (e) {
      rethrow; // Let the calling method handle the error
    }
  }
}
