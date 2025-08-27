class Task {
  final String? id; // parent docId or local UUID for subtasks
  final String title;
  final DateTime deadline;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isCompleted;
  final bool inProgress;
  final int wastedTime; // in minutes
  final bool aiSuggested;
  final List<Task> subTasks;

  Task({
    this.id,
    required this.title,
    required this.deadline,
    this.startTime,
    this.endTime,
    this.isCompleted = false,
    this.inProgress = false,
    this.wastedTime = 0,
    this.aiSuggested = false,
    this.subTasks = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "deadline": deadline.toIso8601String(),
      "startTime": startTime?.toIso8601String(),
      "endTime": endTime?.toIso8601String(),
      "isCompleted": isCompleted,
      "inProgress": inProgress,
      "wastedTime": wastedTime,
      "aiSuggested": aiSuggested,
      "subTasks": subTasks.map((t) => t.toJson()).toList(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json["id"]?.toString(),
      title: (json["title"] ?? "Untitled").toString(),
      deadline: json["deadline"] != null
          ? DateTime.tryParse(json["deadline"].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: json["startTime"] != null
          ? DateTime.tryParse(json["startTime"].toString())
          : null,
      endTime: json["endTime"] != null
          ? DateTime.tryParse(json["endTime"].toString())
          : null,
      isCompleted: json["isCompleted"] is bool
          ? json["isCompleted"]
          : (json["isCompleted"].toString().toLowerCase() == "true"),
      inProgress: json["inProgress"] is bool
          ? json["inProgress"]
          : (json["inProgress"].toString().toLowerCase() == "true"),
      wastedTime: (json["wastedTime"] ?? 0) is int
          ? json["wastedTime"]
          : int.tryParse(json["wastedTime"].toString()) ?? 0,
      aiSuggested: json["aiSuggested"] is bool
          ? json["aiSuggested"]
          : (json["aiSuggested"].toString().toLowerCase() == "true"),
      subTasks: (json["subTasks"] as List<dynamic>? ?? [])
          .map((e) => e is Map<String, dynamic> ? Task.fromJson(e) : null)
          .whereType<Task>()
          .toList(),
    );
  }

  factory Task.fromFirestore(Map<String, dynamic> data, String docId) {
    return Task.fromJson({...data, "id": docId});
  }

  Task copyWith({
    String? id,
    String? title,
    DateTime? deadline,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    bool? inProgress,
    int? wastedTime,
    bool? aiSuggested,
    List<Task>? subTasks,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      deadline: deadline ?? this.deadline,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      inProgress: inProgress ?? this.inProgress,
      wastedTime: wastedTime ?? this.wastedTime,
      aiSuggested: aiSuggested ?? this.aiSuggested,
      subTasks: subTasks ?? this.subTasks,
    );
  }

  @override
  String toString() =>
      "Task(id: $id, title: $title, subTasks: ${subTasks.length})";

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Task && id != null && id == other.id);

  @override
  int get hashCode => id?.hashCode ?? Object.hashAll([title, deadline]);
}
