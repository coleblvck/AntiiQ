import 'package:antiiq/player/utilities/app_restart.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('restart');

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('requests a cold process restart on Android', () async {
    MethodCall? receivedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      receivedCall = call;
      return <String, Object?>{
        'success': true,
        'mode': 'process',
      };
    });

    await restartAntiiQ();

    expect(receivedCall?.method, 'restartApp');
    expect(
      receivedCall?.arguments,
      containsPair('mode', 'process'),
    );
  });

  test('surfaces a rejected restart', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      return <String, Object?>{
        'success': false,
        'mode': 'process',
        'code': 'RESTART_FAILED',
        'message': 'No activity available',
      };
    });

    await expectLater(
      restartAntiiQ(),
      throwsA(
        isA<AntiiQRestartException>().having(
          (error) => error.message,
          'message',
          'No activity available',
        ),
      ),
    );
  });
}
