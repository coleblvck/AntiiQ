import 'package:antiiq/player/utilities/file_handling/metadata.dart';
import 'package:flutter/material.dart';

//Antiiq Packages
import 'package:antiiq/player/ui/elements/ui_elements.dart';
import 'package:antiiq/player/utilities/activity_handlers.dart';



class SwipedCard extends StatelessWidget {
  const SwipedCard({
    super.key,
    required this.track,
    required this.controller,
    required this.title,
  });

  final Track track;
  final PageController controller;
  final Widget title;

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      theme: AntiiQTheme.of(context).cardThemes.primary,
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      CustomButton(
                        function: () {
                          playOnlyThis(track.mediaItem!);
                          controller.jumpToPage(0);
                        },
                        style: ButtonStyles().style1,
                        child: const Text("Play Only"),
                      ),
                      const Padding(
                          padding: EdgeInsetsDirectional.only(end: 3)),
                      CustomButton(
                        function: () {
                          playTrackNext(track.mediaItem!);
                          controller.jumpToPage(0);
                        },
                        style: ButtonStyles().style2,
                        child: const Text("Play Next"),
                      ),
                      const Padding(
                          padding: EdgeInsetsDirectional.only(end: 3)),
                      CustomButton(
                        function: () {
                          addToQueue(track.mediaItem!);
                          controller.jumpToPage(0);
                        },
                        style: ButtonStyles().style3,
                        child: const Text("Play Later"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: CustomCard(
                theme: AntiiQTheme.of(context).cardThemes.background,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: title),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
