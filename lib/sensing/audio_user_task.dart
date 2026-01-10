part of '../main.dart';

/// A user task handling audio recordings.
///
/// The [widget] returns an [AudioMeasurePage] that can be shown on the UI.
///
/// When the recording is started (calling the [onRecord] method),
/// the background task collecting sensor measures is started.
class AudioUserTask extends UserTask {
  final StreamController<int> _countDownController =
      StreamController.broadcast();
  Stream<int> get countDownEvents => _countDownController.stream;
  Timer? _timer;

  /// Duration of audio recording in seconds.
  int recordingDuration = 10;

  AudioUserTask(super.executor, [this.recordingDuration = 10]);

  @override
  bool get hasWidget => true;

  @override
  Widget? get widget => AudioMeasurePage(audioUserTask: this);

  /// Callback when recording is to start.
  /// When recording is started, background sensing is also started.
  void onRecord() {
    backgroundTaskExecutor.resume();

    // start the countdown, once tick pr. second.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _countDownController.add(--recordingDuration);

      if (recordingDuration <= 0) {
        _timer?.cancel();
        _countDownController.close();

        // stop the background sensing and mark this task as done
        backgroundTaskExecutor.pause();
        super.onDone();
      }
    });
  }
}

/// A factory that can [create] a [UserTask] based on the type of app task.
/// In this case an [AudioUserTask].
class PulmonaryUserTaskFactory implements UserTaskFactory {
  @override
  List<String> types = [AppTask.AUDIO_TYPE];

  @override
  UserTask create(AppTaskExecutor executor) {
    switch (executor.task.type) {
      case AppTask.AUDIO_TYPE:
        return AudioUserTask(executor);
      default:
        return BackgroundSensingUserTask(executor);
    }
  }
}
