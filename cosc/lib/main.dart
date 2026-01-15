import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/supabase_service.dart';
import 'services/signaling_service.dart';
import 'services/pairing_service.dart';
import 'utils/local_storage_service.dart';
import 'screens/home_screen.dart';
import 'screens/device_setup_screen.dart';
import 'screens/pairing_request_screen.dart';
import 'screens/pairing_confirmation_screen.dart';
import 'screens/device_list_screen.dart';

const String supabaseUrl = 'YOUR_SUPABASE_URL';
const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await LocalStorageService.initialize();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  
  runApp(const CooperatingScreenApp());
}

class CooperatingScreenApp extends StatelessWidget {
  const CooperatingScreenApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SupabaseService>(
          create: (_) => SupabaseService(),
        ),
        Provider<SignalingService>(
          create: (_) => SignalingService(
            serverUrl: 'ws://localhost:3000', // Update with actual server URL
          ),
        ),
        Provider<PairingService>(
          create: (_) => PairingService(),
        ),
      ],
      child: MaterialApp(
        title: 'CooperatingScreen',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/setup': (context) => const DeviceSetupScreen(),
          '/pairing-request': (context) => const PairingRequestScreen(),
          '/pairing-confirm': (context) => const PairingConfirmationScreen(),
          '/devices': (context) => const DeviceListScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final supabaseService = context.read<SupabaseService>();
    
    return FutureBuilder(
      future: supabaseService.isDeviceRegistered(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasData && snapshot.data == true) {
          return const HomeScreen();
        }
        
        return const DeviceSetupScreen();
      },
    );
  }
}
