import 'package:flutter_test/flutter_test.dart';
import 'lib/services/api/payment_api_service.dart';

void main() {
  group('Payment API Service Tests', () {
    test('PaymentListResponse handles integer payments gracefully', () {
      // Test case 1: payments is an integer (the problematic case)
      final jsonData1 = {
        'payments': 0,  // This caused the original error
        'totalPages': 1,
        'currentPage': 1,
        'total': 0
      };

      expect(() {
        final response = PaymentListResponse.fromJson(jsonData1);
        expect(response.payments, isEmpty);
        expect(response.totalPages, equals(1));
        expect(response.currentPage, equals(1));
        expect(response.total, equals(0));
      }, returnsNormally);

      // Test case 2: payments is null
      final jsonData2 = {
        'payments': null,
        'totalPages': 1,
        'currentPage': 1,
        'total': 0
      };

      expect(() {
        final response = PaymentListResponse.fromJson(jsonData2);
        expect(response.payments, isEmpty);
      }, returnsNormally);

      // Test case 3: payments is a proper list
      final jsonData3 = {
        'payments': [
          {
            '_id': 'test_id',
            'userId': 'user123',
            'courseId': 'course123',
            'amount': 1000,
            'currency': 'RWF',
            'paymentMethod': 'mtn',
            'transactionId': 'TXN123',
            'status': 'pending',
            'contactInfo': '0788888888',
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z'
          }
        ],
        'totalPages': 1,
        'currentPage': 1,
        'total': 1
      };

      expect(() {
        final response = PaymentListResponse.fromJson(jsonData3);
        expect(response.payments, hasLength(1));
        expect(response.payments[0].id, equals('test_id'));
        expect(response.total, equals(1));
      }, returnsNormally);
    });

    test('PaymentListResponse handles malformed data gracefully', () {
      // Test various edge cases
      final edgeCases = [
        {'payments': 'invalid_string'},
        {'payments': true},
        {'payments': false},
        {'payments': {}}, // empty object
        {
          'payments': [
            'invalid_item', // string instead of map
            {'valid': 'payment_data'}, // this should be skipped
            123, // number instead of map
            null // null item
          ]
        }
      ];

      for (var testCase in edgeCases) {
        expect(() {
          final response = PaymentListResponse.fromJson({
            ...testCase,
            'totalPages': 1,
            'currentPage': 1,
            'total': 0
          });
          // Should not crash and should return a valid response
          expect(response, isA<PaymentListResponse>());
        }, returnsNormally);
      }
    });
  });
}