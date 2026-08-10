import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trackedify/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AuthService', () {
    late AuthService authService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      authService = AuthService();
    });

    test('isPinSet returns false when no PIN is configured', () async {
      final isSet = await authService.isPinSet();
      expect(isSet, isFalse);
    });

    test('setPin saves PIN hash and salt successfully', () async {
      await authService.setPin('1234');

      final isSet = await authService.isPinSet();
      expect(isSet, isTrue);

      final isValid = await authService.verifyPin('1234');
      expect(isValid, isTrue);

      final isWrongValid = await authService.verifyPin('9999');
      expect(isWrongValid, isFalse);
    });

    test(
      'setPin with recovery password allows recovery password verification',
      () async {
        await authService.setPin(
          '1234',
          recoveryPassword: 'mySecretRecoveryPassword',
        );

        final isRecoveryValid = await authService.verifyRecoveryPassword(
          'mySecretRecoveryPassword',
        );
        expect(isRecoveryValid, isTrue);

        final isWrongRecovery = await authService.verifyRecoveryPassword(
          'wrongPassword',
        );
        expect(isWrongRecovery, isFalse);
      },
    );

    test('disablePin clears all authentication data', () async {
      await authService.setPin('1234', recoveryPassword: 'myRecoveryPassword');
      expect(await authService.isPinSet(), isTrue);

      await authService.disablePin();

      expect(await authService.isPinSet(), isFalse);
      expect(await authService.verifyPin('1234'), isFalse);
      expect(
        await authService.verifyRecoveryPassword('myRecoveryPassword'),
        isFalse,
      );
    });
  });
}
