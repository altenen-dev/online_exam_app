import 'dart:async';

import 'package:flutter/material.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:provider/provider.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/models/exam_attempt.dart';
import 'package:intl/intl.dart';

class ExamHistoryPage extends StatelessWidget {
  const ExamHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Exam History'),
      ),
      body: FutureBuilder<List<ExamAttempt>>(
        future: Provider.of<UserProvider>(context, listen: false)
            .getUserLatestExamAttempts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No exam attempts found.'));
          }

          final attempts = snapshot.data!;

          return ListView.builder(
            itemCount: attempts.length,
            itemBuilder: (context, index) {
              final attempt = attempts[index];
              if (attempt.completedAt != null) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exam Title Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Exam: ${attempt.examTitle}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            Icon(Icons.assignment, color: Colors.blueAccent),
                          ],
                        ),
                        Divider(thickness: 1.2),
                        SizedBox(height: 10),

                        // Score Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              decoration: BoxDecoration(
                                color: _getColor(attempt.percentage),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                '${attempt.score} / ${attempt.examMarks}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),
                        // Percentage Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Percentage:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '${attempt.percentage.toStringAsFixed(2)}%',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87),
                            ),
                          ],
                        ),

                        SizedBox(height: 10),
                        // Started and Completed Section
                        Text(
                          'Started: ${_formatDateTime(attempt.startTime)}',
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        if (attempt.completedAt != null)
                          Text(
                            'Completed: ${_formatDateTime(attempt.completedAt!)}',
                            style:
                                TextStyle(fontSize: 16, color: Colors.black87),
                          )
                        else
                          Text(
                            'Status: In Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orangeAccent,
                            ),
                          ),

                        // Feedback Section (if available)
                        if (attempt.feedback != null)
                          Container(
                            margin: EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.greenAccent.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.feedback, color: Colors.green),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Feedback: ${attempt.feedback}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: 10),

                        // Navigate to ShowAnswer Screen
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ShowAnswer(
                                    examId: attempt.examId,
                                    attempt: attempt,
                                  ),
                                ),
                              );
                            },
                            icon: Icon(Icons.arrow_forward, color: Colors.blue),
                            label: Text(
                              'View Details',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
  }
}

// Color _getColor(double number) {
//   if (number >= 80) {
//     return const Color.fromARGB(255, 71, 182, 77);
//   } else if (number >= 60) {
//     return Colors.yellowAccent;
//   } else if (number >= 40) {
//     return Colors.orange;
//   } else
//     return Colors.red;
// }

class ShowAnswer extends StatelessWidget {
  final String examId;
  final dynamic attempt;

  // Constructor to accept the examId and attempt
  ShowAnswer({required this.examId, required this.attempt});

  // Function to fetch the exam asynchronously
  Future<dynamic> _fetchExam(BuildContext context, String examId) async {
    return await context.read<ExamProvider>().getExamByIdAsync(examId);
  }

// there is 4 secs delay in examProvider.dart line 171
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Show Answer'),
      ),
      body: FutureBuilder(
        future: _fetchExam(context, examId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData) {
            return Center(
              child: Text(
                'check again later after 10 second',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final exam = snapshot.data;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Exam Title Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'Exam Title: ${exam.title}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Expanded space for Questions and answers
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 20),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.yellow[100],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Feedback',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              Divider(thickness: 1.2),
                              SizedBox(height: 10),
                              Text(
                                attempt.feedback ??
                                    'Your instructor has not added feedback',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        // Display each question
                        ...exam.questions.asMap().entries.map((entry) {
                          int index = entry.key + 1;
                          var question = entry.value;
                          var studentAnswer =
                              attempt.answers[index - 1]['answer'];
                          var studentGrade =
                              attempt.answers[index - 1]['grade'];
                          var correctAnswer = question['correct answer'];
                          var questionMarks = question['marks'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 3,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Question Text
                                      Expanded(
                                        child: Text(
                                          'Q$index: ${question['text']}',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      // Grade Text in Circular Container
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8, horizontal: 16),
                                        decoration: BoxDecoration(
                                          color: _getColor(studentGrade /
                                              questionMarks *
                                              100),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          '$studentGrade / $questionMarks',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Divider(thickness: 1.2),
                                SizedBox(height: 10),
                                Text(
                                  'Your Answer: ${studentAnswer ?? 'N/A'}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Correct Answer: ${correctAnswer ?? ''}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.green,
                                  ),
                                ),
                                SizedBox(height: 10),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: BottomAppBar(
        color: _getColor(attempt.percentage),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Final Score:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${attempt.score}/${attempt.examMarks} (${(attempt.percentage).toStringAsFixed(2)}%)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper function to determine color
Color _getColor(double number) {
  if (number >= 80) {
    return const Color.fromARGB(255, 71, 182, 77);
  } else if (number >= 60) {
    return Colors.yellowAccent;
  } else if (number >= 40) {
    return Colors.orange;
  } else
    return Colors.red;
}
