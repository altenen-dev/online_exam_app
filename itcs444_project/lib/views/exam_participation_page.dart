import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Online_Exam_App/logic/ExamSearchDelegate.dart';
import 'package:Online_Exam_App/views/grading_page.dart';
import 'package:Online_Exam_App/views/solved_exam_page.dart';
import 'package:provider/provider.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/views/exam_taking_page.dart';

class ExamParticipationPage extends StatelessWidget {
  const ExamParticipationPage({super.key});

  // get all user's attempts for a given exam
  Future<int> getTotalUserAttempts(String examId, String userId) async {
    try {
      // Reference to Firestore collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('examAttempts')
          .where('examId', isEqualTo: examId)
          .where('userId', isEqualTo: userId)
          .where('completedAt', isNull: false)
          .get();

      // Return the count of documents that match the query
      return querySnapshot.docs.length;
    } catch (e) {
      // Handle errors
      return 0; // Return 0 in case of an error
    }
  }

  // get the max attempts for a given exam
  Future<int> getMaxExamAttempts(String examId) async {
    try {
      final examDoc = await FirebaseFirestore.instance
          .collection('exams')
          .doc(examId)
          .get();

      return examDoc['maxAttempts'] as int;
    } catch (e) {
      return 0; // Return 0 if an error occurs
    }
  }

  // returns true if the number of attempts for the given exam is less than the max exam attempts
  Future<bool> checkAttempts(String examId, String uid) async {
    var userAttempts = await getTotalUserAttempts(examId, uid);
    var examAttempts = await getMaxExamAttempts(examId);

    if (examAttempts != 0 && userAttempts < examAttempts) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final examProvider = Provider.of<ExamProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final role = userProvider.currentUser!.role;
    final adminId = role == 'admin' ? userProvider.currentUser!.uid : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Available Exams'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              final userProvider =
                  Provider.of<UserProvider>(context, listen: false);

              showSearch(
                context: context,
                delegate: ExamSearchDelegate(
                  role: role,
                  adminId: adminId,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: examProvider.getExamsStream(role: role, adminId: adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: Internal Server Error'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No exams available.'));
          }

          final exams = snapshot.data!.docs;
          if (exams.isEmpty) {
            return Center(
                child: Text('No exams found search for something else'));
          }
          return ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final bool isRegistered =
                  userProvider.currentUser!.registeredExams.contains(exam.id);
              Timestamp endStamp = exam['end'];
              DateTime end = endStamp.toDate();

              if (userProvider.currentUser?.role == 'student' &&
                  (DateTime.now().isBefore(end))) {
                return null;
              }
              return Card(
                margin: EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text(exam['title'] ?? 'No Title'),
                  subtitle: Text(
                      'Duration: ${exam['duration']} minutes, ends: ${exam['end ']}  '),
                  trailing: role != "admin"
                      ? ElevatedButton(
                          onPressed: isRegistered
                              ? () async {
                                  showDialog(
                                    barrierDismissible: false,
                                    context: context,
                                    builder: (BuildContext context) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    },
                                  );
                                  var examInstance;
                                  // the load
                                  try {
                                    examInstance =
                                        await Exam.fromFirestore(exam);
                                    ;
                                  } catch (e) {
                                    // Handle any errors that occur during fetch
                                  } finally {
                                    if (context.mounted) {
                                      Navigator.of(context)
                                          .pop(); // Close the loading dialog
                                    }
                                  }
                                  bool canAttempt = await checkAttempts(
                                      exam.id, userProvider.currentUser!.uid);
                                  if (!canAttempt) {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('No Attempts Left'),
                                        content: Text(
                                            'You have no more attempts for this exam.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context)
                                                  .pop(); // Close the dialog
                                            },
                                            child: Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                  // Show a loading dialog

// Await the result of getExamById
                                  if (examInstance != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            ExamTakingPage(exam: examInstance),
                                      ),
                                    );
                                    return;
                                  }
                                  Exam? examToProcess;

// Check if examToProcess is not null before navigating
                                  if (examToProcess != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExamTakingPage(
                                            exam: examToProcess!),
                                      ),
                                    );
                                  } else {
                                    // Show an error dialog or message if examToProcess is null
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Error'),
                                        content: Text(
                                            'Failed to load the exam. Please try again later.'),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                            child: Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                }
                              : () async {
                                  // Show loading indicator
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (BuildContext context) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    },
                                  );

                                  try {
                                    // Await the registration process
                                    await userProvider.registerForExam(exam.id);

                                    // Registration successful, close the loading dialog
                                    if (context.mounted) {
                                      Navigator.of(context)
                                          .pop(); // Close the loading dialog
                                    }

                                    // Optionally, provide user feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          backgroundColor: Colors.green,
                                          content: Text(
                                            'Successfully registered for the exam.',
                                            style:
                                                TextStyle(color: Colors.white),
                                          )),
                                    );
                                    (context as Element).markNeedsBuild();

                                    // If navigation or state updates are required, handle them here
                                  } catch (e) {
                                    // Handle any errors that occur during registration

                                    // Close the loading dialog
                                    if (context.mounted) {
                                      Navigator.of(context)
                                          .pop(); // Close the loading dialog

                                      // Show an error dialog to inform the user
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text('Registration Failed'),
                                          content: Text(
                                              'Failed to register for the exam. Please try again later.'),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(),
                                              child: Text('Close'),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                  }
                                },
                          child: Text(isRegistered ? 'Start Exam' : 'Register'),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () async {
                                await examProvider.hideExam(exam.id);

                                Future.delayed(Duration(milliseconds: 100), () {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Exam hidden successfully'),
                                      ),
                                    );
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.assessment),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AttemptsPage(
                                      examId: exam.id,
                                      examTitle: exam['title'] ?? 'No Title',
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
