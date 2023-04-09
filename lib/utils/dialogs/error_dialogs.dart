import 'package:flutter/material.dart';
import 'package:notes/utils/dialogs/generic_dialogs.dart';

Future<void> showErrorDialog(BuildContext context, String text) {
  return showGenericDialog(
    context: context,
    title: "An Error Occurred",
    content: text,
    optionsBuilder: () => {'Ok': null},
  );
}
