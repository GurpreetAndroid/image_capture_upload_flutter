import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class ImageUpload extends StatefulWidget {
  const ImageUpload({Key? key}) : super(key: key);

  @override
  _ImageUploadState createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
  late File _image;
  ImagePicker imagePicker = ImagePicker();
  var placeholder = AssetImage('assets/img_default.png');
  bool capture = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white70,
        appBar: AppBar(title: const Text("Image Upload App"),),
        body: Column(
          children: [
            const SizedBox(height: 10,),
            const Text("Capture / Select Image from ", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600,),),
            const SizedBox(height: 10,),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              SizedBox(
                height: 100,
                width: 100,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Column(children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.camera_alt_outlined, size: 30, color: Colors.white,),
                    ),
                    Text("Camera", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,),)
                  ]),
                  onPressed: () => {
                    _imageFromCamera(),
                  },
                ),
              ),
              const SizedBox(width: 10,),
              SizedBox(
                height: 100,
                width: 100,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black54,
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Column(children: [
                    Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.photo_library_outlined, size: 30, color: Colors.white,),
                    ),
                    Text("Gallery", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w400,),)
                  ]),
                  onPressed: () => {
                    _imageFromGallery(),
                  },
                ),
              ),
            ]),
            const SizedBox(height: 20,),
            Container(
                child: capture == true
                    ? CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 5,
                        backgroundImage: FileImage(_image),
                        backgroundColor: Colors.transparent,
                      )
                    : CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 5,
                        backgroundImage: AssetImage('assets/img_default.png'),
                        backgroundColor: Colors.white60,
                      )),
            const SizedBox(height: 10,),
            Padding(
              padding: const EdgeInsets.all(30),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("UPLOAD IMAGE",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600,),
                ),
                onPressed: () => {
                  uploadImage()
                },
              ),
            ),
            const SizedBox(height: 10,),
          ],
        )
    );
  }

  _imageFromCamera() async {
    try {
      XFile? capturedImage = await imagePicker.pickImage(source: ImageSource.camera);
      final File imagePath = File(capturedImage!.path);
      if (capturedImage == null) {
        showAlert(bContext: context, title: "Error choosing file", content: "No file was selected");
      } else {
        setState(() {
          _image = imagePath;
          capture = true;

        });
        //Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayPicture(image: _image, context: context,)));
      }
    } catch (e) {
      showAlert(bContext: context, title: "Error capturing image file", content: e.toString());
    }
  }

  _imageFromGallery() async {
    XFile? uploadedImage = await imagePicker!.pickImage(source: ImageSource.gallery);
    final File imagePath = File(uploadedImage!.path);

    if (uploadedImage == null) {
      showAlert(bContext: context, title: "Error choosing file", content: "No file was selected");
    } else {
      setState(() {
        _image = imagePath;
        capture = true;
      });
      //Navigator.push(context, MaterialPageRoute(builder: (context) => DisplayPicture(image: _image, context: context,)));
    }
  }

  showAlert({BuildContext? bContext, String? title, String? content}) {
    return showDialog(
        context: bContext!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(
              title ?? "",
              style: const TextStyle(color: Colors.white),
            ),
            content: Text(content ?? ""),
            actions: [
              TextButton(onPressed: () => {Navigator.pop(context)}, child: const Text("Okay"))
            ],
          );
        });
  }


  Future<bool> uploadImage() async {
    try {
      String path = '/storage/emulated/0/MyApp/images';
      await Permission.manageExternalStorage.request();
      var stickDirectory = Directory(path);
      await stickDirectory.create(recursive: true);

      // copy the file to a new path
      File compressImg = await compressAndResizeImage(File(_image.path)).copy('$path/com_image1.png');
      // replace with your server url
      var urlInsertImage = "http://00.00.00.88:8989/manageProfile/addProfileImage";
      // replace with your auth token, if present, else no need to add token..
      String token = "Bearer eyJh.............rDA";
      Map<String, String> headers = { "Authorization": token};

      var request = http.MultipartRequest("POST", Uri.parse(urlInsertImage));
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes("file", compressImg.readAsBytesSync(),filename: _image.path));
      var response = await request.send();

      try {
        var res = await http.Response.fromStream(response);
        if (res.statusCode == 200) {
          debugPrint("SUCCESS! 200 HTTP");
        }
      } catch (e, s) {
        debugPrint("$e __ $s");
      }
      return true;
    } catch (e) {
      debugPrint(e.toString());
    }
    return false;
  }


  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      var result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      }
    }
    return false;
  }



  File compressAndResizeImage(File file) {
    img.Image? image = img.decodeImage(file.readAsBytesSync());
    // Resize the image to have the longer side be 800 pixels
    int width;
    int height;
    if (image!.width > image!.height) {
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
