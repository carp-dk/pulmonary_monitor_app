part of '../main.dart';

class StudyPage extends StatefulWidget {
  final StudyViewModel studyViewModel;
  const StudyPage(this.studyViewModel, {super.key});

  @override
  StudyPageState createState() => StudyPageState();
}

class StudyPageState extends State<StudyPage> {
  StudyViewModel get model => widget.studyViewModel;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: ListenableBuilder(
      listenable: model,
      builder: (BuildContext context, Widget? child) => CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            expandedHeight: 256.0,
            pinned: true,
            floating: false,
            snap: false,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(model.title),
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[model.image],
              ),
            ),
          ),
          SliverList(delegate: SliverChildListDelegate(_studyPanel())),
        ],
      ),
    ),
  );

  /// Show an info [message] in a snackbar.
  void _showInfo(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message, softWrap: true)));
  }

  List<Widget> _studyPanel() {
    List<Widget> children = [];

    children.add(
      AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: _studyControllerPanel(),
      ),
    );

    for (var task in model.deployment?.tasks ?? <TaskConfiguration>[]) {
      children.add(_TaskPanel(task: task));
    }

    return children;
  }

  Widget _studyControllerPanel() {
    final ThemeData themeData = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: themeData.dividerColor)),
      ),
      child: DefaultTextStyle(
        style: themeData.textTheme.bodyMedium!,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                width: 72.0,
                child: Icon(
                  Icons.lightbulb_outline,
                  size: 50,
                  color: CachetColors.ORANGE,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StudyControllerLine(model.description),
                    _StudyControllerLine(
                      model.studyStatus?.name,
                      heading: 'Study Status',
                    ),
                    _StudyControllerLine(
                      model.studyDeploymentId,
                      heading: 'Deployment ID',
                    ),
                    _StudyControllerLine(
                      model.deviceRoleName,
                      heading: 'Device Role',
                    ),
                    _StudyControllerLine(
                      model.participantRoleName,
                      heading: 'Participant Role',
                    ),
                    _StudyControllerLine(
                      model.dataEndpointType,
                      heading: 'Data Endpoint',
                    ),
                    StreamBuilder<ExecutorState>(
                      stream: model.executorStateEvents,
                      initialData: ExecutorState.Created,
                      builder: (_, _) => _StudyControllerLine(
                        model.executorState.name,
                        heading: 'Executor State',
                      ),
                    ),
                    StreamBuilder<Measurement>(
                      stream: model.measurements,
                      builder: (_, _) => _StudyControllerLine(
                        '${model.samplingSize}',
                        heading: 'Sample Size',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyControllerLine extends StatelessWidget {
  final String? line, heading;

  const _StudyControllerLine(this.line, {this.heading}) : super();

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: (heading == null)
            ? Text(line!, textAlign: TextAlign.left, softWrap: true)
            : Text.rich(
                TextSpan(
                  children: <TextSpan>[
                    TextSpan(
                      text: '$heading: ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: line),
                  ],
                ),
              ),
      ),
    );
  }
}

class _TaskPanel extends StatelessWidget {
  const _TaskPanel({this.task});

  final TaskConfiguration? task;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final List<Widget> measureLines =
        task!.measures?.map((measure) => _MeasureLine(measure)).toList() ?? [];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: themeData.dividerColor)),
      ),
      child: DefaultTextStyle(
        style: themeData.textTheme.titleMedium!,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(Icons.description, size: 40, color: CachetColors.ORANGE),
                  Text(
                    '  ${task!.name}',
                    style: themeData.textTheme.titleMedium,
                  ),
                ],
              ),
              Column(children: measureLines),
            ],
          ),
        ),
      ),
    );
  }
}

class _MeasureLine extends StatelessWidget {
  const _MeasureLine(this.measure);

  final Measure measure;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final Icon icon = (ProbeDescription.descriptors[measure.type]?.icon != null)
        ? Icon(ProbeDescription.descriptors[measure.type]!.icon?.icon, size: 25)
        : Icon(Icons.error, size: 25);

    final name =
        SamplingPackageRegistry()
            .samplingSchemes[measure.type]
            ?.dataType
            .displayName ??
        measure.type.split('.').last.toUpperCase();

    final columnChildren = <Widget>[];
    columnChildren.add(
      Text(
        name,
        style: themeData.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
    columnChildren.add(
      Text(measure.type, style: themeData.textTheme.bodySmall),
    );

    final List<Widget> rowChildren = [];
    rowChildren.add(
      SizedBox(width: 72.0, child: IconButton(icon: icon, onPressed: null)),
    );

    rowChildren.addAll([
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columnChildren,
        ),
      ),
    ]);
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: rowChildren,
        ),
      ),
    );
  }
}
