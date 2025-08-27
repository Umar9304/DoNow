import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firestore_service.dart';
import 'modes/task.dart';
import 'custom_drawer.dart';
import 'package:intl/intl.dart';

class TasksPage extends StatelessWidget {
  final FirestoreService _firestoreService = FirestoreService();

  TasksPage({super.key});

  String _formatDeadline(DateTime deadline) {
    return DateFormat("d MMM, h:mm a").format(deadline);
  }

  String _formatStart(Task task) {
    if (task.startTime != null) {
      return DateFormat("h:mm a").format(task.startTime!);
    } else if (task.aiSuggested) {
      return "AI‑Suggested";
    } else {
      return "Not Set";
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            "⚠️ Please log in to see tasks",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }
    final uid = user.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        title: const Text("My Tasks", style: TextStyle(color: Colors.white)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const CustomDrawer(),

      body: StreamBuilder<List<Task>>(
        stream: _firestoreService.getTasks(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                "❌ Error loading tasks",
                style: const TextStyle(color: Colors.redAccent),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "No tasks yet",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final tasks = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: tasks.map((task) {
              // ✅ Parent task with subtasks
              if (task.subTasks.isNotEmpty) {
                return Card(
                  color: const Color(0xFF2A2A2A),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 16),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          "Deadline: ${_formatDeadline(task.deadline)} • Start: ${_formatStart(task)}",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      color: const Color(0xFF2A2A2A),
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onSelected: (value) async {
                        if (task.id == null) return; // ✅ prevent crash
                        if (value == "delete") {
                          await _firestoreService.deleteTask(uid, task.id!);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("${task.title} deleted")),
                          );
                        } else if (value == "toggle") {
                          final updatedParent = task.copyWith(
                            isCompleted: !task.isCompleted,
                          );
                          await _firestoreService.updateTask(
                            uid,
                            updatedParent,
                          );
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: "delete",
                          child: Text(
                            "Delete Group",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        PopupMenuItem(
                          value: "toggle",
                          child: Text(
                            task.isCompleted
                                ? "Mark Incomplete"
                                : "Mark Complete",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    children: task.subTasks.map((sub) {
                      return ListTile(
                        title: Text(
                          sub.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          "📅 ${_formatDeadline(sub.deadline)} • 🕑 ${_formatStart(sub)}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: PopupMenuButton<String>(
                          color: const Color(0xFF2A2A2A),
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (value) async {
                            if (value == "delete") {
                              final updatedParent = task.copyWith(
                                subTasks: task.subTasks
                                    .where((t) => t.id != sub.id)
                                    .toList(),
                              );
                              await _firestoreService.updateTask(
                                uid,
                                updatedParent,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("${sub.title} deleted")),
                              );
                            } else if (value == "toggle") {
                              final updatedSub = sub.copyWith(
                                isCompleted: !sub.isCompleted,
                              );
                              final updatedParent = task.copyWith(
                                subTasks: task.subTasks
                                    .map((t) => t.id == sub.id ? updatedSub : t)
                                    .toList(),
                              );
                              await _firestoreService.updateTask(
                                uid,
                                updatedParent,
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: "delete",
                              child: Text(
                                "Delete",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            PopupMenuItem(
                              value: "toggle",
                              child: Text(
                                sub.isCompleted
                                    ? "Mark Incomplete"
                                    : "Mark Complete",
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              }

              // ✅ Normal single task
              return Card(
                color: const Color(0xFF2A2A2A),
                margin: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(
                    task.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    "Deadline: ${_formatDeadline(task.deadline)}\nStart: ${_formatStart(task)}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  trailing: PopupMenuButton<String>(
                    color: const Color(0xFF2A2A2A),
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onSelected: (value) async {
                      if (task.id == null) return; // ✅ prevent crash
                      if (value == "delete") {
                        await _firestoreService.deleteTask(uid, task.id!);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("${task.title} deleted")),
                        );
                      } else if (value == "toggle") {
                        final updated = task.copyWith(
                          isCompleted: !task.isCompleted,
                        );
                        await _firestoreService.updateTask(uid, updated);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: "delete",
                        child: Text(
                          "Delete",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      PopupMenuItem(
                        value: "toggle",
                        child: Text(
                          task.isCompleted
                              ? "Mark Incomplete"
                              : "Mark Complete",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
