# json_intl

Flutter Internationalization library based on Json files

## Getting Started

Add a new asset folder to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  json_intl: [version]

flutter:
  assets:
    - assets/intl/
```

Add the translation delegate settings to your MaterialWidget and the list of supported languages:

```dart
MaterialApp(
  localizationsDelegates: const [
    JsonIntlDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ],
  supportedLocales: const [
    Locale('en'),
    Locale('fr'),
  ],
    home: ...,
);
```

On iOS, an extra step is necessary: add supported languages to ios/Runner/Info.plist:

```xml
<key>CFBundleLocalizations</key>
<array>
    <string>en</string>
    <string>fr</string>
</array>
```

Create the translation files in `assets/intl/`:

- `strings.json` is the default and fallback file. Any translation not found in another file will be taken here.
- `strings-XX.json` one file for each language. `strings-fr.json` French translations, `strings-de.json` for German, etc.
- `strings-XX-AA.json` can also be used for specific countries, like `strings-en-uk.json`

## Using the translations

The content of the files is a json dictionary containing a `key` / `value` list:

```json
{
    "app_name": "Flutter Demo",
    "increment": "Increment",
    "title": "Flutter Demo Home Page"
}
```

to get the values in the dart code, use:

```dart
JsonIntl.of(context).get(#app_name);
```

or

```dart
context.tr(#app_name);
```

### Plurals

The json entry will look like this:

```json
{
    "cart": {
        "one": "{{ count }} item in your Shopping cart",
        "other": "{{ count }} items in your Shopping cart"
    },
}
```

Other values are supported for specific values depending on the language: `"zero", "one", "two", "few", "many", "other"`

To use it in the application:

```dart
JsonIntl.of(context).count(itemCount, #cart);
```

The variable `{{ count }}` is automatically populated with `itemCount`.

### Gender

The json entry will look like this:

```json
{
    "child": {
        "male": "The boy",
        "female": "The girl",
        "neutral": "The kid"
    },
}
```

To use it in the application:

```dart
JsonIntl.of(context).gender(JsonIntlGender.female, #child);
```

### Mixing Plural and Gender

The json entry will look like this:

```json
{
    "child": {
        "male": {
          "one": "a boy",
          "many": "{{ count }} boys",
        },
        "female": {
          "one": "a girl",
          "many": "{{ count }} girls",
        },
        "neutral": {
          "one": "a child",
          "many": "{{ count }} children",
        }
    },
}
```

To use it in the application:

```dart
JsonIntl.of(context).translate(#child, gender: JsonIntlGender.female, count: 3);
```

## Generating the translations

It's also possible to generate a file that contains the translation keys and/or
the full translation strings for all languages.

### Translation keys only

To generate the translation keys, run:

```shell
flutter pub run json_intl
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
    JsonIntlDelegate(
      availableLocales: availableLocalesIntlKeys,
    ),
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
flutter pub run json_intl -b
```

this generates a file `lib/intl.dart` with the same data as
[translation keys only](#translation-keys-only), plus the translated strings.
To use it, replace `JsonIntlDelegate` in your `MaterialApp` Widget with:

```dart
MaterialApp(
  localizationsDelegates: const [
    JsonIntlDelegateBuiltin(
      data: dataIntlKeys,
      defaultLocale: defaultLocaleIntlKeys,
    ),
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
Usage:   json_intl [options...]

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
