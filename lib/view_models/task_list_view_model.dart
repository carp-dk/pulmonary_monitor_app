part of '../main.dart';

/// A view model for the [StudyPage] view.
class TaskListViewModel with ChangeNotifier {
  TaskListViewModel() : super() {
    // Listen to user task events and notify listeners on changes.
    AppTaskController().userTaskEvents.listen((_) {
      notifyListeners();
    });
  }

  /// The list of available app tasks for the user to address.
  List<UserTask> get tasks =>
      AppTaskController().userTaskQueue.reversed.toList();
}
