import 'package:cloud_firestore/cloud_firestore.dart';
import '../modes/task.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// ✅ Add new task (parent with optional subtasks)
  Future<void> addTask(String uid, Task task) async {
    final tasksRef = _db.collection("users").doc(uid).collection("tasks");
    final docRef = task.id != null
        ? tasksRef.doc(task.id) // use provided id
        : tasksRef.doc(); // auto-generate if null

    await docRef.set(task.toJson());
  }

  /// ✅ Get all tasks as real-time stream
  Stream<List<Task>> getTasks(String uid) {
    return _db
        .collection("users")
        .doc(uid)
        .collection("tasks")
        .orderBy("deadline")
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            return Task.fromJson({
              ...data,
              "id": doc.id, // ✅ always override with Firestore docId
            });
          }).toList(),
        );
  }

  /// ✅ Update parent task (with subtasks if any)
  Future<void> updateTask(String uid, Task task) async {
    if (task.id == null) return; // prevent crash if id missing

    await _db
        .collection("users")
        .doc(uid)
        .collection("tasks")
        .doc(task.id)
        .set(task.toJson(), SetOptions(merge: true)); // safe merge
  }

  /// ✅ Delete parent task (and its subtasks since they live in same doc)
  Future<void> deleteTask(String uid, String taskId) async {
    await _db
        .collection("users")
        .doc(uid)
        .collection("tasks")
        .doc(taskId)
        .delete();
  }
}
