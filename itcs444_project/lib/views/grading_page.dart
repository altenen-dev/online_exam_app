import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Online_Exam_App/logic/attachment.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:provider/provider.dart';

class AssementPage extends StatefulWidget {
  const AssementPage({super.key});

  @override
  State<AssementPage> createState() => _AssementPageState();
}

class _AssementPageState extends State<AssementPage> {
  final db = FirebaseFirestore.instance;

  // Fetch all exams created by this teacher
  Future<QuerySnapshot?> getAllExamsByCreator(String uid) async {
    try {
      CollectionReference examsRef = db.collection('exams');
      QuerySnapshot exams = await examsRef
          .where('creatorId', isEqualTo: uid) // Filter exams by creatorId
          .get();
      return exams;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    if (currentUser == null) {
      return Scaffold(
        body: Center(
            child:
                Text('You must be logged in as a teacher to view this page.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Assesment Page')),
      body: FutureBuilder<QuerySnapshot?>(
        future: getAllExamsByCreator(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching exams.'));
          } else if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No exams found.'));
          }

          final exams = snapshot.data!.docs;
          return ListView.builder(
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(exam['title'] ?? 'No Title'),
                  subtitle: Text('Exam ID: ${exam.id}'),
                  trailing: IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AttemptsPage(
                                examId: exam.id, examTitle: exam['title']),
                          ),
                        );
                      },
                      icon: Icon(Icons.assessment_rounded)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AttemptsPage extends StatefulWidget {
  final String examId;
  final String examTitle;

  AttemptsPage({super.key, required this.examId, required this.examTitle});

  @override
  State<AttemptsPage> createState() => _AttemptsPageState();
}

class _AttemptsPageState extends State<AttemptsPage> {
  final db = FirebaseFirestore.instance;
  // Fetch the username based on userId
  Future<String?> getUsername(String userID) async {
    try {
      // Reference to the users collection
      CollectionReference users = db.collection('users');

      // Get the user document with the userID as the document ID
      DocumentSnapshot snapshot = await users.doc(userID).get();

      // Check if the document exists and extract the 'name' field
      if (snapshot.exists) {
        return snapshot['name'] ??
            ''; // Return the 'name' field or empty string if not found
      } else {
        return null; // Document not found
      }
    } catch (e) {
      print('Error fetching username: ${e.toString()}');
      return null;
    }
  }

  // Fetch the latest attempt for each user for a specific exam
  Future<List<QueryDocumentSnapshot>> getLatestAttemptsForExam(
      String examId) async {
    try {
      QuerySnapshot attemptsSnapshot = await db
          .collection('examAttempts')
          .where('examId', isEqualTo: examId)
          .orderBy('completedAt', descending: true)
          .get();

      final Map<String, QueryDocumentSnapshot> latestAttempts = {};
      for (var attempt in attemptsSnapshot.docs) {
        final userId = attempt['userId'];
        if (!latestAttempts.containsKey(userId)) {
          latestAttempts[userId] = attempt;
        }
      }
      return latestAttempts.values.toList();
    } catch (e) {
      print('Error fetching attempts: ${e.toString()}');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attempts for ${widget.examTitle}'),
      ),
      body: FutureBuilder(
        future: getLatestAttemptsForExam(widget.examId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error fetching attempts.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No attempts found for this exam.'));
          }

          final attempts = snapshot.data!;

          return ListView.builder(
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              final userId = attempt['userId'];

              return FutureBuilder<String?>(
                future: getUsername(
                    userId), // Asynchronously fetch username for each userId
                builder: (context, usernameSnapshot) {
                  if (usernameSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Loading...'),
                        subtitle: Text('Score: ${attempt['score']}'),
                        trailing: Text(
                            '${attempt['percentage'].toStringAsFixed(2)}%'),
                      ),
                    );
                  } else if (usernameSnapshot.hasError) {
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Error loading username'),
                        subtitle: Text('Score: ${attempt['score']}'),
                        trailing: Text(
                            '${attempt['percentage'].toStringAsFixed(2)}%'),
                      ),
                    );
                  } else if (usernameSnapshot.hasData &&
                      usernameSnapshot.data != null) {
                    final username = usernameSnapshot.data!;
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('Student name: $username'),
                        subtitle: Text('Score: ${attempt['score']}'),
                        trailing: Text(
                            '${attempt['percentage'].toStringAsFixed(2)}%'),
                        onTap: () async {
                          final rebuilt = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (builder) => GradingPage(
                                      examId: widget.examId,
                                      userId: userId,
                                      attemptId: attempt.id,
                                      initailScore: attempt['score'],
                                    )),
                          );
                          if (rebuilt) {
                            setState(() {});
                          }
                        },
                      ),
                    );
                  } else {
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        title: Text('No username found'),
                        subtitle: Text('Score: ${attempt['score']}'),
                        trailing: Text('${attempt['percentage']}%'),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

class GradingPage extends StatefulWidget {
  final String examId;
  final String userId;
  final String attemptId;
  double initailScore;

  GradingPage({
    super.key,
    required this.examId,
    required this.userId,
    required this.attemptId,
    required this.initailScore,
  });

  @override
  State<GradingPage> createState() => _GradingPageState();
}

class _GradingPageState extends State<GradingPage> {
  final List<double> grades = [];
  double newGrade = 0;
  int questionIndex = -1;
  late double totalGrades;
  GlobalKey<FormState> formKey = GlobalKey();
  var globalTotalMark;
  var questions;
  var feedback = '';
  final db = FirebaseFirestore.instance;

  initState() {
    totalGrades = widget.initailScore;
  }

  /// Fetch all questions for the exam
  Future<List<Map<String, dynamic>>> fetchQuestions(String examId) async {
    try {
      QuerySnapshot snapshot = await db
          .collection('exams')
          .doc(examId)
          .collection('questions')
          .get();

      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data() as Map);
        return {
          'id': doc.id,
          'text': data['text'],
          'type': data['type'],
          'marks': data['marks'],
          'image path': data['image path'],
          'correct answer': data['correct answer'],
        };
      }).toList();
    } catch (e) {
      print('Error fetching questions: $e');
      return [];
    }
  }

  /// Fetch the student's attempt data
  Future<Map<String, dynamic>?> fetchStudentAttempt(String attemptId) async {
    try {
      final snapshot = await db.collection('examAttempts').doc(attemptId).get();
      if (snapshot.exists) {
        return Map<String, dynamic>.from(snapshot.data() as Map);
      }
    } catch (e) {
      print('Error fetching student attempt: $e');
    }
    return null;
  }

  Future<void> sendFeedback(String attemptId, String feedback) async {
    try {
      final attemptRef = db.collection('examAttempts').doc(attemptId);

      final attemptDoc = await attemptRef.get();
      if (attemptDoc.exists) {
        if (feedback != '') {
          await attemptRef.update({
            'feedback': feedback,
          });
        }

        print('Grades updated successfully!');
      } else {
        print('Attempt document not found');
      }
    } catch (e) {
      print('Error updating grades: $e');
    }
  }

  Future<void> updateGrades(
      String attemptId, double grade, qInedx, double totalMarks) async {
    try {
      final attemptRef = db.collection('examAttempts').doc(attemptId);

      // Fetch the current attempt document
      final attemptDoc = await attemptRef.get();
      if (attemptDoc.exists) {
        // Get the current answers array from the document
        List<dynamic> currentAnswers = attemptDoc['answers'];
        currentAnswers[qInedx]['grade'] = grade;
        // After updating the grades, update the document in Firestore
        await attemptRef.update({
          'answers': currentAnswers,
        });
        double totalGrade = await fetchTotalGrade(attemptId);
        //totalGrade += grade;

        await attemptRef.update({
          'score': totalGrade,
          'percentage': totalGrade / totalMarks * 100,
          'examMarks': totalMarks,
        });

        print('Grades updated successfully!');
      } else {
        print('Attempt document not found');
      }
    } catch (e) {
      print('Error updating grades: $e');
    }
  }

  Future<void> updateTotal(String attId) async {
    totalGrades = await fetchTotalGrade(attId);
  }

  Future<double> fetchTotalGrade(String attemptId) async {
    try {
      double totalGrade = 0;
      var attemptRef = db.collection('examAttempts').doc(attemptId);
      final attemptSnapshot = await attemptRef.get();

      // Check if the document exists
      if (!attemptSnapshot.exists) {
        throw Exception(
            'Error while detching totalGrade: Attempt document not found');
      }

      // Fetch and validate the answers array
      var answers = attemptSnapshot.data()?['answers'] as List<dynamic>? ?? [];
      for (var answer in answers) {
        // Safely add the grade, ensuring it is treated as a double
        totalGrade += (answer['grade'])?.toDouble() ?? 0.0;
      }

      return totalGrade;
    } catch (e) {
      print('Error fetching total grade: $e');
      return -1.0; // Return a default value on error
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController feedController = TextEditingController();
    return Scaffold(
      appBar: AppBar(
        title: Text('Grading'),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, true);
            //   Navigator.pop(context);
            //   Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back),
          color: Colors.black,
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([
          fetchQuestions(widget.examId),
          fetchStudentAttempt(widget.attemptId),
        ]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || snapshot.data == null) {
            return Center(child: Text('Error loading data.'));
          }
          print('getting all grades for attempt ${widget.userId}');
          final List<Map<String, dynamic>> questions =
              List<Map<String, dynamic>>.from(snapshot.data![0] as List);
          final attempt = Map<String, dynamic>.from(snapshot.data![1] ?? {});
          return StatefulBuilder(
            builder: (context, setState) {
              var totalMarks = questions.fold(
                0.0,
                (sum, question) => sum + (question['marks'] ?? 0),
              );
              globalTotalMark = totalMarks;
              updateTotal(widget.attemptId);
              return Column(
                children: [
                  Expanded(
                    child: Form(
                      key: formKey,
                      child: ListView.builder(
                        itemCount: questions.length,
                        itemBuilder: (context, index) {
                          final question = questions[index];
                          grades.add(attempt['answers'][index]['grade']);
                          final currentQuestionMarks = question['marks'] ?? 0;
                          final gradeController = TextEditingController(
                            text: grades[index].toString(),
                          );
                          return Card(
                            margin: EdgeInsets.all(8),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Q${index + 1}: ${question['text']} ${grades[index]}/$currentQuestionMarks',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (question['image path'] != null)
                                    FutureBuilder<String>(
                                      future:
                                          getImageUrl(question['image path']),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState ==
                                            ConnectionState.waiting) {
                                          return CircularProgressIndicator();
                                        } else if (snapshot.hasError) {
                                          return Text('Error loading image');
                                        } else if (snapshot.hasData) {
                                          return Image.network(snapshot.data!);
                                        } else {
                                          return SizedBox();
                                        }
                                      },
                                    ),
                                  SizedBox(height: 8),
                                  Text(
                                      'Student Answer: ${attempt['answers'][index]['answer']}, Correct Answer: ${question['correct answer']}'),
                                  SizedBox(height: 8),
                                  if (['short answer', 'essay']
                                      .contains(question['type'])) ...[
                                    Text('Grade this Question:'),
                                    TextFormField(
                                      validator: (value) {
                                        double v =
                                            double.tryParse(value!) ?? 0.0;
                                        print(
                                            'the number $v and the marks is ${question['marks']}');
                                        if (v > question['marks'] || v < 0) {
                                          return 'Enter a valid grade less than or equal to assigned marks.';
                                        }
                                        return null;
                                      },
                                      controller: gradeController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        border: OutlineInputBorder(),
                                        hintText: 'Enter marks',
                                      ),
                                      onChanged: (value) async {
                                        final grade =
                                            double.tryParse(value) ?? 0.0;
                                        // Update the grades map
                                        newGrade = grade;
                                        questionIndex = index;
                                        if (!formKey.currentState!.validate()) {
                                          return;
                                        } else {
                                          grades[index] = newGrade;
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                            content: Text('Grade Updated!'),
                                            duration: Duration(seconds: 2),
                                            backgroundColor: Colors.lightGreen,
                                          ));
                                        }
                                        await updateGrades(
                                            widget.attemptId,
                                            newGrade,
                                            questionIndex,
                                            globalTotalMark);
                                        totalGrades = await fetchTotalGrade(
                                            widget.attemptId);
                                        setState(() {});
                                        print(totalGrades);
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Total: $totalGrades/$totalMarks (Save to Update)', //change
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )),
                  // add 2 floating here
                  Row(
                    children: [
                      // FloatingActionButton(
                      //   onPressed: () async {
                      //     // Show the updated total in a dialog
                      //     showDialog(
                      //       context: context,
                      //       builder: (context) => AlertDialog(
                      //         title: Text('Grades Saved'),
                      //         content: Text(
                      //             'Total Graded Marks: gradedTotalMarks'), //change
                      //         actions: [
                      //           TextButton(
                      //             onPressed: () => Navigator.pop(context),
                      //             child: Text('OK'),
                      //           ),
                      //         ],
                      //       ),
                      //     );
                      //     setState(() {});
                      //   },
                      //   child: Icon(Icons.save),
                      // ),
                      FloatingActionButton(
                        onPressed: () async {
                          setState(() {});
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('The Feedback'),
                              content: TextField(
                                controller: feedController,
                              ), //change
                              actions: [
                                TextButton(
                                  onPressed: () async {
                                    feedback = feedController.text;
                                    await sendFeedback(
                                        widget.attemptId, feedback);
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: Text('sendFeedback'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    feedController.clear();
                                    Navigator.pop(context);
                                  },
                                  child: Text('cancel'),
                                )
                              ],
                            ),
                          );
                        },
                        child: Icon(Icons.edit),
                      ),
                    ],
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// floatingActionButtonLocation: FloatingActionButtonLocation.miniCenterDocked,
// floatingActionButton: Stack(
//   children: [
//     Positioned(
//       left: 16,  // Adjust the position to the left
//       bottom: 16, // Adjust the bottom distance from the screen
//       child: FloatingActionButton(
//         onPressed: () async {
//           if (!formKey.currentState!.validate()) {
//             return;
//           }
//           // Save grades and update the total
//           await updateGrades(
//               widget.attemptId, newGrade, questionIndex, globalTotalMark);
//           // Show the updated total in a dialog
//           showDialog(
//             context: context,
//             builder: (context) => AlertDialog(
//               title: Text('Grades Saved'),
//               content: Text('Total Graded Marks: gradedTotalMarks'), //change
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: Text('OK'),
//                 ),
//               ],
//             ),
//           );
//           setState(() {});
//         },
//         child: Icon(Icons.save),
//       ),
//     ),
//     Positioned(
//       left: 16,  // Position it further from the left
//       bottom: 80, // Adjust the distance from the bottom
//       child: FloatingActionButton(
//         onPressed: () {

//         },
//         child: Icon(Icons.edit),
//       ),
//     ),
//   ],
// ),
