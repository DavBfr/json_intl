import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:json_intl/json_intl.dart';

// ignore_for_file: public_member_api_docs

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // This replaces your [title] attribute, as we need a context to get the
      // translations
      onGenerateTitle: (BuildContext context) =>
          JsonIntl.of(context).get('app_name'),
      home: MyHomePage(),
      localizationsDelegates: const [
        JsonIntlDelegate(), // We add the intl delegate here
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      // Set the list of supported languages in this list.
      // On iOS, you will have to specify the list of languages in the file
      // Info.plist
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
        title: Text(JsonIntl.of(context).get('title')),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // A string translated depending on a number to count something
            Text(JsonIntl.of(context).count(
              _counter,
              'pushed',
              strict: false,
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        // We can use the BuildContext extension too:
        tooltip: context.tr('increment'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
