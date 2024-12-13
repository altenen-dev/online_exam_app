import 'package:flutter/material.dart';
import 'package:Online_Exam_App/logic/auth.dart';
import 'package:Online_Exam_App/models/userProvider.dart';
import 'package:Online_Exam_App/main.dart';
import 'package:Online_Exam_App/models/user.dart';
import 'package:Online_Exam_App/views/login.dart';
import 'package:provider/provider.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  bool hidePassword = true;
  final AuthService auth = AuthService();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passCtrl = TextEditingController();
  final TextEditingController nameCtrl = TextEditingController();
  bool isLoading = false; // New: To track loading state

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final currentUser = userProvider.currentUser;
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Create an Account',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email)),
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
                            var user = await auth.createUser(
                                emailCtrl.text, passCtrl.text, nameCtrl.text);
                            if (user != null) {
                              userProvider.setCurrentUser(user
                                  as AppUser); // we can use as here because the function create user returns type Object
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(
                                      "Account Created Successfully! Redirecting to Home..."),
                                  backgroundColor: Colors.lightGreen));
                              await Future.delayed(Duration(seconds: 2));
                              Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => HomePage()));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text("Invalid input"),
                                      backgroundColor: Colors.red));
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
                          'Sign Up',
                          style: TextStyle(fontSize: 18),
                        )),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (builder) => LoginPage())),
                  child: const Text('Already have an account? Log In',
                      style: TextStyle(color: Colors.blue))),
            ],
          ),
        ),
      ),
    );
  }
}
