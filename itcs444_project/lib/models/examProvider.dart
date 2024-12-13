import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Exam {
  String id;
  String creatorId;
  String title;
  int duration;
  int maxAttempts;
  DateTime start;
  DateTime end;
  List<Map<String, dynamic>> questions;
  bool isSolved;
  String displayStyle; // New field for question display style
  bool questionShuffle;
  bool isHidden; // New field to indicate if the exam is hidden

  Exam({
    this.id = '',
    required this.title,
    required this.duration,
    required this.maxAttempts,
    required this.start,
    required this.end,
    required this.questions,
    required this.creatorId,
    this.isSolved = false,
    this.displayStyle = 'all', // Default to showing all questions
    this.questionShuffle = false, // Default to no shuffling
    this.isHidden = false, // Default to not hidden
  });

  static Future<void> addExamToFirestore(Exam exam, String customExamId) async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Use doc() with a custom ID instead of add()
      DocumentReference examRef =
          firestore.collection('exams').doc(customExamId);

      await examRef.set({
        'creatorId': exam.creatorId,
        'title': exam.title,
        'duration': exam.duration,
        'maxAttempts': exam.maxAttempts,
        'start': Timestamp.fromDate(exam.start),
        'end': Timestamp.fromDate(exam.end),
        'dateCreated': FieldValue.serverTimestamp(),
        'displayStyle': exam.displayStyle,
        'questionShuffle': exam.questionShuffle,
        'isHidden': exam.isHidden, // Save the isHidden field
      });

      // Add each question to the questions subcollection
      for (var question in exam.questions) {
        await examRef.collection('questions').add(question);
      }
    } catch (e) {}
  }

  static Future<Exam> fromFirestore(DocumentSnapshot doc) async {
    final firestore = FirebaseFirestore.instance;
    final data = doc.data() as Map<String, dynamic>;

    // Fetch questions subcollection
    List<Map<String, dynamic>> questions = [];
    try {
      QuerySnapshot questionSnapshot = await firestore
          .collection('exams')
          .doc(doc.id)
          .collection('questions')
          .get();
      questions = questionSnapshot.docs.map((qDoc) {
        final questionData = qDoc.data() as Map<String, dynamic>;
        questionData['id'] = qDoc.id; // Add question id to the map
        return questionData;
      }).toList();
    } catch (e) {}

    return Exam(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      title: data['title'] ?? '',
      duration: data['duration'] ?? 0,
      maxAttempts: data['maxAttempts'] ?? 0,
      start: (data['start'] as Timestamp?)?.toDate() ?? DateTime.now(),
      end: (data['end'] as Timestamp?)?.toDate() ?? DateTime.now(),
      questions: questions,
      isSolved: data['isSolved'] ?? false,
      displayStyle: data['displayStyle'] ?? 'all',
      questionShuffle: data['questionShuffle'] ?? false,
      isHidden: data['isHidden'] ?? false, // Load the isHidden field
    );
  }

  static Future<List<Exam>> fetchAllExams() async {
    final firestore = FirebaseFirestore.instance;
    List<Exam> exams = [];
    try {
      //Here we are fetching all exams from the firestore
      QuerySnapshot snapshot = await firestore.collection('exams').get();
      for (var exam in snapshot.docs) {
        exams.add(await fromFirestore(exam));
      }
    } catch (e) {}
    return exams;
  }
}

class ExamProvider extends ChangeNotifier {
  List<Exam> _exams = [];

  List<Exam> get exams => _exams;

  Future<void> addExam(Exam exam, String id) async {
    await Exam.addExamToFirestore(exam, id);
    _exams.add(exam);
    notifyListeners();
  }

  void removeExam(Exam exam) {
    _exams.remove(exam);
    notifyListeners();
  }

  void updateExam(int index, Exam updatedExam) {
    if (index >= 0 && index < _exams.length) {
      _exams[index] = updatedExam;
      notifyListeners();
    }
  }

  Exam? getExamByTitle(String title) {
    try {
      return _exams.firstWhere((exam) => exam.title == title);
    } catch (e) {
      return null;
    }
  }

  Future<Exam?> getExamById(String examId) async {
    try {
      await fetchExams();
      return _exams.firstWhere((exam) => exam.id == examId);
    } catch (e) {
      return null; // Return null if no exam with matching examId is found
    }
  }

  Future<void> fetchExams() async {
    _exams = await Exam.fetchAllExams();
    notifyListeners();
  }

  Future<void> markExamAsSolved(String examId) async {
    final index = _exams.indexWhere((exam) => exam.id == examId);
    if (index != -1) {
      _exams[index].isSolved = true;
      await FirebaseFirestore.instance
          .collection('exams')
          .doc(examId)
          .update({'isSolved': true});
      notifyListeners();
    }
  }

  Future<Exam?> getExamByIdAsync(String id) async {
    // Simulate a delay or fetch from an API
    await Future.delayed(Duration(
        milliseconds:
            500)); // delay should be decreased for faster performance, its simulated not fixed.
    return getExamById(id);
  }

  Future<void> hideExam(String examId) async {
    try {
      final index = _exams.indexWhere((exam) => exam.id == examId);
      if (index != -1) {
        _exams[index].isHidden = true;
        await FirebaseFirestore.instance
            .collection('exams')
            .doc(examId)
            .update({'isHidden': true});
        notifyListeners();
      }
    } catch (e) {}
  }

  // this method fetch exams based on the role and adminId
  Stream<QuerySnapshot> getExamsStream(
      {required String role, String? adminId}) {
    CollectionReference exams = FirebaseFirestore.instance.collection('exams');

    if (role == 'admin' && adminId != null) {
      return exams
          .where('creatorId', isEqualTo: adminId)
          .where('isHidden', isEqualTo: false)
          .snapshots();
    } else {
      return exams.where('isHidden', isEqualTo: false).snapshots();
    }
  }
}

// Example usage:
// ExamProvider examProvider = ExamProvider();
// examProvider.addExam(Exam(title: "Math Exam", creatorId: "admin1", duration: 60, maxAttempts: 3, start: DateTime.now(), end: DateTime.now().add(Duration(hours: 1)), questions: []));
