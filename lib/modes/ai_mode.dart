import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../gemini_service.dart';
import '../modes/ai_task.dart';
import '../modes/task.dart';
import '../services/firestore_service.dart';
import 'package:intl/intl.dart';

class AiMode extends StatefulWidget {
  const AiMode({super.key});

  @override
  State<AiMode> createState() => _AiModeState();
}

class _AiModeState extends State<AiMode> with TickerProviderStateMixin {
  final TextEditingController taskController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();

  List<AiTask> aiTasks = [];
  bool isLoading = false;
  String? errorMessage;

  // ✅ Parse AI-generated time string into DateTime
  DateTime? _parseTime(DateTime baseDate, String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;

    try {
      // Try parsing 12h format like "2:30 PM"
      final parsed = DateFormat("h:mm a").parseStrict(timeStr);
      return DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        parsed.hour,
        parsed.minute,
      );
    } catch (_) {
      try {
        // Try parsing 24h format like "14:30"
        final parsed = DateFormat("HH:mm").parseStrict(timeStr);
        return DateTime(
          baseDate.year,
          baseDate.month,
          baseDate.day,
          parsed.hour,
          parsed.minute,
        );
      } catch (_) {
        debugPrint("⚠️ Could not parse time: $timeStr");
        return null;
      }
    }
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.lightBlueAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        deadlineController.text =
            "${picked.day.toString().padLeft(2, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.year}";
      });
    }
  }

  Future<void> _generatePlan() async {
    FocusScope.of(context).unfocus();

    if (taskController.text.trim().isEmpty ||
        deadlineController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Please enter task and deadline")),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final gemini = GeminiService();
      final generated = await gemini.generatePlan(
        [taskController.text.trim()],
        hoursPerDay: hoursController.text.trim(),
        deadlineDMY: deadlineController.text.trim(),
      );

      setState(() {
        aiTasks = generated;
        if (generated.isEmpty) {
          errorMessage = "⚠️ Task cannot be completed in the given deadline.";
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        aiTasks = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _addToTasks() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirestoreService();

    if (aiTasks.isEmpty) return;

    // ✅ Use the main input as parent
    final parentId = DateTime.now().millisecondsSinceEpoch.toString();

    final parentTask = Task(
      id: parentId,
      title: taskController.text.trim(), // Parent title = user input
      deadline: DateFormat("dd-MM-yyyy").parse(deadlineController.text.trim()),
      aiSuggested: true,
      subTasks: aiTasks.map((aiTask) {
        return Task(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: aiTask.activity,
          deadline: aiTask.date, // each subtask has its own date
          startTime: _parseTime(aiTask.date, aiTask.startTime),
          endTime: _parseTime(aiTask.date, aiTask.endTime),
          aiSuggested: true,
        );
      }).toList(),
    );

    await firestore.addTask(uid, parentTask);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ AI plan added as grouped Task")),
    );

    setState(() {
      aiTasks.clear();
      errorMessage = null;
    });
  }

  void _regenerate() {
    _generatePlan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task Name
            TextField(
              controller: taskController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Task (e.g. Learn Python)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Deadline
            TextField(
              controller: deadlineController,
              readOnly: true,
              onTap: () => _selectDeadline(context),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Select Deadline',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Daily Hours
            TextField(
              controller: hoursController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Daily Hours (optional)',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Generate Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 200, 200, 200),
                  foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _generatePlan();
                },
                child: const Text(
                  'Generate Plan with AI',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Results
            if (isLoading)
              const Center(
                child: CircularProgressIndicator(color: Colors.lightBlueAccent),
              )
            else if (errorMessage != null) ...[
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F1F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 15),
                ),
              ),
            ] else if (aiTasks.isNotEmpty) ...[
              const Divider(color: Colors.white24, thickness: 1),
              const SizedBox(height: 10),
              const Text(
                "AI Suggested Schedule:",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: aiTasks.length,
                itemBuilder: (context, index) {
                  final task = aiTasks[index];
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 400),
                    opacity: 1.0,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1F1F1F),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(2, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.activity,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "📅 ${task.date.day}-${task.date.month}-${task.date.year}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "🕑 ${task.startTime} - ${task.endTime}  (${task.totalDuration})",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.lightBlueAccent,
                        side: const BorderSide(color: Colors.lightBlueAccent),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        _regenerate();
                      },
                      child: const Text("Regenerate"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlueAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        _addToTasks();
                      },
                      child: const Text("Add to Tasks"),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
