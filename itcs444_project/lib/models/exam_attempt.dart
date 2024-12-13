import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Online_Exam_App/models/examProvider.dart';

class ExamAttempt {
  String id;
  String examId;
  String userId;
  double score;
  int totalQuestions;
  double percentage;
  DateTime? completedAt;
  String? feedback;
  DateTime startTime;
  int remainingDuration;
  List<Map<String, dynamic>> answers;
  int currentQuestionIndex;
  String examTitle;
  double examMarks;

  ExamAttempt({
    required this.id,
    required this.examId,
    required this.userId,
    required this.score,
    required this.totalQuestions,
    required this.percentage,
    this.completedAt,
    this.feedback,
    required this.startTime,
    required this.remainingDuration,
    required this.answers,
    required this.currentQuestionIndex,
    required this.examTitle,
    required this.examMarks,
  });

  factory ExamAttempt.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ExamAttempt(
      id: doc.id,
      examId: data['examId'] ?? '',
      userId: data['userId'] ?? '',
      score: data['score'] ?? 0,
      totalQuestions: data['totalQuestions'] ?? 0,
      percentage: (data['percentage'] ?? 0).toDouble(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      feedback: data['feedback'],
      startTime: data['startTime'] != null
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      remainingDuration: data['remainingDuration'] ?? 0,
      answers: List<Map<String, dynamic>>.from(data['answers'] ?? []),
      currentQuestionIndex: data['currentQuestionIndex'] ?? 0,
      examTitle: data['examTitle'] ?? '',
      examMarks: data['examMarks'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'examId': examId,
      'userId': userId,
      'score': score,
      'totalQuestions': totalQuestions,
      'percentage': percentage,
      'completedAt':
          completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'feedback': feedback,
      'startTime': Timestamp.fromDate(startTime),
      'remainingDuration': remainingDuration,
      'answers': answers,
      'currentQuestionIndex': currentQuestionIndex,
      'examTitle': examTitle,
      'examMarks': examMarks,
    };
  }

  ExamAttempt copyWith({
    String? id,
    String? examId,
    String? userId,
    double? score,
    int? totalQuestions,
    double? percentage,
    DateTime? completedAt,
    String? feedback,
    DateTime? startTime,
    int? remainingDuration,
    List<Map<String, dynamic>>? answers,
    int? currentQuestionIndex,
    String? examTitle,
    double? examMarks,
  }) {
    return ExamAttempt(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      userId: userId ?? this.userId,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      percentage: percentage ?? this.percentage,
      completedAt: completedAt ?? this.completedAt,
      feedback: feedback ?? this.feedback,
      startTime: startTime ?? this.startTime,
      remainingDuration: remainingDuration ?? this.remainingDuration,
      answers: answers ?? this.answers,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      examTitle: examTitle ?? this.examTitle,
      examMarks: examMarks ?? this.examMarks,
    );
  }

  bool isValid() {
    return id.isNotEmpty &&
        examId.isNotEmpty &&
        userId.isNotEmpty &&
        totalQuestions > 0 &&
        answers.length == totalQuestions;
  }

  static ExamAttempt createNewAttempt(Exam exam, String uid) {
    return ExamAttempt(
      id: '',
      examId: exam.id,
      examTitle: exam.title,
      userId: uid,
      score: 0,
      totalQuestions: exam.questions.length,
      percentage: 0,
      completedAt: null,
      startTime: DateTime.now(),
      remainingDuration: exam.duration * 60,
      answers: List.generate(
        exam.questions.length,
        (index) => {
          'questionIndex': index,
          'answer': '',
          'grade': 0,
        },
      ),
      currentQuestionIndex: 0,
      examMarks: 0,
    );
  }
}
