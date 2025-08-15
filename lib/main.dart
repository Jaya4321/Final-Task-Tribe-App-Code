import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'controller/providers/authentication_providers/auth_provider.dart';
import 'controller/providers/authentication_providers/profile_provider.dart';
import 'controller/providers/authentication_providers/password_provider.dart';
import 'controller/providers/chat_providers/chat_provider.dart';
import 'controller/providers/task_providers/task_provider.dart';
import 'controller/providers/task_providers/task_form_provider.dart';
import 'view/screens/authentication_screens/login_screen.dart';
import 'view/screens/main_screens/main_navigation_screen.dart';
import 'services/notification_service.dart';
import 'constants/myColors.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request permissions for gallery and camera
  await _requestPermissions();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize notification service
  await NotificationServices.instance.initialize(
    onMessageReceived: (message) {
    },
    onMessageOpenedApp: (message) {
    },
    onNotificationTapped: (response) {
    },
    onOpenedApp: () {
    },
  );
  
  runApp(const MyApp());
}

// hello 

Future<void> _requestPermissions() async {
  // Camera permission
  final cameraStatus = await Permission.camera.request();
  // Gallery/Photos permission (Android: storage/photos, iOS: photos)
  PermissionStatus galleryStatus;
  if (Platform.isAndroid) {
    // Android 13+ uses photos, below uses storage
    if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
      galleryStatus = PermissionStatus.granted;
    } else if (await Permission.photos.request().isGranted) {
      galleryStatus = PermissionStatus.granted;
    } else {
      galleryStatus = await Permission.storage.request();
    }
  } else if (Platform.isIOS) {
    // iOS
    galleryStatus = await Permission.photos.request();
  } else {
    galleryStatus = PermissionStatus.granted;
  }

  // If any permission is denied, show a dialog
  if (!cameraStatus.isGranted || !galleryStatus.isGranted) {
    // You can show a dialog or a snackbar here
    // For now, just print a warning
    debugPrint('Camera or gallery permission not granted. Some features may not work.');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => PasswordProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => TaskFormProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'TaskTribe',
        theme: ThemeData(
          primaryColor: primaryColor,
          scaffoldBackgroundColor: scaffoldBackgroundColor,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: textPrimaryColor,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonPrimaryColor,
              foregroundColor: buttonTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: inputFocusedBorderColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(color: inputErrorBorderColor),
            ),
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize authentication
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.initialize();
      
      // Listen to authentication state changes
      authProvider.addListener(() {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        
        print('DEBUG: Auth state changed - isAuthenticated: ${authProvider.isAuthenticated}');
        
        if (!authProvider.isAuthenticated) {
          // Clear chat provider data when user signs out
          print('DEBUG: User signed out, clearing chat data');
          chatProvider.clearAllData();
        } else if (authProvider.currentUser != null) {
          // Initialize chat provider when user logs in
          print('DEBUG: User signed in, initializing chat for user: ${authProvider.currentUser!.uid}');
          // Use a small delay to ensure the auth state is fully updated
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && authProvider.isAuthenticated && authProvider.currentUser != null) {
              chatProvider.handleUserLogin(authProvider.currentUser!.uid);
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Show loading screen while checking authentication state
        if (authProvider.isLoading) {
          return const Scaffold(
            backgroundColor: scaffoldBackgroundColor,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 16,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Show login screen if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginScreen();
        }

        // Show main navigation if authenticated
        return const MainNavigationScreen();
      },
    );
  }
}

