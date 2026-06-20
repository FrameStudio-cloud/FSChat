import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';

Future<bool> saveImageToGallery(String url) async {
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) return false;
    final dir = await getTemporaryDirectory();
    final file =
        File('${dir.path}/fschat_${DateTime.now().millisecondsSinceEpoch}.jpg');
    await file.writeAsBytes(response.bodyBytes);
    final result = await ImageGallerySaverPlus.saveFile(file.path);
    await file.delete();
    return result != null && result['isSuccess'] == true;
  } catch (_) {
    return false;
  }
}
