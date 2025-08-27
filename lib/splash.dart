import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigated = false; // ✅ Prevent multiple navigations

  @override
  void initState() {
    super.initState();

    _controller = VideoPlayerController.asset("assets/intro.mp4")
      ..initialize().then((_) {
        if (mounted) {
          setState(() {}); // refresh UI only if still mounted
        }
        _controller.play();
      });

    // Listen for video completion
    _controller.addListener(() {
      if (mounted &&
          !_isNavigated &&
          _controller.value.isInitialized &&
          _controller.value.position >= _controller.value.duration) {
        _isNavigated = true; // ✅ Ensure it runs only once

        _navigateAfterSplash();
      }
    });
  }

  /// ✅ Decide where to go after splash
  void _navigateAfterSplash() {
    final user = FirebaseAuth.instance.currentUser;

    Widget nextPage;
    if (user != null) {
      // Already logged in → go to Home
      nextPage = HomePage();
    } else {
      // Not logged in → go to Login
      nextPage = LoginPage();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, __) => nextPage,
        transitionsBuilder: (context, animation, __, child) {
          const begin = Offset(0.0, 1.0); // slide up
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose(); // ✅ Proper cleanup
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover, // ✅ makes it full screen
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
