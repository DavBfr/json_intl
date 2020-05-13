// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'json_intl_data.dart';

// ignore_for_file: public_member_api_docs

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

Future<void> loadMessages(
  Locale locale,
  List<String> availableLocales,
  String base,
  JsonIntlData into,
) async {
  final files = <String>{'$base/strings.json'};

  if (availableLocales == null ||
      availableLocales.contains(locale.languageCode)) {
    files.add('$base/strings-${locale.languageCode}.json');
  }

  if (availableLocales == null || availableLocales.contains(locale)) {
    files.add('$base/strings-$locale.json');
  }

  for (final file in files) {
    await _addMessagesFile(into, file);
  }
}
