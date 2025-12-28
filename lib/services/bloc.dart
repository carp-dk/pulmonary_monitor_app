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
        ? sensing.client.start()
        : study!.isSampling
        ? sensing.client.pause()
        : sensing.client.resume();
  }

  //   // -------------------------------------------------------------------- //
  //   //                      TESTING PARAMETERS                              //
  //   // -------------------------------------------------------------------- //

  //   /// Deployment ID used for testing. This is used across app restart if not null.
  //   final String? testStudyDeploymentId = 'ae8076a3-7170-4bcf-b66c-64639a7a9eee';

  //   /// Should we save the app task queue across app restart
  //   bool get saveAppTaskQueueAcrossAppRestart => testStudyDeploymentId != null;

  //   // -------------------------------------------------------------------- //

  //   SmartphoneDeployment? get deployment => Sensing().deployment;
  //   StudyDeploymentModel? _model;

  //   /// The list of available app tasks for the user to address.
  //   List<UserTask> get tasks => AppTaskController().userTaskQueue;

  //   /// Get the study for this app.
  //   StudyDeploymentModel get studyDeploymentModel =>
  //       _model ??= StudyDeploymentModel(deployment!);

  //   SensingBLoC();

  //   Future<void> init() async {
  //     Settings().debugLevel = DebugLevel.debug;

  //     Settings().saveAppTaskQueue = saveAppTaskQueueAcrossAppRestart;

  //     await Settings().init();
  //     await Sensing().initialize();
  //     info('$runtimeType initialized');

  //     // This show how an app can listen to user task events.
  //     // Is not used in this app.
  //     AppTaskController().userTaskEvents.listen((event) {
  //       switch (event.state) {
  //         case UserTaskState.initialized:
  //           //
  //           break;
  //         case UserTaskState.enqueued:
  //           //
  //           break;
  //         case UserTaskState.dequeued:
  //           //
  //           break;
  //         case UserTaskState.started:
  //           //
  //           break;
  //         case UserTaskState.done:
  //           //
  //           break;
  //         case UserTaskState.undefined:
  //           //
  //           break;
  //         case UserTaskState.canceled:
  //           //
  //           break;
  //         case UserTaskState.expired:
  //           //
  //           break;
  //         case UserTaskState.notified:
  //           //
  //           break;
  //       }
  //     });
  //   }

  //   void start() async => Sensing().controller?.executor.start();
  //   void stop() async => Sensing().controller?.stop();

  //   /// Is sensing running, i.e. has the study executor been resumed?
  //   bool get isRunning =>
  //       (Sensing().controller != null) &&
  //       Sensing().controller!.executor.state == ExecutorState.started;
  // }
}
