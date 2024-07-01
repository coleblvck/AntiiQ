import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/main_screen/main_box.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AntiiqState.create();
  runApp(const Antiiq());
}

class Antiiq extends StatelessWidget {
  const Antiiq({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AntiiQColorScheme>(
      stream: themeStream.stream,
      builder: (context, snapshot) {
        return AntiiQTheme(
          colorScheme: snapshot.data ?? getColorScheme(),
          child: MaterialApp(
            title: 'AntiiQ',
            theme: ThemeData(
              textSelectionTheme: TextSelectionThemeData(
                cursorColor: currentColorScheme.primary,
                selectionColor: currentColorScheme.primary,
                selectionHandleColor: currentColorScheme.primary,
              ),
            ),
            debugShowCheckedModeBanner: false,
            home: const MainBox(),
          ),
        );
      },
    );
  }
}
