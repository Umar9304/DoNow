import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'modes/ai_task.dart';
import 'package:intl/intl.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService._internal(this._model);

  factory GeminiService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception("⚠️ Gemini API key not found in .env");
    }

    return GeminiService._internal(
      GenerativeModel(model: "gemini-1.5-flash", apiKey: apiKey),
    );
  }

  /// Generates a study plan from Gemini
  Future<List<AiTask>> generatePlan(
    List<String> tasks, {
    String? hoursPerDay,
    String? deadlineDMY, // deadline passed from UI
  }) async {
    final today = DateTime.now();
    final todayDMY = DateFormat("dd-MM-yyyy").format(today);

    final taskList = tasks.join(", ");

    // ✅ Pre-check deadline feasibility
    if (deadlineDMY != null && deadlineDMY.isNotEmpty) {
      final deadline = DateFormat(
        "dd-MM-yyyy",
      ).parse(deadlineDMY.trim(), true).toLocal();

      if (deadline.isBefore(today)) {
        throw Exception("⚠️ Deadline cannot be in the past.");
      }

      if (deadline.difference(today).inDays < 1) {
        return []; // too short → cannot be completed
      }
    }

    // Build strict prompt
    String prompt =
        """
You are an AI scheduler.

Tasks:
$taskList

Today's date (DMY): $todayDMY
Deadline (DMY): $deadlineDMY

Rules:
- Build a day-wise timetable starting from $todayDMY and ending strictly on or before $deadlineDMY.
- If the work cannot be completed within the deadline, return exactly: Task cannot be completed in the given deadline
- Divide tasks into study sessions with realistic "startTime" and "endTime".
- Each activity MUST clearly describe what to do (e.g., "Learn Python: Loops" or "Revise Chapter 3").
- "id" must always be a string: "task-1", "subtask-1", "subtask-2", etc. (never null, never unquoted).
- All string values MUST use double quotes.
- Times must be in 24-hour format "HH:MM".
- Output STRICTLY a JSON object like this:

{
  "id": "task-1",
  "title": "Main Task Name",
  "deadline": "$deadlineDMY 23:59",
  "aiSuggested": true,
  "subTasks": [
    {
      "id": "subtask-1",
      "title": "Subtask Title",
      "date": "DD-MM-YYYY",
      "startTime": "HH:MM",
      "endTime": "HH:MM"
    }
  ]
}

Do NOT include anything outside JSON.

""";

    if (hoursPerDay != null && hoursPerDay.isNotEmpty) {
      prompt += "- The user can only dedicate $hoursPerDay hours per day.\n";
    }

    // Retry wrapper for overload errors
    Future<String> _callGeminiWithRetry(String prompt) async {
      const retries = 3;
      for (int i = 0; i < retries; i++) {
        try {
          final response = await _model.generateContent([Content.text(prompt)]);
          return response.candidates.first.content.parts
              .whereType<TextPart>()
              .map((p) => p.text)
              .join()
              .trim();
        } catch (e) {
          if (e.toString().contains("503")) {
            if (i == retries - 1) {
              return "Task cannot be completed in the given deadline";
            }
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          rethrow;
        }
      }
      return "Task cannot be completed in the given deadline";
    }

    try {
      final raw = await _callGeminiWithRetry(prompt);

      if (raw.isEmpty || raw.contains("Task cannot be completed")) {
        return [];
      }

      // ✅ Extract JSON safely (now we expect { ... } not [ ... ])
      final start = raw.indexOf("{");
      final end = raw.lastIndexOf("}") + 1;
      if (start == -1 || end == -1) {
        return [];
      }

      final jsonStr = raw.substring(start, end);
      final Map<String, dynamic> parsed = jsonDecode(jsonStr);

      // ✅ Subtasks live inside parsed["subTasks"]
      final subTasks = (parsed["subTasks"] as List<dynamic>? ?? [])
          .map((e) => AiTask.fromJson(e as Map<String, dynamic>))
          .toList();

      return subTasks;
    } catch (e) {
      throw Exception("❌ Error generating plan: ${e.toString()}");
    }
  }
}
