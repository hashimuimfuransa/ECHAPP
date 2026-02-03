
class ApiConfig {
  // For Android emulator, use 10.0.2.2 to reach the host machine
  // For iOS simulator, use 10.0.2.2 or your machine's IP address
  // For web, use localhost
  static String get baseUrl {
    // For web development, use localhost
    // For mobile development, use your machine's IP address
    const String ipAddress = '192.168.1.3'; // Updated to machine's IP for mobile testing
    return 'http://$ipAddress:5000/api';
  }
  
  // Auth endpoints
  static String get register => '$baseUrl/auth/register';
  static String get login => '$baseUrl/auth/login';
  static String get refreshToken => '$baseUrl/auth/refresh-token';
  static String get profile => '$baseUrl/auth/profile';
  static String get logout => '$baseUrl/auth/logout';
  static String get firebaseLogin => '$baseUrl/auth/firebase-login';
  
  // Course endpoints
  static String get courses => '$baseUrl/courses';
  
  // Category endpoints
  static String get categories => '$baseUrl/categories';
  
  // Enrollment endpoints
  static String get enrollments => '$baseUrl/enrollments';
  
  // Exam endpoints
  static String get exams => '$baseUrl/exams';
  
  // Payment endpoints
  static String get payments => '$baseUrl/payments';
  
  // Video endpoints
  static String get videos => '$baseUrl/videos';
  
  // Admin endpoints
  static String get admin => '$baseUrl/admin';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
}