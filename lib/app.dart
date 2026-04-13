part of 'main.dart';

class App extends StatelessWidget {
  const App({super.key});

  /// Initialize the app and the sensing, including requesting necessary permissions.
  Future<bool> init() async {
    await Permission.locationWhenInUse.request();
    await Permission.locationAlways.request();
    await Permission.activityRecognition.request();

    // For Android, also request notification permission
    Platform.isAndroid ? await Permission.notification.request() : null;

    await bloc.sensing.initialize();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // theme: ThemeData.light(),
      // darkTheme: ThemeData.dark(),
      theme: researchPackageTheme,
      darkTheme: researchPackageDarkTheme,
      debugShowCheckedModeBanner: false,
      title: 'Pulmonary Monitor',
      home: FutureBuilder(
        future: init(),
        builder: (context, snapshot) => (!snapshot.hasData)
            ? Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [CircularProgressIndicator()],
                  ),
                ),
              )
            : PulmonaryMonitorApp(key: key),
      ),
    );
  }
}

class PulmonaryMonitorApp extends StatefulWidget {
  const PulmonaryMonitorApp({super.key});
  @override
  PulmonaryMonitorAppState createState() => PulmonaryMonitorAppState();
}

class PulmonaryMonitorAppState extends State<PulmonaryMonitorApp> {
  int _selectedIndex = 0;

  final _pages = <Widget>[];

  @override
  void initState() {
    _pages.addAll([
      StudyPage(bloc.studyViewModel),
      TaskListPage(bloc.taskListViewModel),
    ]);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Study'),
          BottomNavigationBarItem(icon: Icon(Icons.spellcheck), label: 'Tasks'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onButtonPressed,
        child: ListenableBuilder(
          listenable: bloc.sensing.client,
          builder: (_, _) => !bloc.hasStudy
              ? Icon(Icons.add)
              : !bloc.isDeployed
              ? Icon(Icons.refresh)
              : bloc.isRunning
              ? Icon(Icons.pause)
              : Icon(Icons.play_arrow),
        ),
      ),
    );
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  /// Handle press on the floating action button.
  /// If there is no study, add a study first.
  /// If the study is not yet deployed, deploy it.
  /// Once deployed, resume/pause sensing.
  void _onButtonPressed() =>
      bloc.sensing.client.studies.isEmpty ? bloc.addStudy() : bloc.runStudy();
}
