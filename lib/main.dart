import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/auth_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://pzhpkoiqcutkcaudrazn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InB6aHBrb2lxY3V0a2NhdWRyYXpuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjgxODIxNzgsImV4cCI6MjA4Mzc1ODE3OH0.Dviqpt3U5qav3smWpPdrXL8puOIWP1cGh8oAxytfLQQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reseller Copilot',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final session = Supabase.instance.client.auth.currentSession;
        
        // If user is authenticated, show scanner screen
        if (session != null) {
          return ScannerScreen(
            supabaseService: SupabaseService(Supabase.instance.client),
          );
        }
        
        // Otherwise, show auth screen
        return const AuthScreen();
      },
    );
  }
}
