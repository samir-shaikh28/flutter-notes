import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:notes/extension/list/filter.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;
import 'crud_exceptions.dart';

class NotesService {
  Database? _db;

  List<DatabaseNotes> _notes = [];

  DatabaseUser? _user;

  static final NotesService _shared = NotesService._sharedInstance();
  NotesService._sharedInstance() {
    _notesStreamController =
        StreamController<List<DatabaseNotes>>.broadcast(onListen: () {
      _notesStreamController.sink.add(_notes);
    });
  }

  factory NotesService() => _shared;

  late final StreamController<List<DatabaseNotes>> _notesStreamController;

  Stream<List<DatabaseNotes>> get allNotes =>
      _notesStreamController.stream.filter((note) {
        final currentUser = _user;
        if (currentUser == null) throw UserShouldBeSetBeforeReadingAllNote();
        return note.userId == currentUser.id;
      });

  Future<DatabaseUser> getOrCreateUser({
    required String email,
    bool setAsCurrentUser = true,
  }) async {
    await _ensureDbIsOpen();
    try {
      final user = await getUser(email: email);
      if (setAsCurrentUser) _user = user;
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      if (setAsCurrentUser) _user = createdUser;
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNotes> updateNote({
    required DatabaseNotes note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    // Checking if not exists
    await getNote(id: note.id);

    // Update DB
    final updateCount = await db.update(
        tableNote,
        {
          noteColumn: text,
          isSyncedColumn: 0,
        },
        where: '_id=?',
        whereArgs: [note.id]);

    if (updateCount == 0) throw CouldNotUpdateNote();
    final updatedNote = await getNote(id: note.id);

    _notes.removeWhere((note) => note.id == updatedNote.id);
    _notes.add(updatedNote);
    _notesStreamController.add(_notes);
    return updatedNote;
  }

  Future<Iterable<DatabaseNotes>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(tableNote);
    return notes.map((note) => DatabaseNotes.fromRow(note));
  }

  Future<DatabaseNotes> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(
      tableNote,
      limit: 1,
      where: '_id=?',
      whereArgs: [id],
    );
    if (notes.isEmpty) throw CouldNotFindNote();
    final note = DatabaseNotes.fromRow(notes.first);
    _notes.removeWhere((note) => note.id == id);
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  Future<int> deleteAllNote() async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletion = await db.delete(tableNote);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletion;
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      tableNote,
      where: '_id=?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNotes> createNote({required DatabaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) throw CouldNotFindUser();

    const note = '';

    final noteId = await db.insert(tableNote,
        {userIdColumn: owner.id, noteColumn: note, isSyncedColumn: 1});
    final noteObj = DatabaseNotes(
      id: noteId,
      userId: owner.id,
      note: note,
      isSynced: true,
    );
    _notes.add(noteObj);
    _notesStreamController.add(_notes);
    return noteObj;
  }

  Future<DatabaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final result = await db.query(
      tableUser,
      limit: 1,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (result.isEmpty) throw CouldNotFindUser();

    return DatabaseUser.fromRow(result.first);
  }

  Future<DatabaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final result = await db.query(
      tableUser,
      limit: 1,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (result.isNotEmpty) throw UserAlreadyExists();

    final id = await db.insert(tableUser, {emailColumn: email.toLowerCase()});

    return DatabaseUser(id: id, email: email);
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      tableUser,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount == 0) throw CouldNotDeleteUser();
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    try {
      await open();
    } on DatabaseAlreadyOpenException {
      // Empty
    }
  }

  Future<void> open() async {
    if (_db != null) throw DatabaseAlreadyOpenException();

    try {
      final docsPath = await getApplicationSupportDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // Create user table
      await db.execute(createUserTable);
      // Create Note Table
      await db.execute(createNoteTable);
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectory();
    }
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({required this.id, required this.email});

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'id = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNotes {
  final int id;
  final int userId;
  final String note;
  final bool isSynced;

  DatabaseNotes(
      {required this.id,
      required this.userId,
      required this.note,
      required this.isSynced});

  DatabaseNotes.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        note = map[noteColumn] as String,
        isSynced = (map[isSyncedColumn] as int) == 1;

  @override
  String toString() => 'Note id = $id, userId = $userId, note = $note';

  @override
  bool operator ==(covariant DatabaseNotes other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const tableNote = 'notes';
const tableUser = 'users';
const idColumn = "_id";
const emailColumn = "email";
const userIdColumn = "user_id";
const noteColumn = "note";
const isSyncedColumn = "is_synced";

const createUserTable = ''' 
      CREATE TABLE IF NOT EXISTS "users" (
        "_id" INTEGER NOT NULL,
        "email" Text NOT NULL UNIQUE,
        PRIMARY KEY("_id" AUTOINCREMENT)
      );
      ''';

const createNoteTable = ''' 
      CREATE TABLE IF NOT EXISTS "notes" (
        "_id" INTEGER NOT NULL,
        "user_id" INTEGER NOT NULL,
        "note" Text,
        "is_synced" INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "users"("_id"),
        PRIMARY KEY("_id" AUTOINCREMENT)
      );
      ''';
