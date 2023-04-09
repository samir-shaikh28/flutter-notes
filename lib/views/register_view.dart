import 'package:flutter/material.dart';
import 'package:notes/constants/routes.dart';
import 'package:notes/services/auth/auth_exception.dart';
import 'package:notes/services/auth/auth_service.dart';
import 'package:notes/utils/dialogs/error_dialogs.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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
        title: const Text("Register"),
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
                    .createUser(email: _email.text, password: _password.text);
                AuthService.firebase().sendEmailVerification();
                Navigator.of(context).pushNamed(verifyEmailRoute);
              } on WeakPasswordException {
                await showErrorDialog(
                    context, "Weak Password. Use a strong one");
              } on EmailAlreadyInUseAuthException {
                showErrorDialog(context, "Already Registered. Try Loging In.");
              } on InvalidEmailAuthException {
                showErrorDialog(context, "Please check your email.");
              } on GenericAuthException {
                showErrorDialog(context, "Something Went Wrong!!");
              }
            },
            child: const Text("Register"),
          ),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text("Already Register? Login Here."))
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
