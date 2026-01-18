import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/auth_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (see .env.example)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // On web builds or local dev, the .env file may be missing from assets.
    // Don't crash the app here; surface a helpful log and continue so tests or
    // alternate env injection can work.
    debugPrint('Warning: .env not found or failed to load: $e');
  }

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Missing SUPABASE_URL or SUPABASE_ANON_KEY environment variables. See .env.example');
  }

  // Initialize Supabase using environment variables
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
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
