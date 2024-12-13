import 'package:Online_Exam_App/logic/auth.dart';
import 'package:Online_Exam_App/views/exam_history_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:Online_Exam_App/logic/auth.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/views/exam_history_page.dart';
import 'package:Online_Exam_App/views/grading_page.dart';
import 'package:provider/provider.dart';
import 'views/profile_page.dart';
import 'views/exam_creation_page.dart';
import 'views/exam_participation_page.dart';
import 'views/login.dart';
import 'models/user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
//use the following lines to set up Firebase with your own project credentials

  // await Firebase.initializeApp(
  //   options: const FirebaseOptions(
  //       apiKey: "",
  //       authDomain: "",
  //       projectId: "",
  //       storageBucket: "",
  //       messagingSenderId: "",
  //       appId: "",
  //       measurementId: ""),
  // );
  User? firebaseUser = FirebaseAuth.instance.currentUser;
  AppUser? appUser;
  if (firebaseUser != null) {
    // Fetch AppUser details if a user is logged in
    appUser = await AppUser.fromFirestore(firebaseUser.uid);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (context) => UserProvider()..setCurrentUser(appUser)),
        ChangeNotifierProvider(create: (create) => ExamProvider())
      ],
      child: ExamApp(),
    ),
  );
}

class ExamApp extends StatelessWidget {
  const ExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: Locale('en', 'US'),
      debugShowCheckedModeBanner: false,
      title: 'Online Exam App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.lightBlue,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32.0),
            ),
          ),
        ),
      ),
      home: LoginPage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  AuthService auth = AuthService();
  // Main pages accessedy bottom navigation
  final List<Widget> _pages = [
    ExamParticipationPage(),
    ExamHistoryPage(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;

    return Scaffold(
      appBar: AppBar(),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Exams'),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          // BottomNavigationBarItem(icon: Icon(Icons.login_rounded), label: 'login'),
        ],
      ),
      drawer: Drawer(
        width: 200,
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Center(
                child: Text('Menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    )),
              ),
            ),
            if (currentUser != null &&
                currentUser.role.toLowerCase() == 'admin') ...[
              ListTile(
                leading: Icon(
                  Icons.add_circle,
                ),
                title: Text('Create Exam'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExamCreationPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.assessment,
                ),
                title: Text('Assesment'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AssementPage()),
                  );
                },
              ),
            ],
            if (currentUser != null &&
                currentUser.role.toLowerCase() == 'student')
              ListTile(
                leading: Icon(Icons.play_circle_fill),
                title: Text('Participate in Exam'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ExamParticipationPage()),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('View Exams History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExamHistoryPage()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.manage_accounts),
              title: Text('View user profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );
              },
            ),
            Divider(),
            if (currentUser != null)
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Colors.red,
                ),
                title: Text('logout'),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (BuildContext content) {
                        return AlertDialog(
                          title: Text('Logout'),
                          content: Text('Are you sure?'),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('No')),
                            TextButton(
                                onPressed: () {
                                  userProvider.logout();
                                  auth.signOut();
                                  Navigator.pop(context);
                                  Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                          builder: (builder) => LoginPage()));
                                },
                                child: Text('Yes'))
                          ],
                        );
                      });
                },
              )
          ],
        ),
      ),
    );
  }
}
