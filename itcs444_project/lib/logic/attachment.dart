import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

// Function to upload the image to Firebase Storage
Future<String?> uploadImage(File file, String path) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = await storageRef.putFile(file);
    return await storageRef.getDownloadURL();
  } catch (e) {
    return null;
  }
}

// Overloaded function for web compatibility (using XFile)
Future<String?> uploadImageWeb(XFile xfile, String path) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final uploadTask = await storageRef.putData(await xfile.readAsBytes());
    return await storageRef.getDownloadURL();
  } catch (e) {
    return null;
  }
}

// Function to update Firestore with user info
Future<void> updateFirestoreUserAvatar(String userId, String avatarUrl) async {
  try {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    await userDoc.update({
      'avatarUrl': avatarUrl,
    });
  } catch (e) {}
}

Future<Uint8List?> fetchImage(String path) async {
  try {
    final storageRef = FirebaseStorage.instance.ref().child(path);
    final downloadImg = await storageRef.getData();
    return downloadImg;
  } catch (e) {
    return null;
  }
}

Future<String> getImageUrl(String imagePath) async {
  final ref = FirebaseStorage.instance.ref().child(imagePath);
  return await ref.getDownloadURL();
}
