import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'modes/custom_mode.dart';
import 'modes/ai_mode.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // 2 tabs → Custom + AI
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A1A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF121212),
          title: const Text("Home", style: TextStyle(color: Colors.white)),
          leading: Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          bottom: TabBar(
            indicatorColor: const Color.fromARGB(255, 255, 255, 255),
            indicatorWeight: 3,
            labelColor: const Color.fromARGB(
              255,
              250,
              250,
              250,
            ), // active tab text
            unselectedLabelColor: Colors.white70, // inactive tab text
            labelStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 16),
            tabs: const [
              Tab(text: "Custom"),
              Tab(text: "Ask AI"),
            ],
          ),
        ),
        drawer: const CustomDrawer(),

        // 🔽 Load our two new mode files here
        body: const TabBarView(children: [CustomMode(), AiMode()]),
      ),
    );
  }
}
