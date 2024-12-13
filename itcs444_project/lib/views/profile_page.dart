import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:Online_Exam_App/logic/attachment.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/views/login.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  Future<Map<String, dynamic>> fetchStatistics(String userId) async {
    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch registered exams from the user's document
      final userDoc = await firestore.collection('users').doc(userId).get();
      final registeredExams =
          (userDoc.data()?['registeredExams'] ?? []) as List<dynamic>;

      // Fetch all exam attempts from the examAttempts collection
      final attemptsSnapshot = await firestore
          .collection('examAttempts')
          .where('userId', isEqualTo: userId)
          .get();

      final attempts = attemptsSnapshot.docs.map((doc) => doc.data()).toList();

      int passedExams = 0;
      double totalPercentage = 0;
      int totalAttempts = attempts.length;

      for (var attempt in attempts) {
        final percentage = attempt['percentage'] ?? 0.0;
        if (percentage > 60) passedExams++;
        totalPercentage += percentage;
      }

      final avgScore =
          totalAttempts > 0 ? (totalPercentage / totalAttempts) : 0.0;

      return {
        'testsPassed': passedExams,
        'testsTaken': registeredExams.length,
        'avgScore': avgScore,
      };
    } catch (e) {
      return {
        'testsPassed': 0,
        'testsTaken': 0,
        'avgScore': 0.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      Future.microtask(() {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      });
      return Container();
    }

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchStatistics(currentUser.uid), // Fetch stats for the user
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final stats = snapshot.data!;
          final testsPassed = stats['testsPassed'];
          final testsTaken = stats['testsTaken'];
          final avgScore = stats['avgScore'];

          return Column(
            children: [
              SizedBox(height: 20),
              FutureBuilder<Uint8List?>(
                future: fetchImage(
                    'profileImgs/${currentUser.uid}/profile.jpg'), // Firebase Storage path
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.error, color: Colors.red),
                    );
                  } else if (snapshot.hasData) {
                    return CircleAvatar(
                      radius: 50,
                      backgroundImage: MemoryImage(
                          snapshot.data!), // Display the fetched image
                      child: null,
                    );
                  } else {
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[200],
                      child: Icon(Icons.person,
                          size: 50,
                          color: Colors.white), // Default icon when no image
                    );
                  }
                },
              ),
              SizedBox(height: 10),
              Text(
                // check this out it is the cause of not found after the name
                // "${currentUser.name} ${currentUser.avatarUrl}",

                // the above line should be replaced with the following line
                "${currentUser.name} ",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                currentUser.email,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatColumn('Tests Passed', '$testsPassed'),
                  _buildStatColumn('Tests Taken', '$testsTaken'),
                  _buildStatColumn(
                      'Avg. Score', '${avgScore.toStringAsFixed(1)}%'),
                ],
              ),
              SizedBox(height: 20),
              TextButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      TextEditingController newEmail =
                          TextEditingController(text: currentUser.email);
                      TextEditingController newName =
                          TextEditingController(text: currentUser.name);
                      XFile? selectedImage;
                      GlobalKey<FormState> formKey = GlobalKey();
                      bool isImageUploaded = false;

                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: Text('Update user info'),
                            content: Form(
                              key: formKey,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () async {
                                      final picker = ImagePicker();
                                      final pickedFile = await picker.pickImage(
                                          source: ImageSource.gallery);

                                      if (pickedFile != null) {
                                        setState(() {
                                          selectedImage = pickedFile;
                                          isImageUploaded = true;

                                          // Get the file extension
                                          String fileExtension =
                                              path.extension(pickedFile.path);
                                          print(
                                              'Selected image extension: $fileExtension');
                                        });
                                      }
                                    },
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        CircleAvatar(
                                          backgroundImage: selectedImage != null
                                              ? (kIsWeb
                                                  ? NetworkImage(
                                                      selectedImage!.path)
                                                  : FileImage(File(
                                                          selectedImage!.path))
                                                      as ImageProvider)
                                              : null,
                                          backgroundColor: isImageUploaded
                                              ? Colors.green
                                              : Colors.grey,
                                          radius: 50,
                                          child: selectedImage == null
                                              ? Icon(Icons.account_circle,
                                                  size: 50)
                                              : null,
                                        ),
                                        if (isImageUploaded)
                                          Positioned(
                                            bottom: 0,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              color:
                                                  Colors.black.withOpacity(0.6),
                                              child: Text(
                                                "Image Uploaded!",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  // TextFormField(
                                  //   controller: newEmail,
                                  //   validator: (value) => value!.isEmpty
                                  //       ? 'Email cannot be empty'
                                  //       : null,
                                  //   decoration:
                                  //       InputDecoration(labelText: 'Email'),
                                  // ),
                                  TextFormField(
                                    controller: newName,
                                    validator: (value) => value!.isEmpty
                                        ? 'Name cannot be empty'
                                        : null,
                                    decoration:
                                        InputDecoration(labelText: 'Name'),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () async {
                                  if (formKey.currentState!.validate()) {
                                    String? avatarUrl;
                                    if (selectedImage != null) {
                                      // Handle web and mobile uploads
                                      if (kIsWeb) {
                                        avatarUrl = await uploadImageWeb(
                                          selectedImage!,
                                          'profileImgs/${currentUser.uid}/profile.jpg',
                                        );
                                      } else {
                                        avatarUrl = await uploadImage(
                                          File(selectedImage!.path),
                                          'profileImgs/${currentUser.uid}/profile.jpg',
                                        );
                                      }

                                      // Update Firestore if avatar uploaded
                                      if (avatarUrl != null) {
                                        // Update the user info
                                        userProvider.updateCurrentUser(
                                            newEmail.text,
                                            newName.text,
                                            avatarUrl);
                                      } else {
                                        print(
                                            'Error: Failed to upload avatar.');
                                      }
                                    }
                                    userProvider.updateCurrentUser(
                                        newEmail.text, newName.text, "");
                                    Navigator.pop(context); // Close dialog
                                  }
                                },
                                child: Text('Save'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancel'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
                },
                icon: Icon(Icons.update),
                label: Text('Update Account Info'),
              ),
            ],
          );
        },
      ),
    );
  }

  Column _buildStatColumn(String label, String count) {
    return Column(
      children: [
        Text(count,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[600])),
      ],
    );
  }
}
