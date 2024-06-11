import 'package:antiiq/player/global_variables.dart';
import 'package:antiiq/player/utilities/user_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:remix_icon_icons/remix_icon_icons.dart';
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:restart_app/restart_app.dart';

class UserInterface extends StatefulWidget {
  const UserInterface({
    super.key,
  });
  @override
  State<UserInterface> createState() => _UserInterfaceState();
}

class _UserInterfaceState extends State<UserInterface> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 75,
          backgroundColor: AntiiQTheme.of(context).colorScheme.background,
          elevation: settingsPageAppBarElevation,
          surfaceTintColor: Colors.transparent,
          shadowColor: AntiiQTheme.of(context).colorScheme.onBackground,
          leading: IconButton(
            iconSize: settingsPageAppBarIconButtonSize,
            color: AntiiQTheme.of(context).colorScheme.secondary,
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: const Icon(RemixIcon.arrow_left),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text(
                "Interface",
                style: AntiiQTheme.of(context)
                    .textStyles
                    .onBackgroundLargeHeader
                    .copyWith(
                      color: AntiiQTheme.of(context).colorScheme.secondary,
                    ),
              ),
            ),
          ],
        ),
        backgroundColor: AntiiQTheme.of(context).colorScheme.background,
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 20,
                ),
              ),
              SliverToBoxAdapter(
                child: CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.background,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "Themes",
                      style: AntiiQTheme.of(context)
                          .textStyles
                          .onBackgroundLargeHeader,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1,
                ),
                delegate: SliverChildListDelegate(
                  [
                    for (String theme in customThemes.keys)
                      CustomCard(
                        theme: AntiiQTheme.of(context)
                            .cardThemes
                            .background
                            .copyWith(
                              color: customThemes[theme]!.background,
                            ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: CustomCard(
                            theme: AntiiQTheme.of(context)
                                .cardThemes
                                .background
                                .copyWith(
                                  color: customThemes[theme]!.surface,
                                ),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Text(
                                    theme,
                                    style: TextStyle(
                                      color: customThemes[theme]!.onSurface,
                                      fontSize: 15,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        height: 20,
                                        width: 20,
                                        color: customThemes[theme]!.primary,
                                      ),
                                      Container(
                                        height: 20,
                                        width: 20,
                                        color: customThemes[theme]!.secondary,
                                      ),
                                      Container(
                                        height: 20,
                                        width: 20,
                                        color: customThemes[theme]!.surface,
                                      ),
                                      Container(
                                        height: 20,
                                        width: 20,
                                        color: customThemes[theme]!.background,
                                      ),
                                    ],
                                  ),
                                  CustomButton(
                                    style: ButtonStyles().style1.copyWith(
                                          backgroundColor:
                                              WidgetStatePropertyAll(
                                            customThemes[theme]!.primary,
                                          ),
                                          foregroundColor:
                                              WidgetStatePropertyAll(
                                            customThemes[theme]!.onPrimary,
                                          ),
                                        ),
                                    function: () {
                                      changeTheme(theme);
                                    },
                                    child: const Text("Apply"),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                ),
              ),
              SliverToBoxAdapter(
                child: CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.primary,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            "Status Bar Mode:",
                            style: AntiiQTheme.of(context)
                                .textStyles
                                .onPrimaryText,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AntiiQTheme.of(context).colorScheme.surface,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentStatusBarMode !=
                                        StatusBarMode.defaultMode) {
                                      setStatusBarMode("default");
                                      setState(() {});
                                    }
                                  },
                                  child: Card(
                                    color: currentStatusBarMode ==
                                            StatusBarMode.defaultMode
                                        ? AntiiQTheme.of(context)
                                            .colorScheme
                                            .background
                                        : Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    surfaceTintColor: Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Default",
                                          style: TextStyle(
                                            color: AntiiQTheme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    if (currentStatusBarMode !=
                                        StatusBarMode.immersiveMode) {
                                      setStatusBarMode("immersive");
                                      setState(() {});
                                    }
                                  },
                                  child: Card(
                                    color: currentStatusBarMode ==
                                            StatusBarMode.immersiveMode
                                        ? AntiiQTheme.of(context)
                                            .colorScheme
                                            .background
                                        : Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    surfaceTintColor: Colors.transparent,
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Align(
                                        alignment: Alignment.center,
                                        child: Text(
                                          "Immersive",
                                          style: TextStyle(
                                            color: AntiiQTheme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Divider(
                  color: AntiiQTheme.of(context).colorScheme.primary,
                ),
              ),
              SliverToBoxAdapter(
                child: CustomCard(
                  theme: AntiiQTheme.of(context).cardThemes.surface,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          "UI Roundness",
                          style: AntiiQTheme.of(context)
                              .textStyles
                              .onBackgroundLargeHeader
                              .copyWith(
                                color:
                                    AntiiQTheme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text(
                          "The app will restart when you apply this setting.",
                          style: TextStyle(
                            color: AntiiQTheme.of(context)
                                .colorScheme
                                .onBackground,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: CustomButton(
                          style: ButtonStyles().style2,
                          function: () {
                            Restart.restartApp();
                          },
                          child: const Text("Apply"),
                        ),
                      ),
                      CustomCard(
                        theme: AntiiQTheme.of(context).cardThemes.background,
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                "Radius: ${generalRadius.round()}",
                                style: AntiiQTheme.of(context)
                                    .textStyles
                                    .onSurfaceText,
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                height: 20,
                                child: FlutterSlider(
                                    selectByTap: false,
                                    tooltip: FlutterSliderTooltip(
                                      disabled: true,
                                    ),
                                    handlerHeight: 20,
                                    handlerWidth: 5,
                                    step: const FlutterSliderStep(
                                        step: 5, isPercentRange: false),
                                    values: [generalRadius],
                                    min: 0,
                                    max: 25,
                                    handler: FlutterSliderHandler(
                                      decoration: BoxDecoration(
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .primary,
                                          borderRadius:
                                              BorderRadius.circular(5)),
                                      child: Container(),
                                    ),
                                    foregroundDecoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(1)),
                                    trackBar: FlutterSliderTrackBar(
                                      inactiveTrackBar: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .primary,
                                        border: Border.all(
                                          width: 3,
                                          color: AntiiQTheme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                      activeTrackBar: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                        color: AntiiQTheme.of(context)
                                            .colorScheme
                                            .secondary,
                                      ),
                                    ),
                                    onDragging: (handlerIndex, lowerValue,
                                            upperValue) =>
                                        {
                                          setState(() {
                                            setGeneralRadius(lowerValue);
                                          })
                                        }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
