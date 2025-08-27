import 'package:intl/intl.dart';

class AiTask {
  final DateTime date;
  final String startTime;
  final String endTime;
  final String activity;
  final String totalDuration;

  AiTask({
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.activity,
    required this.totalDuration,
  });

  factory AiTask.fromJson(Map<String, dynamic> json) {
    try {
      // Parse date (strict dd-MM-yyyy)
      final date = DateFormat("dd-MM-yyyy").parseStrict(json["date"]);

      // Support both snake_case and camelCase for safety
      final startRaw = json["start_time"] ?? json["startTime"];
      final endRaw = json["end_time"] ?? json["endTime"];

      final start24 = DateFormat("HH:mm").parseStrict(startRaw);
      final end24 = DateFormat("HH:mm").parseStrict(endRaw);

      // Convert to 12h with AM/PM
      final start12 = DateFormat("h:mm a").format(start24);
      final end12 = DateFormat("h:mm a").format(end24);

      return AiTask(
        date: date,
        startTime: start12,
        endTime: end12,
        activity: json["activity"] ?? json["title"] ?? "Unknown Task",
        totalDuration:
            json["total_duration"] ??
            json["totalDuration"] ??
            "N/A", // handle both formats
      );
    } catch (e) {
      throw FormatException("Invalid AiTask JSON: $json | Error: $e");
    }
  }

  /// Convert back to JSON if needed (useful for saving to Firestore later)
  Map<String, dynamic> toJson() {
    return {
      "date": DateFormat("dd-MM-yyyy").format(date),
      "start_time": startTime,
      "end_time": endTime,
      "activity": activity,
      "total_duration": totalDuration,
    };
  }
}
