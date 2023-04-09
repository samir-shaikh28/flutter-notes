import 'package:flutter/material.dart';
import 'package:notes/services/crud/notes_service.dart';
import 'package:notes/utils/dialogs/delete_dialog.dart';

typedef NoteCallback = void Function(DatabaseNotes note);

class NotesListView extends StatelessWidget {
  final List<DatabaseNotes> notes;
  final NoteCallback onDeleteNote;
  final NoteCallback onTap;

  const NotesListView(
      {super.key,
      required this.notes,
      required this.onDeleteNote,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        return ListTile(
          onTap: () => onTap(note),
          title: Text(
            note.note,
            maxLines: 2,
            softWrap: true,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final shouldDelete = await showDeleteDialog(context);
              if (shouldDelete) onDeleteNote(note);
            },
          ),
        );
      },
    );
  }
}
