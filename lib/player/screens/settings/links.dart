import 'package:url_launcher/url_launcher.dart';

class Links {
  String github = "https://github.com/coleblvck";
  String twitter = "https://x.com/talesofblvck";
  String email = "mailto:coleblvck@gmail.com";
  String antiiqCore = "https://antiiq.artatura.com";
  String antiiqSource = "https://codeberg.org/coleblvck/antiiq";
  String ffmpeg = "https://github.com/Artatura/AntiiQCore-FFmpeg";
  String soundTouch = "https://github.com/Artatura/AntiiQCore-SoundTouch";
}

final githubUri = Uri.parse(Links().github);
final twitterUri = Uri.parse(Links().twitter);
final emailUri = Uri.parse(Links().email);
final antiiqCoreUri = Uri.parse(Links().antiiqCore);
final antiiqSourceUri = Uri.parse(Links().antiiqSource);
final ffmpegUri = Uri.parse(Links().ffmpeg);
final soundTouchUri = Uri.parse(Links().soundTouch);

openLink(Uri link) async {
  await launchUrl(link);
}
