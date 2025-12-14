part of '../main.dart';

class TaskList extends StatefulWidget {
  final TaskListViewModel viewModel;

  const TaskList(this.viewModel, {super.key});

  static const String routeName = '/tasklist';

  @override
  TaskListState createState() => TaskListState();
}

class TaskListState extends State<TaskList> {
  TaskListViewModel get model => widget.viewModel;

  @override
  Widget build(BuildContext context) {
    List<UserTask> tasks = model.tasks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        //TODO - move actions/settings icon to the app level.
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Theme.of(context).platform == TargetPlatform.iOS
                  ? Icons.more_horiz
                  : Icons.more_vert,
            ),
            tooltip: 'Settings',
            onPressed: _showSettings,
          ),
        ],
      ),
      body: StreamBuilder<UserTask>(
        stream: AppTaskController().userTaskEvents,
        builder: (context, AsyncSnapshot<UserTask> snapshot) {
          return Scrollbar(
            child: ListView.builder(
              itemCount: tasks.length,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemBuilder: (context, index) =>
                  _buildTaskCard(context, tasks[index]),
            ),
          );
        },
      ),
    );
  }

  void _showSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings not implemented yet...')));
  }

  Widget _buildTaskCard(BuildContext context, UserTask userTask) {
    return Center(
      child: Card(
        elevation: 10,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: StreamBuilder<UserTaskState>(
          stream: userTask.stateEvents,
          initialData: UserTaskState.initialized,
          builder: (context, AsyncSnapshot<UserTaskState> snapshot) => Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: taskTypeIcon[userTask.type],
                title: Text(userTask.title),
                subtitle: Text(userTask.description),
                trailing: taskStateIcon[userTask.state],
              ),
              (userTask.availableForUser)
                  ? OverflowBar(
                      children: <Widget>[
                        TextButton(
                            child: const Text('PRESS HERE TO FINISH TASK'),
                            onPressed: () {
                              // Mark the task as started.
                              userTask.onStart();

                              if (userTask.hasWidget) {
                                // Push the task widget to the app.
                                // Note that the widget is responsible for calling the onDone method
                                // when the task is done.
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<Widget>(
                                      builder: (context) => userTask.widget!),
                                );
                              } else {
                                // A non-UI sensing task that collects sensor data.
                                // Automatically stops after 10 seconds.
                                Timer(const Duration(seconds: 10),
                                    () => userTask.onDone());
                              }
                            }),
                      ],
                    )
                  : const Text(""),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, Icon> get taskTypeIcon => {
        SurveyUserTask.SURVEY_TYPE: const Icon(
          Icons.description,
          color: CachetColors.ORANGE,
          size: 40,
        ),
        SurveyUserTask.COGNITIVE_ASSESSMENT_TYPE: const Icon(
          Icons.face,
          color: CachetColors.YELLOW,
          size: 40,
        ),
        AudioUserTask.AUDIO_TYPE: const Icon(
          Icons.record_voice_over,
          color: CachetColors.GREEN,
          size: 40,
        ),
        BackgroundSensingUserTask.SENSING_TYPE: const Icon(
          Icons.settings_input_antenna,
          color: CachetColors.CACHET_BLUE,
          size: 40,
        ),
      };

  Map<UserTaskState, Icon> get taskStateIcon => {
        UserTaskState.initialized:
            const Icon(Icons.stream, color: CachetColors.YELLOW),
        UserTaskState.enqueued:
            const Icon(Icons.notifications, color: CachetColors.YELLOW),
        UserTaskState.dequeued:
            const Icon(Icons.not_interested_outlined, color: CachetColors.RED),
        UserTaskState.started:
            const Icon(Icons.radio_button_checked, color: CachetColors.GREEN),
        UserTaskState.canceled:
            const Icon(Icons.radio_button_off, color: CachetColors.RED),
        UserTaskState.done: const Icon(Icons.check, color: CachetColors.GREEN),
      };
}
