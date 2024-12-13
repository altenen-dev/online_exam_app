import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:Online_Exam_App/models/exam_attempt.dart';
import 'package:Online_Exam_App/models/user.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:provider/provider.dart';

class UserProvider with ChangeNotifier {
  AppUser? _currentUser;
  String _role = 'student'; // Default role
  String _id = ''; // User ID or Admin ID
  String get role => _role;
  String get id => _id;

  UserProvider() {
    _initializeUser();
  }

  void _initializeUser() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        // Fetch user role from Firestore
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          _role = data['role'] ?? 'student';
          _id = user.uid;
        } else {
          _role = 'student';
          _id = user.uid;
        }
      } else {
        _role = 'student';
        _id = '';
      }
      notifyListeners();
    });
  }

  AppUser? get currentUser => _currentUser;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  void setCurrentUser(AppUser? user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> registerForExam(String examId) async {
    if (_currentUser != null) {
      if (!_currentUser!.registeredExams.contains(examId)) {
        _currentUser!.registeredExams.add(examId);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUser!.uid)
            .update({'registeredExams': _currentUser!.registeredExams});
        notifyListeners();
      }
    }
  }

  Future<void> unregisterFromExam(String examId) async {
    if (_currentUser != null) {
      _currentUser!.registeredExams.remove(examId);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'registeredExams': _currentUser!.registeredExams});
      notifyListeners();
    }
  }

  void saveExamProgress(String examId, Map<String, dynamic> progress) {
    if (_currentUser != null) {
      _currentUser!.examProgress[examId] = progress;
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'examProgress': _currentUser!.examProgress});
      notifyListeners();
    }
  }

  void updateCurrentUser(String email, String name, String avatarUrl) {
    _currentUser?.updateInfo(email, name, avatarUrl);
    _currentUser?.name = name;
    _currentUser?.email = email;
    _currentUser?.avatarUrl = avatarUrl;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  Map<String, dynamic>? getSavedExamProgress(String examId) {
    return _currentUser?.examProgress[examId];
  }

  bool isRegisteredForExam(String examId) {
    return _currentUser?.registeredExams.contains(examId) ?? false;
  }

// function to return exam title from the exam id
  Future<String> getExamTitle(String examId) async {
    if (_currentUser != null) {
      DocumentSnapshot examDoc =
          await _firestore.collection('exams').doc(examId).get();
      return examDoc['title'] ?? '';
    }
    return '';
  }

  Future<void> addExamResult(String examId, Map<String, dynamic> result) async {
    if (_currentUser != null) {
      result['examId'] = examId;
      _currentUser!.examHistory.add(result);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'examHistory': _currentUser!.examHistory});
      notifyListeners();
    }
  }

  Future<void> markExamAsCompleted(String examId) async {
    if (_currentUser != null) {
      _currentUser!.registeredExams.remove(examId);
      _currentUser!.examProgress.remove(examId);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({
        'registeredExams': _currentUser!.registeredExams,
        'examProgress': _currentUser!.examProgress,
      });
      notifyListeners();
    }
  }

  Future<void> addExamAttempt(ExamAttempt attempt) async {
    if (_currentUser != null) {
      await _firestore.collection('examAttempts').add(attempt.toFirestore());
      // _currentUser!.registeredExams.remove(attempt.examId);
      _currentUser!.examProgress.remove(attempt.examId);
      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'registeredExams': _currentUser!.registeredExams,
        'examProgress': _currentUser!.examProgress,
      });
      notifyListeners();
    }
  }

  Future<List<ExamAttempt>> getUserExamAttempts() async {
    if (_currentUser != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('examAttempts')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();

      return querySnapshot.docs
          .map((doc) => ExamAttempt.fromFirestore(doc))
          .toList();
    }
    return [];
  }

  Future<ExamAttempt?> getLastSubmmitedExamAttempt(String examId) async {
    // should get last attempt ***
    if (_currentUser != null) {
      try {
        print(
            'Fetching exam attempt for user: ${_currentUser!.uid}, exam: $examId');
        QuerySnapshot querySnapshot = await _firestore
            .collection('examAttempts')
            .where('userId', isEqualTo: _currentUser!.uid)
            .where('examId', isEqualTo: examId)
            .orderBy('completedAt', descending: true)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return ExamAttempt.fromFirestore(querySnapshot.docs.first);
        } else {
          return null;
        }
      } catch (e) {}
    } else {}
    return null;
  }

  Future<List<ExamAttempt>> getUserLatestExamAttempts() async {
    try {
      if (_currentUser != null) {
        QuerySnapshot querySnapshot = await _firestore
            .collection('examAttempts')
            .where('userId', isEqualTo: _currentUser!.uid)
            .orderBy('completedAt', descending: true)
            .get();

        final Map<String, ExamAttempt> latestAttempts = {};
        for (var doc in querySnapshot.docs) {
          final attempt = ExamAttempt.fromFirestore(doc);
          if (!latestAttempts.containsKey(attempt.examId)) {
            latestAttempts[attempt.examId] = attempt;
          }
        }
        return latestAttempts.values.toList();
      }
      return [];
    } catch (e) {
      print(e.toString());
      return [];
    }
  }

  Future<ExamAttempt?> getLastUnSubmmitedExamAttempt(String examId) async {
    // should get last attempt ***
    if (_currentUser != null) {
      try {
        print(
            'Fetching exam attempt for user: ${_currentUser!.uid}, exam: $examId');
        QuerySnapshot querySnapshot = await _firestore
            .collection('examAttempts')
            .where('userId', isEqualTo: _currentUser!.uid)
            .where('examId', isEqualTo: examId)
            .where('completedAt', isNull: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return ExamAttempt.fromFirestore(querySnapshot.docs.last);
        } else {
          return null;
        }
      } catch (e) {}
    } else {}
    return null;
  }

  Future<void> updateExamAttempt(ExamAttempt attempt) async {
    try {
      if (attempt.id.isEmpty) {
        // Query the database to get the last inserted attempt
        final querySnapshot = await _firestore
            .collection('examAttempts')
            .orderBy('startTime', descending: true)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          attempt.id = querySnapshot.docs.first.id;
        } else {
          throw ArgumentError('No existing exam attempts found');
        }
      }

      final examAttemptRef =
          _firestore.collection('examAttempts').doc(attempt.id);

      final docSnapshot = await examAttemptRef.get();
      if (docSnapshot.exists) {
        await examAttemptRef.update(attempt.toFirestore());
      } else {
        await examAttemptRef.set(attempt.toFirestore());
      }

      notifyListeners();
    } catch (e) {
      // Handle the error appropriately
      print(
          'Error updating exam attempt IS HEREEEEEEEEEEEEEEEEEEEEEEEEEEEE: $e');
    }
  }
}
