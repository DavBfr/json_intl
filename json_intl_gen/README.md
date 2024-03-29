# json_intl

Flutter Internationalization generator based on Json files

## Getting Started

Add `json_intl_gen` to your `dev_dependencies`.

```shell
flutter pub add --dev json_intl_gen
```

## Command-line generation

### Translation keys only

To generate the translation keys, run:

```shell
dart run json_intl_gen
```

this generates a file `lib/intl.dart` containing a class `IntlKeys` with all the
keys from the json files, using stardard Dart naming conventions.
To use it, simply do:

```dart
JsonIntl.of(context).get(IntlKeys.appName);
```

It will also generate a list of locales `supportedLocalesIntlKeys` and
`availableLocalesIntlKeys` found in the asset folder, directly usable in your
`MaterialApp` Widget:

```dart
MaterialApp(
  localizationsDelegates: const [
    jsonIntlDelegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: supportedLocalesIntlKeys,
  home: ...,
);
```

### Full translations

To generate the full translation strings into a dart source, run:

```shell
dart run json_intl_gen -b
```

this generates a file `lib/intl.dart` with the same data as
[translation keys only](#translation-keys-only), plus the translated strings.
Update your `MaterialApp` Widget with:

```dart
MaterialApp(
  localizationsDelegates: const [
    jsonIntlDelegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: supportedLocalesIntlKeys,
  home: ...,
);
```

You can then remove the `assets/intl/` folder from your `pubspec.yaml` as they
will not be used anymore. The translation strings are now part of the application.

### Command-line options

```
Usage:   json_intl_gen [options...]

Options:
-s, --source            Source intl directory
                        (defaults to "assets/intl")
-d, --destination       Destination dart file
                        (defaults to "lib/intl.dart")
-c, --classname         Destination class name
                        (defaults to "IntlKeys")
-l, --default-locale    Default generated locale
                        (defaults to "en")
-b, --builtin           Generate full built-in localizations
-m, --mangle            Change keys to a random string
-v, --verbose           Verbose output
    --version           Print the version information
-h, --help              Shows usage information
```

## build_runner generation

Add the `build_runner` dev dependency

```shell
flutter pub add --dev build_runner
```

Build the `intl.dart` file

```shell
dart run build_runner build
```

In your MaterialApp, add:

```dart
MaterialApp(
  localizationsDelegates: const [
    jsonIntlDelegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: supportedLocalesIntlKeys,
);
```

Builder options are configured in your pubspec.yaml:

```yaml
json_intl:
  class_name: IntlKeys
  default_locale: en
  mangle: false
  debug: false
  builtin: true
  source: assets/intl
  output: lib/intl.dart
  format: true
```
