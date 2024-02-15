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
      "- Temporarilty removed auto-runtime scan due to some glitches",
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
