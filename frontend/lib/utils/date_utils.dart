/// Universal date parsing utility for handling different date formats
/// Used across the application to safely parse dates from various sources
library;

class DateUtils {
  /// Parse date from various formats (int timestamp, String ISO, DateTime)
  static DateTime parseDate(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }

    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }

    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        // If parsing fails, return current time
        return DateTime.now();
      }
    }

    if (value is DateTime) {
      return value;
    }

    // Fallback - return current time
    return DateTime.now();
  }

  /// Convert DateTime to milliseconds since epoch
  static int toTimestamp(DateTime dateTime) {
    return dateTime.millisecondsSinceEpoch;
  }

  /// Convert DateTime to ISO string
  static String toISOString(DateTime dateTime) {
    return dateTime.toIso8601String();
  }
}
