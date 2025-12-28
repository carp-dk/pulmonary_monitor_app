part of '../main.dart';

/// This class implements the sensing layer.
///
/// In particular, it shown how sensing is configured locally on a phone, without
/// the need for using the CARP Web Service infrastructure. Hence, this app shows
/// how to create and run a protocol locally and store data locally in a SQLite
/// database.
///
/// It also shows how sensing is "recovered" during app restart including the
/// app task queue.
class Sensing {
  static final Sensing _instance = Sensing._();

  /// The client manager running on this smartphone.
  SmartPhoneClientManager client = SmartPhoneClientManager();

  /// The study for the currently running study deployment.
  /// Returns `null` if no study is deployed (yet).
  /// If multiple studies are deployed, returns the first one (this app only
  /// supports a single study at a time).
  SmartphoneStudy? get study =>
      client.studies.isEmpty ? null : client.studies.first;

  /// The deployment service used to deploy studies.
  DeploymentService deploymentService = SmartphoneDeploymentService();

  /// The total number of measurements sampled so far.
  int samplingSize = 0;

  /// The study runtime controller for this [study], if deployed.
  SmartphoneStudyController? get controller =>
      (study != null) ? client.getStudyController(study!) : null;

  /// Get the singleton sensing instance
  factory Sensing() => _instance;

  Sensing._() {
    // Create and register external sampling packages
    SamplingPackageRegistry().register(ContextSamplingPackage());
    SamplingPackageRegistry().register(MediaSamplingPackage());
    SamplingPackageRegistry().register(SurveySamplingPackage());
    SamplingPackageRegistry().register(ConnectivitySamplingPackage());
    // SamplingPackageRegistry().register(CommunicationSamplingPackage());
    SamplingPackageRegistry().register(AppsSamplingPackage());

    // Register the special-purpose audio user task factory
    AppTaskController().registerUserTaskFactory(PulmonaryUserTaskFactory());
  }

  /// Initialize and set up sensing.
  Future<void> initialize() async {
    info('Initializing $runtimeType');
    await Settings().init();

    info('$runtimeType - Configuring client...');

    await client.configure(
      deploymentService: deploymentService,
      askForPermissions: true,
    );

    // Listen on the measurements stream and count measurements
    // .. and print them as json.
    client.measurements.listen((measurement) {
      samplingSize++;
      print(toJsonString(measurement));
    });

    info('$runtimeType initialized');
  }
}
