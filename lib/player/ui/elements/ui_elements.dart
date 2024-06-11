import 'package:flutter/material.dart';
import 'package:antiiq/player/ui/elements/ui_colours.dart';

class CustomCard extends StatelessWidget {
  final CardTheme theme;
  final Widget child;
  const CustomCard({
    Key? key,
    required this.theme,
    required this.child,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: theme.elevation ?? 5,
      shape: theme.shape ?? AntiiQTheme.of(context).cardThemes.background.shape,
      color: theme.color ?? AntiiQTheme.of(context).cardThemes.background.color,
      shadowColor: Colors.black,
      surfaceTintColor: theme.surfaceTintColor ?? Colors.transparent,
      child: child,
    );
  }
}

class CardThemes {
  final transparent = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: Colors.transparent,
    surfaceTintColor: Colors.transparent,
  );
  final primary = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.primary,
    surfaceTintColor: Colors.transparent,
  );
  final background = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
    surfaceTintColor: Colors.transparent,
  );
  final backgroundOverlay = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background.withAlpha(80),
    surfaceTintColor: Colors.transparent,
  );
  final surface = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.surface,
    surfaceTintColor: Colors.transparent,
  );
  final surfaceOverlay = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.surface.withAlpha(200),
    surfaceTintColor: Colors.transparent,
  );
}

const double generalCardElevation = 5;
late double generalRadius;

class CardShapes {
  var antiiqCardShape1 = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(generalRadius));
}

class CustomButton extends StatelessWidget {
  final Widget child;
  final ButtonStyle style;
  final Function function;
  const CustomButton({
    Key? key,
    required this.child,
    required this.style,
    required this.function,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        function();
      },
      style: style,
      child: child,
    );
  }
}

class AntiiQSwitch extends StatelessWidget {
  final Widget child;
  final ButtonStyle style;
  final Function function;
  const AntiiQSwitch({
    Key? key,
    required this.child,
    required this.style,
    required this.function,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        function();
      },
      style: style,
      child: child,
    );
  }
}

class ButtonStyles {
  final ButtonStyle style1 = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(currentColorScheme.background),
    foregroundColor: WidgetStatePropertyAll(currentColorScheme.primary),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(5),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(generalRadius),
      ),
    ),
    textStyle: WidgetStatePropertyAll(TextStyles().onPrimaryText),
  );
  final ButtonStyle style2 = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(currentColorScheme.primary),
    foregroundColor: WidgetStatePropertyAll(currentColorScheme.background),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(5),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(generalRadius),
      ),
    ),
    textStyle: WidgetStatePropertyAll(TextStyles().onBackgroundText),
  );
  final ButtonStyle style3 = ButtonStyle(
    backgroundColor: WidgetStatePropertyAll(currentColorScheme.secondary),
    foregroundColor: WidgetStatePropertyAll(currentColorScheme.onSecondary),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(5),
    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(generalRadius),
      ),
    ),
    textStyle: WidgetStatePropertyAll(TextStyles().onBackgroundText),
  );
}

class TextStyles {
  final TextStyle primaryText = TextStyle(
    color: currentColorScheme.primary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  final TextStyle onPrimaryText = TextStyle(
    color: currentColorScheme.onPrimary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  final TextStyle onSecondaryText = TextStyle(
    color: currentColorScheme.onSecondary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  final TextStyle onBackgroundText = TextStyle(
    color: currentColorScheme.onBackground,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  final TextStyle onSurfaceText = TextStyle(
    color: currentColorScheme.onSurface,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  final TextStyle onPrimaryTextBold = TextStyle(
    color: currentColorScheme.onPrimary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  final TextStyle onSecondaryTextBold = TextStyle(
    color: currentColorScheme.onSecondary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  final TextStyle onBackgroundTextBold = TextStyle(
    color: currentColorScheme.onBackground,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  final TextStyle onSurfaceTextBold = TextStyle(
    color: currentColorScheme.onSurface,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  final TextStyle onBackgroundLargeHeader = TextStyle(
    color: currentColorScheme.onBackground,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().largeHeader,
    overflow: TextOverflow.ellipsis,
  );

  final TextStyle onSurfaceLargeHeader = TextStyle(
    color: currentColorScheme.onSurface,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().largeHeader,
  );
}

class FontFamilies {
  String defaultFont = "Roboto";
}

class FontSizes {
  double defaultFontSize = 15;
  double largeHeader = 30;
}

class CustomProgressIndicator extends StatelessWidget {
  final double progress;
  const CustomProgressIndicator({
    Key? key,
    required this.progress,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      value: progress,
      color: AntiiQTheme.of(context).colorScheme.primary,
      backgroundColor: AntiiQTheme.of(context).colorScheme.surface,
    );
  }
}

class CustomInfiniteProgressIndicator extends StatelessWidget {
  const CustomInfiniteProgressIndicator({
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(
      color: AntiiQTheme.of(context).colorScheme.primary,
      backgroundColor: AntiiQTheme.of(context).colorScheme.background,
      strokeWidth: 10,
    );
  }
}

//class Logos {
//  String smallTransparent = "assets/logos/small_transparent.png";
//  String smallWideTransparent = "assets/logos/small_wide_transparent.png";
//}

class CustomAppBar extends AppBar {
  final Widget leadingWidget;
  final BuildContext context;
  final Widget titleWidget;
  final List<Widget> actionList;
  CustomAppBar({
    super.key,
    required this.leadingWidget,
    required this.context,
    required this.titleWidget,
    required this.actionList,
  }) : super(
          title: titleWidget,
          leading: leadingWidget,
          foregroundColor: AntiiQTheme.of(context).colorScheme.onBackground,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 40,
          backgroundColor: AntiiQTheme.of(context).colorScheme.background,
          elevation: generalCardElevation,
          actions: actionList,
        );
}

class AntiiQTheme extends InheritedWidget {
  AntiiQTheme({
    super.key,
    required super.child,
    required this.colorScheme,
  });

  final AntiiQColorScheme colorScheme;
  final CardThemes cardThemes = CardThemes();
  final TextStyles textStyles = TextStyles();
  final ButtonStyles buttonStyles = ButtonStyles();

  static AntiiQTheme? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AntiiQTheme>();
  }

  static AntiiQTheme of(BuildContext context) {
    final AntiiQTheme? result = maybeOf(context);
    assert(result != null, 'No AntiiQTheme found in context');
    return result!;
  }

  @override
  bool updateShouldNotify(AntiiQTheme oldWidget) {
    return oldWidget.colorScheme != colorScheme;
  }
}
