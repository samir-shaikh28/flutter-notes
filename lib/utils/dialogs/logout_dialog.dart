import 'package:flutter/material.dart';
import 'package:notes/utils/dialogs/generic_dialogs.dart';

Future<bool> showLogOutDialog(BuildContext context) {
  return showGenericDialog<bool>(
      context: context,
      title: "Log out",
      content: "Are you sure you want to log out?",
      optionsBuilder: () => {
            'Cancel': false,
            'Log Out': true,
          }).then((value) => value ?? false);
}
