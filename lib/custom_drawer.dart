import 'package:flutter/material.dart';
import 'home.dart';
import 'dashboard.dart';
import 'completion.dart';
import 'login.dart';
import 'task_page.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6, // ✅ custom width
      child: Drawer(
        backgroundColor: const Color(0xFF2A2A2A),
        child: Column(
          children: [
            // Header
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF121212)),
              child: Center(
                child: Text(
                  'DoNow',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ),

            // Navigation items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildDrawerItem(
                    context,
                    title: 'Home',
                    icon: Icons.home, // 🏠 Home icon
                    page: HomePage(),
                  ),
                  _buildDrawerItem(
                    context,
                    title: 'Tasks',
                    icon: Icons.task, // ✅ Tasks icon
                    page: TasksPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    title: 'Dashboard',
                    icon: Icons.dashboard, // 📊 Dashboard icon
                    page: DashboardPage(),
                  ),
                  _buildDrawerItem(
                    context,
                    title: 'Completion',
                    icon: Icons.task_alt, // ✅ Completion icon
                    page: CompletionPage(),
                  ),
                ],
              ),
            ),

            // Divider + Logout button at bottom
            const Divider(color: Colors.white24, thickness: 1),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.redAccent),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        LoginPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                          const begin = Offset(-1.0, 0.0); // slide from left
                          const end = Offset.zero;
                          const curve = Curves.ease;

                          final tween = Tween(
                            begin: begin,
                            end: end,
                          ).chain(CurveTween(curve: curve));
                          final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

                          return SlideTransition(
                            position: animation.drive(tween),
                            child: FadeTransition(
                              opacity: animation.drive(fadeTween),
                              child: child,
                            ),
                          );
                        },
                  ),
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// ✅ Reusable Drawer Item with custom icon + Slide/Fade transition
  Widget _buildDrawerItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget page,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => page,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0); // slide from right
                  const end = Offset.zero;
                  const curve = Curves.ease;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final fadeTween = Tween<double>(begin: 0.0, end: 1.0);

                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(
                      opacity: animation.drive(fadeTween),
                      child: child,
                    ),
                  );
                },
          ),
        );
      },
    );
  }
}
