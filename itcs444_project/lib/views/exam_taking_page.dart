import 'dart:math';

import 'package:flutter/material.dart';
import 'package:Online_Exam_App/views/grading_page.dart';
import 'package:Online_Exam_App/widgets/widgets_question_widget.dart'; // Ensure this file exists or update the path
import 'package:provider/provider.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/models/exam_attempt.dart';
import 'package:Online_Exam_App/widgets/countdown_timer.dart';

class ExamTakingPage extends StatefulWidget {
  final Exam exam;

  const ExamTakingPage({
    super.key,
    required this.exam,
  });

  @override
  _ExamTakingPageState createState() => _ExamTakingPageState();
}

class _ExamTakingPageState extends State<ExamTakingPage> {
  late List<Map<String, dynamic>> _userAnswers = List.generate(
    widget.exam.questions.length,
    (index) => {'questionIndex': index, 'answer': '', 'grade': 0},
  );
  int _currentQuestionIndex = 0;
  late Future<ExamAttempt?> _examAttemptFuture;
  List<Map<String, dynamic>> _displayedQuestions = [];
  late List<int> _questionOrder;

  @override
  void initState() {
    super.initState();

    _prepareQuestions(); // Prepare questions based on shuffle setting
    _examAttemptFuture = _loadExamAttempt();
  }

  void _prepareQuestions() {
    if (widget.exam.questionShuffle) {
      // Check the exam's shuffle setting
      _shuffleQuestions();
    } else {
      _displayedQuestions = widget.exam.questions; // Use original order
    }
  }

  void _shuffleQuestions() {
    final random = Random();
    _questionOrder = List.generate(widget.exam.questions.length, (i) => i);
    _questionOrder.shuffle(random);
    _displayedQuestions =
        _questionOrder.map((index) => widget.exam.questions[index]).toList();
    print(_displayedQuestions);
  }

  Future<void> _saveDuration(ExamAttempt attempt) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.updateExamAttempt(attempt);
  }

  void _loadSavedProgress() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final savedProgress = userProvider.getSavedExamProgress(widget.exam.id);
    if (savedProgress != null) {
      setState(() {
        _userAnswers =
            List<Map<String, dynamic>>.from(savedProgress['answers'] ?? [])
                .map((answer) {
          return {
            'questionIndex': answer['questionIndex'],
            'answer': answer['answer'],
            'grade': answer['grade'] ?? 0,
          };
        }).toList();
        _currentQuestionIndex = savedProgress['currentQuestionIndex'] ?? 0;
      });
    }
  }

  Future<ExamAttempt?> _loadExamAttempt() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      // this will get the last attempt
      var attempt =
          await userProvider.getLastUnSubmmitedExamAttempt(widget.exam.id) ??
              null;
      print(
          'loading attempt id: ${attempt?.id} and the exam title ${attempt?.examTitle}');
      // we must create a new attempt if the previous attempt is completed,
      // otherwise load and continue with the previous one.
      if (attempt == null || attempt.completedAt != null) {
        print('the attempt is submitted');
        ExamAttempt newAttempt = ExamAttempt(
            id: '',
            examId: widget.exam.id,
            userId: userProvider.currentUser!.uid,
            score: 0.0,
            totalQuestions: widget.exam.questions.length,
            percentage: 0.0,
            startTime: DateTime.now(),
            remainingDuration: widget.exam.duration * 60,
            answers: List.generate(
              widget.exam.questions.length,
              (index) => {
                'answer': '',
                'grade': 0,
                'questionIndex': index,
              },
            ),
            currentQuestionIndex: 0,
            examTitle: widget.exam.title,
            examMarks: 0);
        await userProvider.addExamAttempt(newAttempt);
        attempt = newAttempt;
        print('creating new attempt');
      }
      return attempt;
    } catch (e) {
      print('Error loading exam attempt: $e');
      return null;
    }
  }

  Future<void> _saveProgress(ExamAttempt attempt) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final updatedAttempt = attempt.copyWith(answers: _userAnswers);
    await userProvider.updateExamAttempt(updatedAttempt);
  }

  Future<void> _submitExam(ExamAttempt attempt) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      double score = 0;
      double totalMarks = 0;
      for (int i = 0; i < widget.exam.questions.length; i++) {
        final question = widget.exam.questions[i];
        totalMarks += question['marks'];

        if (attempt.answers[i]['answer'] == question['correct answer']) {
          score += question['marks'];
          attempt.answers[i]['grade'] = question['marks']; // Full marks
        } else {
          attempt.answers[i]['grade'] = 0; // Zero marks for incorrect
        }
      }

      double percentage = (score / totalMarks) * 100;

      attempt.score = score;
      attempt.percentage = percentage;
      attempt.completedAt = DateTime.now();
      attempt.remainingDuration = 0;
      attempt.examMarks = totalMarks;

      await userProvider.updateExamAttempt(attempt);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Exam Completed'),
            content: Text(
                'Your score: ${score.toStringAsFixed(2)}/$totalMarks (${percentage.toStringAsFixed(2)}%)'),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop(); // Dismiss dialog
                  Navigator.of(context).pop(); // Return to previous page
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error submitting exam: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Failed to submit exam: ${e.toString()}. Please try again.')),
      );
    }
  }

  Widget _buildQuestionWidget(
      Map<String, dynamic> question, int index, ExamAttempt examAttempt) {
    return QuestionWidget(
      question: question,
      index: index,
      answer: examAttempt.answers[index]['answer'],
      onChanged: (value) {
        setState(() {
          examAttempt.answers[index]['answer'] = value;
        });
        _saveProgress(examAttempt);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exam.title)),
      body: FutureBuilder<ExamAttempt?>(
        future: _examAttemptFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No exam attempt data available.'));
          }

          final examAttempt = snapshot.data!;

          return Column(
            children: [
              CountdownTimer(
                examAttempt: examAttempt,
                onFinished: () => _submitExam(examAttempt),
                onTick: (Duration remaining) {
                  examAttempt.remainingDuration = remaining.inSeconds;
                  _saveDuration(examAttempt);
                },
              ),
              Expanded(
                child: widget.exam.displayStyle == 'all'
                    ? ListView.builder(
                        itemCount: widget.exam.questions.length,
                        itemBuilder: (context, index) {
                          final question = _displayedQuestions[index];
                          final originalIndex = widget.exam.questionShuffle
                              ? widget.exam.questions.indexOf(question)
                              : index;
                          return _buildQuestionWidget(
                              question, originalIndex, examAttempt);
                        },
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: _buildQuestionWidget(
                              _displayedQuestions[_currentQuestionIndex],
                              widget.exam.questionShuffle
                                  ? widget.exam.questions.indexOf(
                                      _displayedQuestions[
                                          _currentQuestionIndex])
                                  : _currentQuestionIndex,
                              examAttempt,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if (_currentQuestionIndex > 0)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentQuestionIndex--;
                                    });
                                  },
                                  child: Text('Previous'),
                                ),
                              if (_currentQuestionIndex <
                                  widget.exam.questions.length - 1)
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentQuestionIndex++;
                                    });
                                  },
                                  child: Text('Next'),
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
              ElevatedButton(
                onPressed: () => _submitExam(examAttempt),
                child: Text('Submit Exam'),
              ),
            ],
          );
        },
      ),
    );
  }
}
