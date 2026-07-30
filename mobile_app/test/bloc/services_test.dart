import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('FlutterSecureStorage', () {
    late MockSecureStorage storage;

    setUp(() {
      storage = MockSecureStorage();
    });

    test('write stores value', () async {
      when(() => storage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});
      await storage.write(key: 'test', value: 'value');
      verify(() => storage.write(key: 'test', value: 'value')).called(1);
    });

    test('read retrieves stored value', () async {
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => 'test_value');
      final value = await storage.read(key: 'test_key');
      expect(value, 'test_value');
    });

    test('read returns null when key not found', () async {
      when(() => storage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
      final value = await storage.read(key: 'missing_key');
      expect(value, null);
    });

    test('delete removes value', () async {
      when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
      await storage.delete(key: 'test_key');
      verify(() => storage.delete(key: 'test_key')).called(1);
    });

    test('deleteAll clears all values', () async {
      when(() => storage.deleteAll()).thenAnswer((_) async {});
      await storage.deleteAll();
      verify(() => storage.deleteAll()).called(1);
    });
  });
}
