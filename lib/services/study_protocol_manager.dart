part of '../main.dart';

/// This is a simple local [StudyProtocolManager] which
/// creates the Pulmonary Monitor study protocol.
class LocalStudyProtocolManager implements StudyProtocolManager {
  @override
  Future<void> initialize() async {}

  @override
  Future<SmartphoneStudyProtocol> getStudyProtocol(String studyId) async {
    var protocol = SmartphoneStudyProtocol(
      name: 'Pulmonary Monitor',
      ownerId: 'abc@uni.dk',
      studyDescription: StudyDescription(
        title: 'Pulmonary Monitor',
        description:
            "With the Pulmonary Monitor you can monitor your respiratory health. "
            "By using the phones sensors, including the microphone, it will try to monitor you breathing, heart rate, sleep, social contact to others, and your movement. "
            "You will also be able to fill in a simple daily survey to help us understand how you're doing. "
            "Before you start, please also fill in the demographics survey. ",
      ),
    );

    // Define the data end point , i.e., where to store data.
    // This example app only stores data locally in a SQLite DB
    protocol.dataEndPoint = SQLiteDataEndPoint();

    // Define which devices are used for data collection.
    Smartphone phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // Define the online location service and add it as a 'device'.
    final locationService = LocationService(
      // used for debugging when the phone is laying still on the table
      distance: 0,
    );
    protocol.addConnectedDevice(locationService, phone);

    // Define the online weather service and add it as a 'device'
    final weatherService = WeatherService(
      apiKey: '12b6e28582eb9298577c734a31ba9f4f',
    );
    protocol.addConnectedDevice(weatherService, phone);

    // Define the online air quality service and add it as a 'device'
    final airQualityService = AirQualityService(
      apiKey: '9e538456b2b85c92647d8b65090e29f957638c77',
    );
    protocol.addConnectedDevice(airQualityService, phone);

    // Create and add a health service (device)
    final healthService = HealthService();
    protocol.addConnectedDevice(healthService, phone);

    // --------- BACKGROUND TASKS ---------

    // Device data
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Device Information',
        measures: [
          Measure(type: DeviceSamplingPackage.DEVICE_INFORMATION),
          Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
          Measure(type: DeviceSamplingPackage.FREE_MEMORY),
          Measure(type: DeviceSamplingPackage.BATTERY_STATE),
          Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
        ],
      ),
      phone,
    );

    // Activity measures
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Activity',
        measures: [
          Measure(type: SensorSamplingPackage.STEP_EVENT),
          Measure(type: ContextSamplingPackage.ACTIVITY),
        ],
      ),
      phone,
    );

    // Add a background task that continuously collects location
    // and mobility features (e.g., home stay).
    protocol.addTaskControl(
      ImmediateTrigger(),
      BackgroundTask(
        name: 'Location & Mobility',
        measures: [
          Measure(type: ContextSamplingPackage.LOCATION),
          Measure(type: ContextSamplingPackage.MOBILITY),
        ],
      ),
      locationService,
    );

    // --------- APP / USER TASKS ---------

    // Create an app task that collects location, air quality and weather data,
    // and notify the user.
    //
    // Note that for this to work, the LocationService, AirQualityService, and
    // WeatherService needs to be defined and added as connected devices to
    // this phone.
    var environmentTask = AppTask(
      type: AppTask.SENSING_TYPE,
      name: 'Environment Task',
      title: "Location, Weather & Air Quality",
      description: "Collect location, weather and air quality",
      notification: true,
      measures: [
        Measure(type: ContextSamplingPackage.LOCATION)
          // Override the default sampling configuration to just get
          // a single location sample each time the task is triggered.
          // Otherwise, the default configuration for location is to do continuous
          // sampling, which is not what we want here.
          ..overrideSamplingConfiguration = LocationSamplingConfiguration(
            once: true,
          ),
        Measure(type: ContextSamplingPackage.WEATHER),
        Measure(type: ContextSamplingPackage.AIR_QUALITY),
      ],
    );

    var symptomsTask = RPAppTask(
      type: AppTask.SURVEY_TYPE,
      name: 'Symptoms Survey',
      title: surveys.symptoms.title,
      description: surveys.symptoms.description,
      minutesToComplete: surveys.symptoms.minutesToComplete,
      rpTask: surveys.symptoms.survey,
      measures: [Measure(type: ContextSamplingPackage.LOCATION)],
    );

    var demographicsTask = RPAppTask(
      type: AppTask.SURVEY_TYPE,
      name: 'Demographics Survey',
      title: surveys.demographics.title,
      description: surveys.demographics.description,
      minutesToComplete: surveys.demographics.minutesToComplete,
      notification: true,
      rpTask: surveys.demographics.survey,
      measures: [Measure(type: ContextSamplingPackage.LOCATION)],
    );

    // Collect a coughing sample.
    // Also collect current location, and local weather and air quality of this
    // sample.
    var coughingTask = AppTask(
      type: AppTask.AUDIO_TYPE,
      name: 'Coughing Task',
      title: "Coughing",
      description:
          'In this small exercise we would like to collect sound samples of coughing.',
      instructions:
          'Please press the record button below, and then cough 5 times.',
      minutesToComplete: 3,
      notification: true,
      measures: [
        Measure(type: MediaSamplingPackage.AUDIO),
        Measure(type: ContextSamplingPackage.LOCATION),
        Measure(type: ContextSamplingPackage.WEATHER),
        Measure(type: ContextSamplingPackage.AIR_QUALITY),
      ],
    );

    // A cognition assessment task.
    //
    // This is strictly speaking not part of monitoring pulmonary symptoms,
    // but is included to illustrate the use of cognitive tests from the
    // cognition package.
    // Note that this task also collects movement (accelerometer & gyroscope) data
    // while the user is performing the tests.
    var cognitionTask = RPAppTask(
      type: AppTask.COGNITIVE_ASSESSMENT_TYPE,
      name: 'Cognition Assessment',
      title: "Cognition Assessment",
      description:
          "A simple task assessing cognitive reaction time and tapping speed.",
      minutesToComplete: 3,
      rpTask: RPOrderedTask(
        identifier: "cognition_assessment",
        steps: [
          RPInstructionStep(
            identifier: 'cognition_instruction',
            title: "Cognition Assessment",
            text:
                "In the following pages, you will be asked to solve two simple test which will help assess your cognition on a daily basis. "
                "Each test has an instruction page, which you should read carefully before starting the test.\n\n"
                "Please sit down comfortably and hold the phone in one hand while performing the test with the other.",
          ),
          RPTimerStep(
            identifier: 'holding_phone_test',
            timeout: const Duration(seconds: 6),
            title:
                "Please stand up and hold the phone in one hand and lift it in a straight arm until you hear the sound.",
            playSound: true,
          ),
          RPFlankerActivity(
            identifier: 'flanker_test',
            lengthOfTest: 30,
            numberOfCards: 10,
          ),
          RPTappingActivity(identifier: 'tapping_test', lengthOfTest: 10),
        ],
      ),
      measures: [
        Measure(type: SensorSamplingPackage.ACCELERATION),
        Measure(type: SensorSamplingPackage.ROTATION),
      ],
    );

    var healthTask = HealthAppTask(
      title: "Press here to collect your physical health data",
      description:
          "This will collect your weight, exercise time, steps, and sleep "
          "time from the Health database on the phone.",
      types: [
        HealthDataType.WEIGHT,
        HealthDataType.STEPS,
        HealthDataType.BASAL_ENERGY_BURNED,
        HealthDataType.SLEEP_SESSION,
      ],
    );

    // Now add the tasks to the protocol using different trigger conditions.

    // Add the demographics task only once during a study.
    protocol.addTaskControl(OneTimeTrigger(), demographicsTask, phone);

    // Make sure to always have an environment task on the list by using
    // a NoUserTaskTrigger.
    protocol.addTaskControl(
      NoUserTaskTrigger(taskName: environmentTask.name),
      environmentTask,
      phone,
    );

    // // Perform a cognitive assessment every 2nd hour.
    // protocol.addTaskControl(
    //     PeriodicTrigger(period: const Duration(hours: 2)),
    //     RPAppTask(
    //       type: SurveyUserTask.COGNITIVE_ASSESSMENT_TYPE,
    //       title: surveys.cognition.title,
    //       description: surveys.cognition.description,
    //       minutesToComplete: surveys.cognition.minutesToComplete,
    //       rpTask: surveys.cognition.survey,
    //       measures: [Measure(type: ContextSamplingPackage.CURRENT_LOCATION)],
    //     ),
    //     phone);

    // // Collect a coughing sample every evening at 19:00 based on a cron expression.
    // protocol.addTaskControl(
    //   CronScheduledTrigger.parse(cronExpression: '0 19 * * *'),
    //   coughingTask,
    //   phone,
    // );

    // // Always keep a Cognitive Assessment task on the list.
    // protocol.addTaskControl(
    //   NoUserTaskTrigger(taskName: cognitionTask.name),
    //   cognitionTask,
    //   phone,
    // );

    // // Collect symptoms daily at 13:30
    // protocol.addTaskControl(
    //   RecurrentScheduledTrigger(
    //     type: RecurrentType.daily,
    //     time: const TimeOfDay(hour: 13, minute: 30),
    //   ),
    //   symptomsTask,
    //   phone,
    // );

    // Always keep a Symptoms assessment task on the list.
    protocol.addTaskControl(
      NoUserTaskTrigger(taskName: symptomsTask.name),
      symptomsTask,
      phone,
    );

    // When a symptoms task is done, trigger the coughing and cognition tasks.
    protocol.addTaskControls(
      UserTaskTrigger(
        taskName: symptomsTask.name,
        triggerCondition: UserTaskState.done,
      ),
      [coughingTask, cognitionTask],
      phone,
    );

    // When a the user is sitting still, add a task that collects health data
    protocol.addTaskControl(
      SamplingEventTrigger(
        measureType: ContextSamplingPackage.ACTIVITY,
        triggerCondition: Activity(type: ActivityType.STILL, confidence: 90),
      ),
      healthTask,
      phone,
    );

    return protocol;
  }

  @override
  Future<bool> saveStudyProtocol(String studyId, StudyProtocol protocol) async {
    throw UnimplementedError();
  }
}
