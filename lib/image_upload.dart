import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'image_util.dart';

class ImageUpload extends StatefulWidget {
  const ImageUpload({super.key});

  @override
  _ImageUploadState createState() => _ImageUploadState();
}

class _ImageUploadState extends State<ImageUpload> {
    File? selectedImage;
  ImagePicker imagePicker = ImagePicker();
  bool isImageSelected = false;

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
                    pickFromCamera(),
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
                    pickFromGallery(),
                  },
                ),
              ),
            ]),
            const SizedBox(height: 20,),
            Container(
                child: isImageSelected == true
                    ? CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 5,
                        backgroundImage: FileImage(selectedImage!),
                        backgroundColor: Colors.transparent,
                      )
                    : CircleAvatar(
                        radius: MediaQuery.of(context).size.width / 5,
                        backgroundImage: const AssetImage('assets/img_default.png'),
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
                  if(isImageSelected == false){
                    showAlert(context: context, title: "Error Image Upload", content: "No file was selected")
                  } else {
                    uploadImage()
                  }
                },
              ),
            ),
            const SizedBox(height: 10,),
          ],
        )
    );
  }

  pickFromCamera() async {
    try {
      XFile? capturedImage = await imagePicker.pickImage(source: ImageSource.camera);
      final File imagePath = File(capturedImage!.path);
      setState(() {
        selectedImage = imagePath;
        isImageSelected = true;
      });
    } catch (e) {
      showAlert(context: context, title: "Error capturing image file", content: e.toString());
    }
  }

  pickFromGallery() async {
    XFile? uploadedImage = await imagePicker.pickImage(source: ImageSource.gallery);
    final File imagePath = File(uploadedImage!.path);
    setState(() {
      selectedImage = imagePath;
      isImageSelected = true;
    });
  }

  showAlert({BuildContext? context, String? title, String? content}) {
    return showDialog(
        context: context!,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(title! , style: const TextStyle(color: Colors.black87),),
            content: Text(content! ),
            actions: [
              TextButton(onPressed: () => {Navigator.pop(context)}, child: const Text("OK"))
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
      File compressImg = await ImageUtil().compressAndResizeImage(File(selectedImage!.path)).copy('$path/com_image1.png');
      // replace with your server url
      var urlInsertImage = "http://00.00.00.88:8989/manageProfile/addProfileImage";
      // replace with your auth token, if present, else no need to add token..
      String token = "Bearer eyJh.............rDA";
      Map<String, String> headers = { "Authorization": token};

      var request = http.MultipartRequest("POST", Uri.parse(urlInsertImage));
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes("file", compressImg.readAsBytesSync(),filename: selectedImage!.path));
      var response = await request.send();

      try {
        var res = await http.Response.fromStream(response);
        if (res.statusCode == 200) {
          debugPrint("SUCCESS! 200 HTTP");
          // don't forget to reset value here..
          isImageSelected = false;
          selectedImage = null;
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
}
