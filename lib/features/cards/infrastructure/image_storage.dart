import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';

class ImageStorage {
  // 画像を保存するディレクトリを取得
  static Future<Directory> getImageDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDir = Directory('${directory.path}/card_images');
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }
    return imageDir;
  }

  // 画像を保存
  static Future<String?> saveImage(File imageFile, String cardId) async {
    try {
      final imageDir = await getImageDirectory();
      final fileName = 'card_$cardId.jpg';
      final savedFile = await imageFile.copy('${imageDir.path}/$fileName');
      return savedFile.path;
    } catch (e) {
      return null;
    }
  }

  // 画像を削除
  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath != null) {
      try {
        final file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        // エラーは無視
      }
    }
  }

  // 画像を選択（カメラまたはギャラリー）
  static Future<File?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}

