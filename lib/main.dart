import 'package:antiiq/chaos/chaos_ui_state.dart';
import 'package:antiiq/chaos/dashboard.dart';
import 'package:antiiq/home_widget/home_widget_manager.dart';
import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/screens/main_screen/main_box.dart';
import 'package:antiiq/player/state/antiiq_state.dart';
import 'package:antiiq/player/state/ui_state.dart';
import 'package:antiiq/player/state/version_updates.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final antiiQState = await AntiiqState.create();

  final VersionUpdates versionUpdates = antiiQState.versionUpdates;

  final chaosUIState = ChaosUIState();
  await chaosUIState.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: antiiQState),
        ChangeNotifierProvider.value(value: chaosUIState),
        ChangeNotifierProvider.value(value: antiiQState.audioSetup.audioHandler),
        ChangeNotifierProvider(create: (_) => versionUpdates),
      ],
      child: const AntiiQ(),
    ),
  );
}

class AntiiQ extends StatefulWidget {
  const AntiiQ({Key? key}) : super(key: key);

  @override
  State<AntiiQ> createState() => _AntiiQState();
}

class _AntiiQState extends State<AntiiQ> with WidgetsBindingObserver {
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
      final mediaItem = globalAntiiqAudioHandler.mediaItem.value;
      final playbackState = globalAntiiqAudioHandler.playbackState.value;
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
            child: UIStateInitializer(
              child: MaterialApp(
                title: 'AntiiQ',
                debugShowCheckedModeBanner: false,
                theme: ThemeData.dark().copyWith(
                  scaffoldBackgroundColor: Colors.transparent,
                  primaryColor: currentColorScheme.primary,
                  scrollbarTheme: ScrollbarThemeData(
                    thumbColor:
                        WidgetStatePropertyAll(currentColorScheme.primary),
                    crossAxisMargin: 4,
                    mainAxisMargin: 4,
                  ),
                  textSelectionTheme: TextSelectionThemeData(
                    cursorColor: currentColorScheme.primary,
                    selectionColor:
                        currentColorScheme.primary.withValues(alpha: 0.4),
                    selectionHandleColor: currentColorScheme.primary,
                  ),
                ),
                home: Builder(builder: (context) {
                  final colors = AntiiQTheme.of(context).colorScheme;
                  final chaosUIState = context.watch<ChaosUIState>();
                  return Theme(
                    data: Theme.of(context).copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: WidgetStatePropertyAll(colors.primary),
                        crossAxisMargin: 4,
                        mainAxisMargin: 4,
                        interactive: true,
                        thickness: const WidgetStatePropertyAll(16),
                        radius:
                            Radius.circular(chaosUIState.getAdjustedRadius(8)),
                      ),
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: colors.primary,
                        selectionColor: colors.primary.withValues(alpha: 0.4),
                        selectionHandleColor: colors.primary,
                      ),
                    ),
                    child: chaosUIState.chaosUIStatus
                        ? const TypographyChaosDashboard()
                        : const MainBox(),
                  );
                }),
              ),
            ),
          );
        });
  }
}
