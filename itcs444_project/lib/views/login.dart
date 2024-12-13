import 'package:flutter/material.dart';
import 'package:Online_Exam_App/logic/auth.dart';
import 'package:Online_Exam_App/models/examProvider.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/main.dart';
import 'package:Online_Exam_App/models/user.dart';
import 'package:Online_Exam_App/views/signup.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  bool hidePassword = true;

  bool isLoading = true; // New: To track loading state

  @override
  void initState() {
    super.initState();
    _checkAuthState(); // Check the user's authentication state on initialization
  }

  void _checkAuthState() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final firebaseUser = auth.currentUser;

    if (firebaseUser != null) {
      // User is already logged in, fetch their data
      final appUser = await AppUser.fromFirestore(firebaseUser.uid);
      userProvider.setCurrentUser(appUser!);

      Provider.of<ExamProvider>(context, listen: false).fetchExams();
      print(
          'user logged in and the avatar url is: ${userProvider.currentUser!.avatarUrl}');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else {
      // No user logged in, stop loading
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show login form if not loading
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Welcome to Bahrain Board',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                        hidePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        hidePassword = !hidePassword;
                      });
                    },
                  ),
                ),
                obscureText: hidePassword,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: isLoading
                      ? null // Disable button while logging in
                      : () async {
                          setState(() {
                            isLoading = true; // Show loading spinner
                          });
                          try {
                            var user = await auth.signIn(
                                emailCtrl.text, passCtrl.text);
                            if (user != null) {
                              var appuser =
                                  await AppUser.fromFirestore(user.uid);
                              Provider.of<UserProvider>(context, listen: false)
                                  .setCurrentUser(appuser!);
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => HomePage()),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Login failed. Check credentials.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setState(() {
                              isLoading = false; // Hide loading spinner
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: const Color.fromARGB(
                                255, 255, 0, 0), // Spinner color
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Log In',
                          style: TextStyle(fontSize: 18),
                        )),
              SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (builder) => SignUpPage()),
                ),
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
