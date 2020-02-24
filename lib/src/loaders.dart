/*
 * Copyright (C) 2019, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

part of 'package:json_intl/json_intl.dart';

Future<void> _addMessagesFile(JsonIntlData result, String filename) async {
  try {
    const decoder = JsonDecoder();
    final data = await rootBundle.loadString(filename);
    final Map<String, dynamic> json = decoder.convert(data);

    assert(() {
      print('Loaded $filename');
      return true;
    }());

    result.append(json);
  } catch (e) {
    print('Language file not found $filename');
  }
}

Future<JsonIntlData> _loadMessages(
  Locale locale,
  List<String> availableLocales,
  String base,
) async {
  final result = JsonIntlData();

  final files = <String>{'$base/strings.json'};

  if (availableLocales == null ||
      availableLocales.contains(locale.languageCode)) {
    files.add('$base/strings-${locale.languageCode}.json');
  }

  if (availableLocales == null || availableLocales.contains(locale)) {
    files.add('$base/strings-$locale.json');
  }

  for (final file in files) {
    await _addMessagesFile(result, file);
  }

  return result;
}
