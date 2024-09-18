
import 'dart:io';
import 'package:image/image.dart' as img;
class ImageUtil{


  File compressAndResizeImage(File file) {
    img.Image? image = img.decodeImage(file.readAsBytesSync());
    // Resize the image to have the longer side be 800 pixels
    int width;
    int height;
    if (image!.width > image.height) {
      width = 800;
      height = (image.height / image.width * 800).round();
    } else {
      height = 800;
      width = (image.width / image.height * 800).round();
    }
    img.Image resizedImage = img.copyResize(image, width: width, height: height);
    // Compress the image with JPEG format
    List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 75);  // Adjust quality as needed
    // Save the compressed image to a file
    File compressedFile = File(file.path.replaceFirst('.jpg', '_compressed.jpg'));
    compressedFile.writeAsBytesSync(compressedBytes);
    return compressedFile;
  }

}