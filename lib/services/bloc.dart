part of '../main.dart';

class SensingBLoC {
  StudyViewModel? _studyViewModel;
  TaskListViewModel? _taskListViewModel;

  /// Create the BLoC, optionally specifying the [debugLevel].
  SensingBLoC({DebugLevel debugLevel = DebugLevel.warning}) {
    Settings().debugLevel = debugLevel;
  }

  /// The [Sensing] layer used in the app.
  Sensing get sensing => Sensing();

  /// The study running on this phone.
  SmartphoneStudy? get study => sensing.study;

  /// Is the any study added yet?
  bool get hasStudy => study != null;

  /// Is the study deployed?
  bool get isDeployed => study?.isDeployed ?? false;

  /// Is sensing running, i.e. has the study executor been started?
  bool get isRunning =>
      sensing.controller?.executor.state == ExecutorState.Resumed;

  /// Get the view model for the [StudyPage].
  StudyViewModel get studyViewModel =>
      _studyViewModel ??= StudyViewModel(study);

  /// Get the view model for the [TaskListPage].
  TaskListViewModel get taskListViewModel =>
      _taskListViewModel ??= TaskListViewModel();

  /// Add a study to the app based on the study protocol loaded from the local
  /// study protocol manager.
  Future<void> addStudy() async {
    // Get the protocol from the local study protocol manager.
    // Note that the study id is not used.
    StudyProtocol protocol = await LocalStudyProtocolManager().getStudyProtocol(
      '',
    );

    // Add the study from the protocol to the sensing client.
    await sensing.client.addStudyFromProtocol(protocol);

    // Update the study view model.
    if (study != null) studyViewModel.study = study!;
  }

  /// Run (start, resume, pause) [study] based on its current state.
  void runStudy() {
    if (study == null) return;

    debug(
      '$runtimeType - Running study - isDeployed: ${study!.isDeployed}, '
      'isSampling: ${study!.isSampling}',
    );

    // If the study has not been started (and deployed) yet, do this before
    // resuming or pausing.
    !study!.isDeployed
        ? sensing.client.tryDeployment(
            study!.studyDeploymentId,
            study!.deviceRoleName,
          )
        : study!.isSampling
        ? sensing.client.pause()
        : sensing.client.resume();
  }
}
