import 'package:flutter/foundation.dart';
import '../../services/api/payment_api_service.dart';
import '../../models/payment.dart';
import '../../models/payment_status.dart';
import '../../services/infrastructure/api_client.dart';

/// Payment state management provider
class PaymentProvider with ChangeNotifier {
  final PaymentApiService _apiService = PaymentApiService();
  
  // State variables
  List<Payment> _payments = [];
  List<Payment> _userPayments = [];
  PaymentStatsResponse? _stats;
  bool _isLoading = false;
  bool _isProcessing = false;
  String? _error;
  
  // Track ongoing payment initiation to prevent duplicates
  String? _ongoingPaymentCourseId;
  
  // Filter and pagination
  PaymentStatus? _filterStatus;
  String _searchQuery = '';
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  int _totalItems = 0;
  
  // Getters
  List<Payment> get payments => _payments;
  List<Payment> get userPayments => _userPayments;
  PaymentStatsResponse? get stats => _stats;
  bool get isLoading => _isLoading;
  bool get isProcessing => _isProcessing;
  String? get error => _error;
  PaymentStatus? get filterStatus => _filterStatus;
  String get searchQuery => _searchQuery;
  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  
  // Computed getters
  List<Payment> get filteredPayments {
    List<Payment> filtered = _payments;
    
    // Apply status filter
    if (_filterStatus != null) {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => 
        p.transactionId.toLowerCase().contains(query) ||
        p.user?.fullName.toLowerCase().contains(query) == true ||
        p.user?.email.toLowerCase().contains(query) == true ||
        p.course?.title.toLowerCase().contains(query) == true
      ).toList();
    }
    
    return filtered;
  }
  
  List<Payment> get filteredUserPayments {
    List<Payment> filtered = _userPayments;
    
    if (_filterStatus != null) {
      filtered = filtered.where((p) => p.status == _filterStatus).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((p) => 
        p.transactionId.toLowerCase().contains(query) ||
        p.course?.title.toLowerCase().contains(query) == true
      ).toList();
    }
    
    return filtered;
  }
  
  // Admin Methods
  Future<void> loadPayments({
    PaymentStatus? status,
    String? courseId,
    String? userId,
    int page = 1,
  }) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final response = await _apiService.getAllPayments(
        status: status,
        courseId: courseId,
        userId: userId,
        page: page,
        limit: _itemsPerPage,
      );
      
      // Update pagination info
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _totalItems = response.total;
      _payments = response.payments;
      
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      // Clear payments on error to show empty state
      _payments = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> loadPaymentStats() async {
    _setLoading(true);
    _setError(null);
    
    try {
      _stats = await _apiService.getPaymentStats();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> verifyPayment({
    required String paymentId,
    required PaymentStatus status,
    String? adminNotes,
  }) async {
    _setProcessing(true);
    _setError(null);
    
    try {
      await _apiService.verifyPayment(
        paymentId: paymentId,
        status: status,
        adminNotes: adminNotes,
      );
      
      // Refresh payments list
      await loadPayments(status: _filterStatus, page: _currentPage);
      // Don't call loadPaymentStats() here to avoid infinite loop
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setProcessing(false);
    }
  }
  
  // User Methods
  Future<void> loadUserPayments({PaymentStatus? status}) async {
    _setLoading(true);
    _setError(null);
    
    try {
      _userPayments = await _apiService.getMyPayments(status: status);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
      _userPayments = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }
  
  Future<PaymentInitiationResponse> initiatePayment({
    required String courseId,
    required String paymentMethod,
    required String contactInfo,
  }) async {
    // Prevent duplicate payment initiations for the same course
    if (_ongoingPaymentCourseId == courseId) {
      throw ApiException('Payment initiation already in progress for this course');
    }
    
    _ongoingPaymentCourseId = courseId;
    _setProcessing(true);
    _setError(null);
    
    try {
      final response = await _apiService.initiatePayment(
        courseId: courseId,
        paymentMethod: paymentMethod,
        contactInfo: contactInfo,
      );
      
      // Refresh user payments
      await loadUserPayments();
      
      return response;
    } catch (e) {
      // If it's a 'payment already initiated' error, still refresh user payments
      // so the UI can detect the pending payment
      if (e.toString().contains('already initiated')) {
        await loadUserPayments();
      }
      
      _setError(e.toString());
      rethrow;
    } finally {
      _ongoingPaymentCourseId = null;
      _setProcessing(false);
    }
  }
  
  Future<void> cancelPayment(String paymentId) async {
    _setProcessing(true);
    _setError(null);
    
    try {
      await _apiService.cancelPayment(paymentId);
      
      // Refresh payments lists
      await loadUserPayments(status: _filterStatus);
      if (_payments.isNotEmpty) {
        await loadPayments(status: _filterStatus, page: _currentPage);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setProcessing(false);
    }
  }
  
  Future<Payment> getPaymentDetails(String paymentId) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final payment = await _apiService.getPaymentById(paymentId);
      return payment;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // UI Helper Methods
  void setFilterStatus(PaymentStatus? status) {
    _filterStatus = status;
    _currentPage = 1; // Reset to first page
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page
    notifyListeners();
  }
  
  void setItemsPerPage(int itemsPerPage) {
    _itemsPerPage = itemsPerPage;
    _currentPage = 1; // Reset to first page
    notifyListeners();
  }
  
  // Reset methods
  void resetFilters() {
    _filterStatus = null;
    _searchQuery = '';
    _currentPage = 1;
    notifyListeners();
  }
  
  void resetError() {
    _setError(null);
  }
  
  void reset() {
    _payments = [];
    _userPayments = [];
    _stats = null;
    _filterStatus = null;
    _searchQuery = '';
    _currentPage = 1;
    _totalPages = 1;
    _totalItems = 0;
    _setError(null);
    notifyListeners();
  }
  
  // Private helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void _setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }
  
  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }
  
  @override
  void dispose() {
    _apiService.dispose();
    super.dispose();
  }
}
