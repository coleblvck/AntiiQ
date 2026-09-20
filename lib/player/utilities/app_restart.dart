import 'package:restart_app/restart_app.dart';

class AntiiQRestartException implements Exception {
  const AntiiQRestartException(this.message);

  final String message;

  @override
  String toString() => message;
}

Future<void> restartAntiiQ() async {
  final result = await Restart.restartApp(mode: RestartMode.process);
  if (!result.success) {
    throw AntiiQRestartException(
      result.message ?? result.code ?? 'AntiiQ could not restart.',
    );
  }
}
