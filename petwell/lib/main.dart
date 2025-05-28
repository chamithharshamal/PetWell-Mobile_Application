import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:petwell/features/auth/screens/start_page.dart';
import 'package:petwell/features/auth/screens/signin_screen.dart'; // Adjust path
import './features/home/home_screen.dart'; // Adjust path
import './features/admin/screens/admin_dashboard_screen.dart'; // Adjust path
// Adjust path if needed
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
    return MaterialApp(
      title: 'PetWell',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red, // Changed to red to match Color(0xFFe74d3d)
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: const Color(
              0xFFe74d3d,
            ), // Match your primary color
            foregroundColor: Colors.white, // Text/icon color
          ),
        ),
      ),
      initialRoute: '/', // Set initial route to handle authentication
      routes: {
        '/': (context) => const AuthWrapper(), // Authentication wrapper
        '/signin': (context) => const SignInScreen(),
        '/start': (context) => const StartPage(), // Route for StartPage
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminDashboardScreen(),
      },
      onUnknownRoute: (settings) {
        // Fallback for undefined routes
        return MaterialPageRoute(
          builder:
              (context) => Scaffold(
                body: Center(child: Text('Route ${settings.name} not found')),
              ),
        );
      },
    );
  }
}

// Wrapper to handle authentication state and redirect accordingly
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // User is signed in, check if admin
          return FutureBuilder(
            future:
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(snapshot.data!.uid)
                    .get(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final isAdmin =
                  userSnapshot.data?.data() != null
                      ? (userSnapshot.data!.data()
                              as Map<String, dynamic>)['isAdmin'] ??
                          false
                      : false;
              return isAdmin
                  ? const AdminDashboardScreen()
                  : const HomeScreen();
            },
          );
        }
        // User is not signed in, redirect to StartPage or SignInScreen
        return const StartPage(); // StartPage can navigate to SignInScreen
      },
    );
  }
}
