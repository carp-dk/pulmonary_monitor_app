part of '../main.dart';

/// This is a simple local [StudyProtocolManager] which
/// creates the Pulmonary Monitor study protocol.
class LocalStudyProtocolManager implements StudyProtocolManager {
  @override
  Future<void> initialize() async {}

  @override
  Future<SmartphoneStudyProtocol> getStudyProtocol(String studyId) async {
    SmartphoneStudyProtocol protocol = SmartphoneStudyProtocol(
      name: 'Pulmonary Monitor',
      ownerId: 'alex@uni.dk',
    );
    protocol.studyDescription = StudyDescription(
        title: 'Pulmonary Monitor',
        description:
            "With the Pulmonary Monitor you can monitor your respiratory health. "
            "By using the phones sensors, including the microphone, it will try to monitor you breathing, heart rate, sleep, social contact to others, and your movement. "
            "You will also be able to fill in a simple daily survey to help us understand how you're doing. "
            "Before you start, please also fill in the demographics survey. ",
        purpose:
            'To collect basic data from users in their everyday life in order '
            'to investigate pulmonary-related symptoms.',
        responsible: StudyResponsible(
          id: 'jakba',
          title: 'Professor',
          address: 'Ørsteds Plads, 2100 Kgs. Lyngby',
          affiliation: 'Technical University of Denmark',
          email: 'jakba@dtu.dk',
          name: 'Jakob E. Bardram',
        ));

    // Define the data end point , i.e., where to store data.
    // This example app only stores data locally in a SQLite DB
    protocol.dataEndPoint = SQLiteDataEndPoint();

    // Define which devices are used for data collection.
    Smartphone phone = Smartphone();
    protocol.addPrimaryDevice(phone);

    // Define the online weather service and add it as a 'device'
    WeatherService weatherService =
        WeatherService(apiKey: '12b6e28582eb9298577c734a31ba9f4f');
    protocol.addConnectedDevice(weatherService, phone);

    // Define the online air quality service and add it as a 'device'
    AirQualityService airQualityService =
        AirQualityService(apiKey: '9e538456b2b85c92647d8b65090e29f957638c77');
    protocol.addConnectedDevice(airQualityService, phone);

    // Add the background sensing
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: SensorSamplingPackage.STEP_COUNT),
          Measure(type: SensorSamplingPackage.AMBIENT_LIGHT),
          Measure(type: DeviceSamplingPackage.SCREEN_EVENT),
          Measure(type: DeviceSamplingPackage.FREE_MEMORY),
          Measure(type: DeviceSamplingPackage.BATTERY_STATE),
        ]),
        phone);

    // // Add activity measure using the phone
    // protocol.addTaskControl(
    //     ImmediateTrigger(),
    //     BackgroundTask(
    //         measures: [Measure(type: ContextSamplingPackage.ACTIVITY)]),
    //     phone);

    // Define the online location service and add it as a 'device'.
    LocationService locationService = LocationService(
      // used for debugging when the phone is laying still on the table
      distance: 0,
    );

    protocol.addConnectedDevice(locationService, phone);

    // Add a background task that continuously collects location
    // and mobility features (e.g., home stay).
    protocol.addTaskControl(
        ImmediateTrigger(),
        BackgroundTask(measures: [
          Measure(type: ContextSamplingPackage.LOCATION),
          Measure(type: ContextSamplingPackage.MOBILITY)
        ]),
        locationService);

    // // Add audio measure in the background
    // protocol.addTaskControl(
    //     PeriodicTrigger(period: Duration(seconds: 40)),
    //     BackgroundTask(
    //       measures: [Measure(type: MediaSamplingPackage.AUDIO)],
    //       duration: const Duration(seconds: 5),
    //     ),
    //     phone);

    // The following contains the definition of the app (user) tasks.

    // Create an app task that collects air quality and weather data,
    // and notify the user.
    //
    // Note that for this to work, the air_quality and weather services needs
    // to be defined and added as connected devices to this phone.
    var environmentTask = AppTask(
        type: BackgroundSensingUserTask.SENSING_TYPE,
        title: "Location, Weather & Air Quality",
        description: "Collect location, weather and air quality",
        notification: true,
        measures: [
          Measure(type: ContextSamplingPackage.LOCATION),
          Measure(type: ContextSamplingPackage.WEATHER),
          Measure(type: ContextSamplingPackage.AIR_QUALITY),
        ]);

    var symptomsTask = RPAppTask(
      type: SurveyUserTask.SURVEY_TYPE,
      title: surveys.symptoms.title,
      description: surveys.symptoms.description,
      minutesToComplete: surveys.symptoms.minutesToComplete,
      rpTask: surveys.symptoms.survey,
      measures: [Measure(type: ContextSamplingPackage.LOCATION)],
    );

    var demographicsTask = RPAppTask(
      type: SurveyUserTask.SURVEY_TYPE,
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
      type: AudioUserTask.AUDIO_TYPE,
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

    // A Parkinson's assessment task.
    // This is strictly speaking not part of monitoring pulmonary symptoms,
    // but is included to illustrate the use of cognitive tests from the
    // cognition package.
    var parkinsonsTask = RPAppTask(
        type: SurveyUserTask.COGNITIVE_ASSESSMENT_TYPE,
        title: "Parkinson's' Assessment",
        description: "A simple task assessing finger tapping speed.",
        minutesToComplete: 3,
        rpTask: RPOrderedTask(
          identifier: "parkinsons_assessment",
          steps: [
            RPInstructionStep(
                identifier: 'parkinsons_instruction',
                title: "Parkinsons' Disease Assessment",
                text:
                    "In the following pages, you will be asked to solve two simple test which will help assess your symptoms on a daily basis. "
                    "Each test has an instruction page, which you should read carefully before starting the test.\n\n"
                    "Please sit down comfortably and hold the phone in one hand while performing the test with the other."),
            RPTimerStep(
              identifier: 'RPTimerStepID',
              timeout: const Duration(seconds: 6),
              title:
                  "Please stand up and hold the phone in one hand and lift it in a straight arm until you hear the sound.",
              playSound: true,
            ),
            RPFlankerActivity(
              identifier: 'flanker_1',
              lengthOfTest: 30,
              numberOfCards: 10,
            ),
            RPTappingActivity(
              identifier: 'tapping_1',
              lengthOfTest: 10,
            )
          ],
        ),
        measures: [
          Measure(type: SensorSamplingPackage.ACCELERATION),
          Measure(type: SensorSamplingPackage.ROTATION),
        ]);

    // Now add the tasks to the protocol using different trigger conditions.

    // always have a symptoms task on the list
    protocol.addTaskControl(
      NoUserTaskTrigger(taskName: symptomsTask.name),
      symptomsTask,
      phone,
    );

    // when a symptoms task is filled, add the demographics task
    protocol.addTaskControl(
        UserTaskTrigger(
            taskName: symptomsTask.name, triggerCondition: UserTaskState.done),
        demographicsTask,
        phone);

    // // Collect symptoms daily at 13:30
    // protocol.addTaskControl(
    //     RecurrentScheduledTrigger(
    //       type: RecurrentType.daily,
    //       time: const TimeOfDay(hour: 13, minute: 30),
    //     ),
    //     symptomsTask,
    //     phone);

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

    // Collect a coughing sample every hour at minute zero based on a cron expression.
    protocol.addTaskControl(
      CronScheduledTrigger.parse(cronExpression: '0 * * * *'),
      coughingTask,
      phone,
    );

    // Always keep a coughing task on the list.
    protocol.addTaskControl(
      NoUserTaskTrigger(taskName: coughingTask.name),
      coughingTask,
      phone,
    );

    // Always keep a Parkinson's task on the list.
    protocol.addTaskControl(
      NoUserTaskTrigger(taskName: parkinsonsTask.name),
      parkinsonsTask,
      phone,
    );

    // Add a task that keeps reappearing when done.

    protocol.addTaskControl(ImmediateTrigger(), environmentTask, phone);
    protocol.addTaskControl(
        UserTaskTrigger(
            taskName: environmentTask.name,
            triggerCondition: UserTaskState.done),
        environmentTask,
        phone);

    return protocol;
  }

  @override
  Future<bool> saveStudyProtocol(String studyId, StudyProtocol protocol) async {
    throw UnimplementedError();
  }
}
