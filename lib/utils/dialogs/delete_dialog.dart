import 'package:flutter/material.dart';
import 'package:notes/utils/dialogs/generic_dialogs.dart';

Future<bool> showDeleteDialog(BuildContext context) {
  return showGenericDialog<bool>(
      context: context,
      title: "Delete",
      content: "Are you sure you want to delete this note?",
      optionsBuilder: () => {
            'Cancel': false,
            'Yes': true,
          }).then((value) => value ?? false);
}
