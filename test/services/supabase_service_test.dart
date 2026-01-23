import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:reseller_copilot/services/supabase_service.dart';
import 'package:reseller_copilot/models/scan_result.dart';

import 'supabase_service_test.mocks.dart';

// Generate mocks for these classes
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  Session,
  User,
  SupabaseFunctionsClient,
  FunctionResponse,
  SupabaseStorageClient,
  SupabaseQueryBuilder,
  PostgrestFilterBuilder,
])
void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;
  late MockSupabaseFunctionsClient mockFunctions;
  late MockSupabaseStorageClient mockStorage;
  late SupabaseService service;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockFunctions = MockSupabaseFunctionsClient();
    mockStorage = MockSupabaseStorageClient();

    when(mockSupabase.auth).thenReturn(mockAuth);
    when(mockSupabase.functions).thenReturn(mockFunctions);
    when(mockSupabase.storage).thenReturn(mockStorage);

    service = SupabaseService(mockSupabase);
  });

  group('SupabaseService - analyzeItem', () {
    test('should throw exception when user is not authenticated', () async {
      // Arrange
      when(mockAuth.currentSession).thenReturn(null);

      // Act & Assert
      expect(
        () => service.analyzeItem(
          imageBytes: Uint8List.fromList([1, 2, 3]),
          price: 29.99,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User not authenticated'),
        )),
      );
    });

    test('should throw exception when neither image nor imageBytes provided', () async {
      // Arrange
      final mockSession = MockSession();
      when(mockAuth.currentSession).thenReturn(mockSession);
      when(mockAuth.refreshSession()).thenAnswer((_) async => AuthResponse(session: mockSession));
      when(mockSession.accessToken).thenReturn('valid-token');

      // Act & Assert
      expect(
        () => service.analyzeItem(price: 29.99),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Either image or imageBytes must be provided'),
        )),
      );
    });

    test('should successfully analyze item with valid imageBytes', () async {
      // Arrange
      final mockSession = MockSession();
      final mockUser = MockUser();
      final mockFunctionResponse = MockFunctionResponse();

      when(mockAuth.currentSession).thenReturn(mockSession);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockAuth.refreshSession()).thenAnswer((_) async => AuthResponse(session: mockSession));
      when(mockSession.accessToken).thenReturn('valid-token');
      when(mockUser.id).thenReturn('user-123');

      // Mock the edge function response
      final responseData = {
        'product_name': 'Nike Air Max',
        'market_price': 89.99,
        'net_profit': 45.50,
        'verdict': 'BUY',
        'velocity_score': 'High',
        'ebay_price': 89.99,
        'ebay_url': 'https://ebay.com/item/123',
        'amazon_price': 94.99,
        'amazon_url': 'https://amazon.com/dp/ABC123',
        'fee_percentage': 15.0,
        'fees_amount': 13.50,
        'shipping_cost': 5.00,
        'sales_tax_rate': 8.0,
        'sales_tax_amount': 2.40,
        'market_analysis': 'This product is selling well.',
        'condition': 'New',
      };

      when(mockFunctionResponse.status).thenReturn(200);
      when(mockFunctionResponse.data).thenReturn(responseData);

      when(mockFunctions.invoke(
        'analyze-product',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockFunctionResponse);

      final imageBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

      // Act
      final result = await service.analyzeItem(
        imageBytes: imageBytes,
        price: 29.99,
        barcode: '123456789',
        condition: 'New',
      );

      // Assert
      expect(result.productName, 'Nike Air Max');
      expect(result.buyPrice, 29.99);
      expect(result.marketPrice, 89.99);
      expect(result.netProfit, 45.50);
      expect(result.verdict, 'BUY');
      expect(result.velocityScore, 'High');
      expect(result.barcode, '123456789');
      expect(result.ebayPrice, 89.99);
      expect(result.ebayUrl, 'https://ebay.com/item/123');

      // Verify edge function was called
      verify(mockFunctions.invoke(
        'analyze-product',
        body: anyNamed('body'),
      )).called(1);
    });

    test('should handle edge function error responses', () async {
      // Arrange
      final mockSession = MockSession();
      final mockFunctionResponse = MockFunctionResponse();

      when(mockAuth.currentSession).thenReturn(mockSession);
      when(mockAuth.refreshSession()).thenAnswer((_) async => AuthResponse(session: mockSession));
      when(mockSession.accessToken).thenReturn('valid-token');

      when(mockFunctionResponse.status).thenReturn(500);
      when(mockFunctionResponse.data).thenReturn({
        'error': 'AI analysis failed',
      });

      when(mockFunctions.invoke(
        'analyze-product',
        body: anyNamed('body'),
      )).thenAnswer((_) async => mockFunctionResponse);

      final imageBytes = Uint8List.fromList([1, 2, 3]);

      // Act & Assert
      expect(
        () => service.analyzeItem(
          imageBytes: imageBytes,
          price: 29.99,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to analyze product'),
        )),
      );
    });

    test('should handle session expired error', () async {
      // Arrange
      final mockSession = MockSession();

      when(mockAuth.currentSession).thenReturn(mockSession);
      when(mockAuth.refreshSession()).thenAnswer((_) async => AuthResponse(session: null));
      when(mockSession.accessToken).thenReturn('valid-token');

      final imageBytes = Uint8List.fromList([1, 2, 3]);

      // Act & Assert
      expect(
        () => service.analyzeItem(
          imageBytes: imageBytes,
          price: 29.99,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Failed to refresh session'),
        )),
      );
    });
  });

  group('SupabaseService - saveScan', () {
    test('should throw exception when user is not authenticated', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      final scan = ScanResult(
        productName: 'Test Product',
        buyPrice: 29.99,
        marketPrice: 89.99,
        netProfit: 45.50,
        verdict: 'BUY',
        velocityScore: 'High',
      );

      // Act & Assert
      expect(
        () => service.saveScan(scan),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User not authenticated'),
        )),
      );
    });

    test('should successfully save scan with all fields', () async {
      // Arrange
      final mockUser = MockUser();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('user-123');

      final scan = ScanResult(
        productName: 'Nike Air Max',
        buyPrice: 29.99,
        marketPrice: 89.99,
        netProfit: 45.50,
        verdict: 'BUY',
        velocityScore: 'High',
        barcode: '123456789',
        ebayPrice: 89.99,
        ebayUrl: 'https://ebay.com/item/123',
        amazonPrice: 94.99,
        amazonUrl: 'https://amazon.com/dp/ABC123',
        condition: 'New',
      );

      final savedScanData = {
        'id': 'scan-123',
        'user_id': 'user-123',
        'product_name': 'Nike Air Max',
        'buy_price': 29.99,
        'market_price': 89.99,
        'net_profit': 45.50,
        'verdict': 'BUY',
        'velocity_score': 'High',
        'barcode': '123456789',
        'ebay_price': 89.99,
        'ebay_url': 'https://ebay.com/item/123',
        'amazon_price': 94.99,
        'amazon_url': 'https://amazon.com/dp/ABC123',
        'condition': 'New',
        'created_at': DateTime.now().toIso8601String(),
      };

      when(mockSupabase.from('scans')).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('*')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenAnswer((_) async => savedScanData);

      // Act
      final result = await service.saveScan(scan);

      // Assert
      expect(result.id, 'scan-123');
      expect(result.userId, 'user-123');
      expect(result.productName, 'Nike Air Max');
      expect(result.buyPrice, 29.99);
      expect(result.verdict, 'BUY');

      // Verify insert was called
      verify(mockSupabase.from('scans')).called(1);
      verify(mockQueryBuilder.insert(any)).called(1);
    });

    test('should handle database errors when saving scan', () async {
      // Arrange
      final mockUser = MockUser();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('user-123');

      final scan = ScanResult(
        productName: 'Test Product',
        buyPrice: 29.99,
        marketPrice: 89.99,
        netProfit: 45.50,
        verdict: 'BUY',
        velocityScore: 'High',
      );

      when(mockSupabase.from('scans')).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.insert(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('*')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenThrow(Exception('Database error'));

      // Act & Assert
      expect(
        () => service.saveScan(scan),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error saving scan'),
        )),
      );
    });
  });

  group('SupabaseService - getScans', () {
    test('should throw exception when user is not authenticated', () async {
      // Arrange
      when(mockAuth.currentUser).thenReturn(null);

      // Act & Assert
      expect(
        () => service.getScans(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User not authenticated'),
        )),
      );
    });

    test('should successfully retrieve scans for authenticated user', () async {
      // Arrange
      final mockUser = MockUser();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('user-123');

      final scansData = [
        {
          'id': 'scan-1',
          'user_id': 'user-123',
          'product_name': 'Product 1',
          'buy_price': 19.99,
          'market_price': 49.99,
          'net_profit': 20.00,
          'verdict': 'BUY',
          'velocity_score': 'High',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'scan-2',
          'user_id': 'user-123',
          'product_name': 'Product 2',
          'buy_price': 39.99,
          'market_price': 59.99,
          'net_profit': 10.00,
          'verdict': 'PASS',
          'velocity_score': 'Low',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      when(mockSupabase.from('scans')).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.select('*')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('user_id', 'user-123')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('created_at', ascending: false))
          .thenAnswer((_) async => scansData);

      // Act
      final result = await service.getScans();

      // Assert
      expect(result.length, 2);
      expect(result[0].productName, 'Product 1');
      expect(result[0].verdict, 'BUY');
      expect(result[1].productName, 'Product 2');
      expect(result[1].verdict, 'PASS');

      // Verify query was constructed correctly
      verify(mockSupabase.from('scans')).called(1);
      verify(mockQueryBuilder.select('*')).called(1);
      verify(mockFilterBuilder.eq('user_id', 'user-123')).called(1);
      verify(mockFilterBuilder.order('created_at', ascending: false)).called(1);
    });

    test('should return empty list when user has no scans', () async {
      // Arrange
      final mockUser = MockUser();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('user-123');

      when(mockSupabase.from('scans')).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.select('*')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('user_id', 'user-123')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('created_at', ascending: false))
          .thenAnswer((_) async => []);

      // Act
      final result = await service.getScans();

      // Assert
      expect(result, isEmpty);
    });

    test('should handle database errors when fetching scans', () async {
      // Arrange
      final mockUser = MockUser();
      final mockQueryBuilder = MockSupabaseQueryBuilder();
      final mockFilterBuilder = MockPostgrestFilterBuilder();

      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('user-123');

      when(mockSupabase.from('scans')).thenReturn(mockQueryBuilder);
      when(mockQueryBuilder.select('*')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq('user_id', 'user-123')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order('created_at', ascending: false))
          .thenThrow(Exception('Database connection failed'));

      // Act & Assert
      expect(
        () => service.getScans(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Error fetching scans'),
        )),
      );
    });
  });
}
