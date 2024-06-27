import 'package:antiiq/player/ui/elements/ui_colours.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

pickAndCrop() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(
    source: ImageSource.gallery,
    maxHeight: 800,
    maxWidth: 800,
  );
  if (image != null) {
    final CroppedFile? croppedFile = await crop(image.path);
    if (croppedFile != null) {
      final croppedFileBytes = await croppedFile.readAsBytes();
      return croppedFileBytes;
    }
  }
}

Future<CroppedFile?> crop(String path) async {
  CroppedFile? croppedFile = await ImageCropper().cropImage(
    sourcePath: path,
    aspectRatioPresets: [
      CropAspectRatioPreset.square,
    ],
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: "Crop Image",
        toolbarColor: currentColorScheme.background,
        toolbarWidgetColor: currentColorScheme.primary,
        initAspectRatio: CropAspectRatioPreset.square,
        lockAspectRatio: true,
      ),
    ],
  );

  return croppedFile;
}
