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
