import 'package:flutter/material.dart';
import 'package:notes/constants/routes.dart';
import 'package:notes/services/auth/auth_exception.dart';
import 'package:notes/services/auth/auth_service.dart';
import 'package:notes/utils/dialogs/error_dialogs.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: "Enter Your Email"),
          ),
          TextField(
              controller: _password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration:
                  const InputDecoration(hintText: "Enter Your Password")),
          TextButton(
            onPressed: () async {
              try {
                await AuthService.firebase()
                    .login(email: _email.text, password: _password.text);
                final user = AuthService.firebase().currentUser;
                if (user?.isEmailVerified ?? false) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil(notesRoute, (route) => false);
                } else {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                      verifyEmailRoute, (route) => false);
                }
              } on UserNotFoundException {
                await showErrorDialog(context, "User Not Found");
              } on WrongPasswordAuthException {
                await showErrorDialog(
                    context, "Wrong Password!! Please check your password.");
              } on GenericAuthException {
                showErrorDialog(context, "Authentication Error! ");
              }
            },
            child: const Text("Login"),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(registerRoute, (route) => false);
              },
              child: const Text("Not Registered Yet? Register Here."))
        ],
      ),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }
}
