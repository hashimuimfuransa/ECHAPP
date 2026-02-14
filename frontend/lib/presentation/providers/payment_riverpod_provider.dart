import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/api/payment_api_service.dart';
import '../../models/payment.dart';
import '../../models/payment_status.dart';
import '../../services/infrastructure/api_client.dart';

// Payment API Service Provider
final paymentApiServiceProvider = Provider<PaymentApiService>((ref) {
  return PaymentApiService();
});

// Payment State Notifier
class PaymentStateNotifier extends StateNotifier<PaymentState> {
  final PaymentApiService _apiService;
  
  // Track ongoing payment initiation to prevent duplicates
  String? _ongoingPaymentCourseId;
  
  PaymentStateNotifier(this._apiService) : super(const PaymentState());

  // Admin Methods
  Future<void> loadPayments({
    PaymentStatus? status,
    String? courseId,
    String? userId,
    int page = 1,
  }) async {
    print('PaymentNotifier: loadPayments called with status=$status, page=$page');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('PaymentNotifier: Calling getAllPayments');
      final response = await _apiService.getAllPayments(
        status: status,
        courseId: courseId,
        userId: userId,
        page: page,
        limit: state.itemsPerPage,
      );
      
      print('PaymentNotifier: Got response with ${response.payments.length} payments');
      
      state = state.copyWith(
        payments: response.payments,
        currentPage: response.currentPage,
        totalPages: response.totalPages,
        totalItems: response.total,
        isLoading: false,
        error: null, // Clear any previous errors
      );
      print('PaymentNotifier: State updated successfully');
    } catch (e, stackTrace) {
      print('PaymentNotifier: Error in loadPayments: $e');
      print('Stack trace: $stackTrace');
      
      // Provide user-friendly error messages
      String userFriendlyError;
      if (e.toString().contains("type 'int' is not a subtype of type 'Iterable'")) {
        userFriendlyError = 'Payment data format error. Please try refreshing.';
      } else if (e.toString().contains('Network')) {
        userFriendlyError = 'Network error. Please check your connection.';
      } else if (e.toString().contains('401') || e.toString().contains('403')) {
        userFriendlyError = 'Authentication error. Please log in again.';
      } else {
        userFriendlyError = 'Failed to load payments. Please try again.';
      }
      
      state = state.copyWith(
        error: userFriendlyError,
        payments: const [],
        isLoading: false,
      );
    }
  }
  
  Future<void> loadPaymentStats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final stats = await _apiService.getPaymentStats();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  Future<void> verifyPayment({
    required String paymentId,
    required PaymentStatus status,
    String? adminNotes,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      await _apiService.verifyPayment(
        paymentId: paymentId,
        status: status,
        adminNotes: adminNotes,
      );
      
      // Refresh payments list
      await loadPayments(status: state.filterStatus, page: state.currentPage);
      // Don't call loadPaymentStats() here to avoid infinite loop
      state = state.copyWith(isProcessing: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isProcessing: false);
    }
  }
  
  // User Methods
  Future<void> loadUserPayments({PaymentStatus? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final payments = await _apiService.getMyPayments(status: status);
      state = state.copyWith(userPayments: payments, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        userPayments: [],
        isLoading: false,
      );
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
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      final response = await _apiService.initiatePayment(
        courseId: courseId,
        paymentMethod: paymentMethod,
        contactInfo: contactInfo,
      );
      
      // Refresh user payments
      await loadUserPayments();
      state = state.copyWith(isProcessing: false);
      
      return response;
    } catch (e) {
      // If it's a 'payment already initiated' error, still refresh user payments
      // so the UI can detect the pending payment
      if (e.toString().contains('already initiated')) {
        await loadUserPayments();
      }
      
      state = state.copyWith(error: e.toString(), isProcessing: false);
      rethrow;
    } finally {
      _ongoingPaymentCourseId = null;
    }
  }
  
  Future<void> cancelPayment(String paymentId) async {
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      await _apiService.cancelPayment(paymentId);
      
      // Refresh payments lists
      await loadUserPayments(status: state.filterStatus);
      if (state.payments.isNotEmpty) {
        await loadPayments(status: state.filterStatus, page: state.currentPage);
      }
      state = state.copyWith(isProcessing: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isProcessing: false);
    }
  }
  
  Future<Payment> getPaymentDetails(String paymentId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final payment = await _apiService.getPaymentById(paymentId);
      state = state.copyWith(isLoading: false);
      return payment;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      rethrow;
    }
  }
  
  // UI Helper Methods
  void setFilterStatus(PaymentStatus? status) {
    state = state.copyWith(
      filterStatus: status,
      currentPage: 1,
    );
  }
  
  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
    );
  }
  
  void setItemsPerPage(int itemsPerPage) {
    state = state.copyWith(
      itemsPerPage: itemsPerPage,
      currentPage: 1,
    );
  }
  
  // Reset methods
  void resetFilters() {
    state = state.copyWith(
      filterStatus: null,
      searchQuery: '',
      currentPage: 1,
    );
  }
  
  void resetError() {
    state = state.copyWith(error: null);
  }
  
  void reset() {
    state = const PaymentState();
  }
}

// Payment State
class PaymentState {
  final List<Payment> payments;
  final List<Payment> userPayments;
  final PaymentStatsResponse? stats;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final PaymentStatus? filterStatus;
  final String searchQuery;
  final int currentPage;
  final int itemsPerPage;
  final int totalPages;
  final int totalItems;

  const PaymentState({
    this.payments = const [],
    this.userPayments = const [],
    this.stats,
    this.isLoading = false,
    this.isProcessing = false,
    this.error,
    this.filterStatus,
    this.searchQuery = '',
    this.currentPage = 1,
    this.itemsPerPage = 10,
    this.totalPages = 1,
    this.totalItems = 0,
  });

  // Computed getters
  List<Payment> get filteredPayments {
    List<Payment> filtered = payments;
    
    // Apply status filter
    if (filterStatus != null) {
      filtered = filtered.where((p) => p.status == filterStatus).toList();
    }
    
    // Apply search filter
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
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
    List<Payment> filtered = userPayments;
    
    if (filterStatus != null) {
      filtered = filtered.where((p) => p.status == filterStatus).toList();
    }
    
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((p) => 
        p.transactionId.toLowerCase().contains(query) ||
        p.course?.title.toLowerCase().contains(query) == true
      ).toList();
    }
    
    return filtered;
  }

  PaymentState copyWith({
    List<Payment>? payments,
    List<Payment>? userPayments,
    PaymentStatsResponse? stats,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    PaymentStatus? filterStatus,
    String? searchQuery,
    int? currentPage,
    int? itemsPerPage,
    int? totalPages,
    int? totalItems,
  }) {
    return PaymentState(
      payments: payments ?? this.payments,
      userPayments: userPayments ?? this.userPayments,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      filterStatus: filterStatus ?? this.filterStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PaymentState &&
        other.payments == payments &&
        other.userPayments == userPayments &&
        other.stats == stats &&
        other.isLoading == isLoading &&
        other.isProcessing == isProcessing &&
        other.error == error &&
        other.filterStatus == filterStatus &&
        other.searchQuery == searchQuery &&
        other.currentPage == currentPage &&
        other.itemsPerPage == itemsPerPage &&
        other.totalPages == totalPages &&
        other.totalItems == totalItems;
  }

  @override
  int get hashCode {
    return Object.hash(
      payments,
      userPayments,
      stats,
      isLoading,
      isProcessing,
      error,
      filterStatus,
      searchQuery,
      currentPage,
      itemsPerPage,
      totalPages,
      totalItems,
    );
  }
}

// Main Payment Provider
final paymentProvider = StateNotifierProvider<PaymentStateNotifier, PaymentState>(
  (ref) {
    final apiService = ref.watch(paymentApiServiceProvider);
    return PaymentStateNotifier(apiService);
  },
);
