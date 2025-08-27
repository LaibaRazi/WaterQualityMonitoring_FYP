// Importing Flutter's Material Design library
// This gives us access to ready-made widgets like AppBar, TextField, Buttons, etc.
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth.dart';
class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? errorMessage = '';
  bool isLogin = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try {
      await Auth().signInwithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }


  Future<void> createUserWithEmailAndPassword() async {
    try {
      await Auth().createUserwithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message;
      });
    }
  }

  Widget _title(){
    return const Text('Firebase Auth');
  }

  Widget _entryField(
      String title,
      TextEditingController controller,
      )
  {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: title
      ),
    );
  }

  Widget _errorMessage(){
    return Text(errorMessage == '' ? '' : 'Hum ? $errorMessage');
  }

  Widget _submitButton(){
    return ElevatedButton(
        onPressed:
        isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
        child: Text(isLogin ? 'Login' : 'Register'),
    );
  }

  Widget _loginOrRegisterButton(){
    return TextButton(
        onPressed: (){
          setState(() {
            isLogin = !isLogin;
          });
        }, child: Text(isLogin ? 'Register Insted' : 'Login Insted'),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: signInWithEmailAndPassword, // Call login
              child: Text("Login"),
            ),
            if (errorMessage?.isNotEmpty ?? false)
              Text(errorMessage!, style: TextStyle(color: Colors.red)),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/signup');
              },
              child: Text("Don’t have an account? Sign up"),
            ),
          ],
        ),
      ),
    );
  }
}
