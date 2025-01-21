class Version {
  const Version({
    required this.version,
    required this.title,
    required this.date,
    required this.changes,
  });

  final String version;
  final String title;
  final String date;
  final List<String> changes;
}

List<Version> versions = [
  const Version(
    version: "1.4.3",
    title: "Melomaniac",
    date: "22-JAN-2025",
    changes: [
      "- Added setting for cover art fit",
      "- Some UI tweaks",
      "- Swipe left/right on cover art in album screen to jump to next or previous albums",
    ],
  ),
  const Version(
    version: "1.4.2",
    title: "Melomaniac",
    date: "1-JULY-2024",
    changes: [
      "- Improvements and BugFixes",
      "- No need for separate apply and restart when changing UI settings",
      "- Dynamic Colours for Android versions below 12",
      "- Amoled option for Dynamic Colour Theme",
    ],
  ),
  const Version(
    version: "1.4.1",
    title: "Melomaniac",
    date: "14-JUN-2024",
    changes: [
      "- Important tweaks and fixes",
      "- Dynamic Colours for Android 12 and above",
    ],
  ),
  const Version(
    version: "1.4.0",
    title: "Melomaniac",
    date: "12-JUN-2024",
    changes: [
      "- A more consistent & cleaner UI",
      "- Improved Search results including tracks from artist and album searches",
      "- Immersive mode toggle in settings",
      "- Custom Colour Theming",
    ],
  ),
  const Version(
    version: "1.3.2",
    title: "Melomaniac",
    date: "09-JUN-2024",
    changes: [
      "- Scan for folder image if embedded art is not present",
      "- Setting for back button exit mode",
      "- No need to restart app on theme apply (Experimental)",
      "- New themes (because... it was within reach...)",
      "- A more consistent UI",
    ],
  ),
  const Version(
    version: "1.3.0",
    title: "Melomaniac",
    date: "09-JUN-2024",
    changes: [
      "- Fixed music playback from File Manager accumulating very large cache storage usage",
      "- (Fix) Make audio stop after queue end",
      "- Fixed keyboard pop-up bug when going from search screen to now playing, to options and back",
      "- Other important bug fixes",
      "- A more consistent UI",
      "- New option for Tweaking general App roundness(radius) in settings",
      "- General improvements to playback from File Manager",
    ],
  ),
  const Version(
    version: "1.2.0",
    title: "Melomaniac",
    date: "05-JUN-2024",
    changes: [
      "- Important bug fixes",
      "- Added an option to show/hide currently playing track duration",
      "- Quit using back button",
      "- Added the ability to play tracks from the file manager and to set AntiiQ as the default music player",
    ],
  ),
  const Version(
    version: "1.0.8",
    title: "Early Bird",
    date: "15-FEB-2024",
    changes: [
      "- Added Favourites",
    ],
  ),
  const Version(
    version: "1.0.6",
    title: "Early Bird",
    date: "24-OCT-2023",
    changes: [
      "- Important UX improvements",
      "- Added Sort",
      "- Included Album Name match and Artist Name match in search results",
      "- Fixed Folder Selection",
    ],
  ),
  const Version(
    version: "1.0.5",
    title: "Early Bird",
    date: "21-OCT-2023",
    changes: [
      "- Important fixes to bugs and errors with selection list",
      "- Temporarily removed auto-runtime scan due to some glitches",
    ],
  ),
  const Version(
    version: "1.0.4",
    title: "Early Bird",
    date: "19-OCT-2023",
    changes: [
      "- Minor UI changes and  fixes",
      "- Added Automatic scanning during runtime and its related tweaks in settings",
      "- Added settings to enable/disable interactive Mini Player Seekbar",
      "- Added current queue 'remembrance', so tapping on the play button on start simply resumes previous queue if there was any",
      "- Added Global selection feature, so tracks can be selected from anywhere across the app (Except for Playlist and Search views) and used in various ways. This list can be accessed from its own menu on the main dashboard and is also 'remembered' on app close and reopen. Tapping on Cover Art still plays tracks when in this mode.",
    ],
  ),
  const Version(
    version: "1.0.2",
    title: "Early Bird",
    date: "17-OCT-2023",
    changes: [
      "- Automatic scanning of new music metadata without requiring a manual re-scan",
      "- Some UX fixes like scroll not working on the settings page",
      "- Additional UI/UX fixes and rearrangements.",
    ],
  ),
  const Version(
    version: "1.0.0",
    title: "Early Bird",
    date: "15-OCT-2023",
    changes: [
      "- First Release",
      "- All Features working on Android 13",
    ],
  ),
];
