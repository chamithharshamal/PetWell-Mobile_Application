import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:petwell/features/pet_profile/logic/pet_controller.dart';
import 'package:petwell/features/pet_profile/presentation/pets_list_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => PetController(),
      child: MaterialApp(
        title: 'PetWell App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFE74D3D),
            primary: const Color(0xFFE74D3D),
          ),
        ),
        home: const PetsListScreen(),
      ),
    );
  }
}