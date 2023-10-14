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
      shape: theme.shape ?? Theme.of(context).cardTheme.shape,
      color: theme.color ?? Theme.of(context).cardTheme.color,
      shadowColor: Colors.black,
      surfaceTintColor: theme.surfaceTintColor ?? Colors.transparent,
      child: child,
    );
  }
}

class CardThemes {
  final bottomNavBarTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final miniPlayerCardTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final nowPlayingTopCardTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final nowPlayingMainCardTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final nowPlayingArtOverlayTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background.withAlpha(80),
  );
  final nowPlayingRepeatShuffleTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.surface.withAlpha(200),
  );
  final dashboardItemTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final listHeaderTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final songsItemTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final albumSongsItemTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.surface,
  );
  final songsItemSwipedTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.primary,
  );
  final smallCardOnArtTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final bottomSheetListHeaderTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );
  final settingsItemTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
    surfaceTintColor: currentColorScheme.surface,
  );
  final genreGridItemTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.primary,
  );
  final searchBoxTheme = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.surface,
  );
  final bgColor = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.background,
  );

  final surfaceColor = CardTheme(
    shape: CardShapes().antiiqCardShape1,
    elevation: generalCardElevation,
    color: currentColorScheme.surface,
  );
}

const double generalCardElevation = 5;

class CardShapes {
  var antiiqCardShape1 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));

  var antiiqCardShape2 =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
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

class ButtonStyles {
  ButtonStyle style1 = ButtonStyle(
    backgroundColor: MaterialStatePropertyAll(currentColorScheme.background),
    foregroundColor: MaterialStatePropertyAll(currentColorScheme.primary),
    elevation: const MaterialStatePropertyAll(5),
    padding:
        const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 5)),
    shape: MaterialStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    textStyle: MaterialStatePropertyAll(TextStyles().onPrimaryText),
  );
  ButtonStyle style2 = ButtonStyle(
    backgroundColor: MaterialStatePropertyAll(currentColorScheme.primary),
    foregroundColor: MaterialStatePropertyAll(currentColorScheme.background),
    elevation: const MaterialStatePropertyAll(5),
    padding:
        const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 5)),
    shape: MaterialStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    textStyle: MaterialStatePropertyAll(TextStyles().onBackgroundText),
  );
  ButtonStyle style3 = ButtonStyle(
    backgroundColor: MaterialStatePropertyAll(currentColorScheme.secondary),
    foregroundColor: MaterialStatePropertyAll(currentColorScheme.onSecondary),
    elevation: const MaterialStatePropertyAll(5),
    padding:
        const MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 5)),
    shape: MaterialStatePropertyAll(
      RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    textStyle: MaterialStatePropertyAll(TextStyles().onBackgroundText),
  );
}

class TextStyles {
  TextStyle onPrimaryText = TextStyle(
    color: currentColorScheme.onPrimary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  TextStyle onSecondaryText = TextStyle(
    color: currentColorScheme.onSecondary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  TextStyle onBackgroundText = TextStyle(
    color: currentColorScheme.onBackground,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  TextStyle onSurfaceText = TextStyle(
    color: currentColorScheme.onSurface,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
  );

  TextStyle onPrimaryTextBold = TextStyle(
    color: currentColorScheme.onPrimary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  TextStyle onSecondaryTextBold = TextStyle(
    color: currentColorScheme.onSecondary,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  TextStyle onBackgroundTextBold = TextStyle(
    color: currentColorScheme.onBackground,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );

  TextStyle onSurfaceTextBold = TextStyle(
    color: currentColorScheme.onSurface,
    fontFamily: FontFamilies().defaultFont,
    fontSize: FontSizes().defaultFontSize,
    fontWeight: FontWeight.bold,
  );
}

class FontFamilies {
  String defaultFont = "monospace";
}

class FontSizes {
  double defaultFontSize = 15;
  double headerTitleSize = 20;
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
      color: Theme.of(context).colorScheme.primary,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
      color: Theme.of(context).colorScheme.inversePrimary,
      backgroundColor: Theme.of(context).colorScheme.background,
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
          foregroundColor: Theme.of(context).colorScheme.onBackground,
          shadowColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 40,
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: generalCardElevation,
          actions: actionList,
        );
}
