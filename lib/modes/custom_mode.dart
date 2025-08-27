import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../modes/task.dart';
import '../services/firestore_service.dart';

class CustomMode extends StatefulWidget {
  const CustomMode({super.key});

  @override
  State<CustomMode> createState() => _CustomModeState();
}

class _CustomModeState extends State<CustomMode> {
  final _firestoreService = FirestoreService();

  final TextEditingController taskController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();
  DateTimeRange? selectedRange;
  TimeOfDay? selectedTime;
  bool letAIChoose = false;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(data: ThemeData.dark(), child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        selectedRange = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked;
        letAIChoose = false;
      });
    }
  }

  void _chooseAI() {
    setState(() {
      letAIChoose = true;
      selectedTime = null;
    });
  }

  Future<void> _addTask() async {
    if (taskController.text.trim().isEmpty ||
        hoursController.text.trim().isEmpty ||
        selectedRange == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required fields"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final hours = int.tryParse(hoursController.text.trim()) ?? 1;

    DateTime? startDateTime;
    if (selectedTime != null) {
      final now = DateTime.now();
      startDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );
    }

    final task = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: taskController.text.trim(),
      deadline: selectedRange!.end,
      startTime: startDateTime,
      endTime: startDateTime != null
          ? startDateTime.add(Duration(hours: hours))
          : null,
      aiSuggested: letAIChoose,
      isCompleted: false,
      inProgress: false,
      wastedTime: 0,
    );

    await _firestoreService.addTask(uid, task);

    taskController.clear();
    hoursController.clear();
    setState(() {
      selectedRange = null;
      selectedTime = null;
      letAIChoose = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Task added successfully"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),

        // Task input
        TextField(
          controller: taskController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            hintText: "Task (e.g. DSA)",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Hours input
        TextField(
          controller: hoursController,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            hintText: "Hours per day",
            hintStyle: const TextStyle(color: Colors.white54),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Pick date range
        ElevatedButton(
          onPressed: () {
            FocusScope.of(context).unfocus();
            _pickDateRange();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.grey[800],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: const Size.fromHeight(45),
          ),
          child: const Text(
            "Pick Date Range",
            style: TextStyle(color: Colors.white),
          ),
        ),
        if (selectedRange != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "📅 ${selectedRange!.start.toString().split(' ')[0]} → ${selectedRange!.end.toString().split(' ')[0]}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        const SizedBox(height: 12),

        // Pick start time or AI
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _pickTime();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (!letAIChoose && selectedTime != null)
                      ? Colors.blueAccent
                      : Colors.grey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(45),
                ),
                child: const Text(
                  "Pick Start Time",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  _chooseAI();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: letAIChoose
                      ? Colors.blueAccent
                      : Colors.grey[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size.fromHeight(45),
                ),
                child: const Text(
                  "Let AI Choose",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
        if (selectedTime != null && !letAIChoose)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              "⏰ ${selectedTime!.format(context)}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        const SizedBox(height: 20),

        // Add task button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              FocusScope.of(context).unfocus();
              _addTask();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[600],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "Add Task",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
