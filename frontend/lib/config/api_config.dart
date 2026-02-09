
class ApiConfig {
  // Dynamic base URL that works across platforms
  static String get baseUrl {
    // For web development, use localhost
    // For mobile development, use your machine's IP address
    const String ipAddress = '192.168.1.5'; // Updated to your current IP
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
  
  // Upload endpoints
  static String get upload => '$baseUrl/upload';
  
  // Admin endpoints
  static String get admin => '$baseUrl/admin';
  
  // Section endpoints
  static String get sections => '$baseUrl/sections';
  
  // Lesson endpoints
  static String get lessons => '$baseUrl/lessons';
}

class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userRole = 'user_role';
  static const String userId = 'user_id';
}