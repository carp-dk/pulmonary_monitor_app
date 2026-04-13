part of '../main.dart';

class InformedConsentPage extends StatefulWidget {
  const InformedConsentPage({super.key});

  @override
  State createState() => InformedConsentPageState();
}

class InformedConsentPageState extends State<InformedConsentPage> {
  String _encode(Object object) =>
      const JsonEncoder.withIndent(' ').convert(object);

  void resultCallback(RPTaskResult result, BuildContext context) {
    print(_encode(result));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return RPUITask(
      task: consent.informedConsent,
      onSubmit: (result) {
        resultCallback(result, context);
      },
    );
  }
}
