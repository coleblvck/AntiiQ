import 'package:antiiq/home_widget/home_widget_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/main_screen/main_box.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await AntiiqState.create();
  runApp(const Antiiq());
}

class Antiiq extends StatefulWidget {
  const Antiiq({super.key});

  @override
  State<Antiiq> createState() => _AntiiqState();
}

class _AntiiqState extends State<Antiiq> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeWidgetManager.initialize();
  }

  @override
  void dispose() {
    HomeWidgetManager.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final mediaItem = audioHandler.mediaItem.value;
      final playbackState = audioHandler.playbackState.value;
      if (mediaItem != null) {
        HomeWidgetManager.updateWidgetInfo(
          mediaItem,
          playbackState.playing,
          playbackState.position,
          mediaItem.duration ?? Duration.zero,
        );
      }
    } else if (state == AppLifecycleState.resumed) {
      HomeWidget.getWidgetData<String>('last_action').then((action) {
        if (action != null) {
          Uri uri = Uri.parse('antiiqwidget://$action');
          HomeWidgetManager.handleWidgetClicked(uri);
          HomeWidget.saveWidgetData<String>('last_action', null);
        }
      });
    }
  }

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
