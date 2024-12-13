import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String uid;
  String name;
  String email;
  String avatarUrl;
  final String role;
  List<String> registeredExams;
  Map<String, Map<String, dynamic>> examProgress;
  List<Map<String, dynamic>> examHistory;
  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl = '',
    List<String>? registeredExams,
    Map<String, Map<String, dynamic>>? examProgress,
    List<Map<String, dynamic>>? examHistory,
  })  : registeredExams = registeredExams ?? [],
        examProgress = examProgress ?? {},
        examHistory = examHistory ?? [];

  static Future<AppUser?> fromFirestore(String uid) async {
    final firestore = FirebaseFirestore.instance;
    try {
      DocumentSnapshot doc = await firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return AppUser(
          uid: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          role: data['role'] ?? 'student',
          avatarUrl: data['avatarUrl'] ?? 'not found',
          registeredExams: List<String>.from(data['registeredExams'] ?? []),
          examProgress: Map<String, Map<String, dynamic>>.from(
              data['examProgress'] ?? {}),
          examHistory:
              List<Map<String, dynamic>>.from(data['examHistory'] ?? []),
        );
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<void> updateInfo(String email, String name, String url) async {
    final fb = FirebaseFirestore.instance;
    try {
      DocumentReference userRef = fb.collection('users').doc(uid);
      await userRef.update({'email': email, 'name': name, 'avatarUrl': url});
    } catch (e) {}
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'registeredExams': registeredExams,
      'examProgress': examProgress,
      'examHistory': examHistory,
    };
  }
}
