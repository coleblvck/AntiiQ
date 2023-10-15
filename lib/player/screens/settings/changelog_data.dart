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
    version: "1.0.0",
    title: "Early Bird",
    date: "15-OCT-2023",
    changes: [
      "- First Release",
      "- All Features working on Android 13",
    ],
  ),
];
