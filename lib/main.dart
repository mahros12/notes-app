import 'package:flutter/material.dart';

import 'database/app_database.dart';
import 'screens/notes_screen.dart';
import 'services/location_service.dart';
import 'services/note_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = await $FloorAppDatabase
      .databaseBuilder('notes_app.db')
      .addMigrations([migration1to2, migration2to3])
      .build();

  final service = NoteService(database.noteDao, LocationService());

  runApp(NotesApp(service: service));
}

class NotesApp extends StatelessWidget {
  final NoteService service;

  const NotesApp({super.key, required this.service});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF5B5FEF);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Notes',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
        scaffoldBackgroundColor: const Color(0xFFF7F7FB),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7FB),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: Color(0xFFE4E4EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: seed, width: 1.5),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Colors.white,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            side: BorderSide(color: Color(0xFFE9E9F0)),
          ),
        ),
      ),
      home: NotesScreen(service: service),
    );
  }
}
