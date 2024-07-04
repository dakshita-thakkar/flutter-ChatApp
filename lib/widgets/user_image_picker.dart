import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class UserImagePicker extends StatefulWidget {
  const UserImagePicker({super.key, required this.onPickedImage});

  final void Function(File pickedImage) onPickedImage;

  @override
  State<UserImagePicker> createState() {
    return _UserImagePickerState();
  }
}

class _UserImagePickerState extends State<UserImagePicker> {
  File? _pickedImageFile;

  

  void _pickImageFromGallery() async {
    final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 50, maxWidth: 150);

if(pickedImage==null){
  return;
}
    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });
  }

  void _pickImageFromCamera() async {
    final pickedImage = await ImagePicker()
        .pickImage(source: ImageSource.camera, imageQuality: 50, maxWidth: 150);
if(pickedImage==null){
  return;
}
    setState(() {
      _pickedImageFile = File(pickedImage.path);
    });

    widget.onPickedImage(_pickedImageFile!);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: const Color.fromARGB(98, 158, 158, 158),
          foregroundImage: _pickedImageFile == null ? null : FileImage(_pickedImageFile!),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton.icon(
              onPressed: _pickImageFromCamera,
              label: Text(
                'Add Image',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              icon: const Icon(Icons.camera_alt_rounded),
            ),
            
            TextButton.icon(
              onPressed: _pickImageFromGallery,
              label: Text(
                'Upload Image',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              icon: const Icon(Icons.image_search_rounded),
            ),
          ],
        )
      ],
    );
  }
}
