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

For this, add `json_intl_gen` to your `dev_dependencies`.

and follow the documentation for [json_intl_gen](https://pub.dev/packages/json_intl_gen)
