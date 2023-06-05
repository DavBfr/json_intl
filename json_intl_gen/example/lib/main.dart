import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:json_intl/json_intl.dart';

import 'intl.dart';

// ignore_for_file: public_member_api_docs

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // This replaces your [title] attribute, as we need a context to get the
      // translations
      onGenerateTitle: (BuildContext context) =>
          JsonIntl.of(context).get(IntlKeys.appName),
      home: const MyHomePage(),
      localizationsDelegates: const [
        jsonIntlDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: supportedLocalesIntlKeys,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // A simple translated title
        title: Text(JsonIntl.of(context).get(IntlKeys.title)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // A string translated depending on a number to count something
            Text(JsonIntl.of(context)
                .later('Pushed {{ numbers }}', map: {'numbers': _counter})),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        // We can use the BuildContext extension too:
        tooltip: context.tr(IntlKeys.increment),
        child: const Icon(Icons.add),
      ),
    );
  }
}
