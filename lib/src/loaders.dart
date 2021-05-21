// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'json_intl_data.dart';
import 'json_intl_value.dart';
import 'log.dart';

// ignore_for_file: public_member_api_docs

Future<void> _addMessagesFile(JsonIntlData result, String filename) async {
  try {
    const decoder = JsonDecoder();
    final data = await rootBundle.loadString(filename, cache: kReleaseMode);
    final Map<String, dynamic> json = decoder.convert(data);
    log.info('Loaded $filename');
    result.append(json);
  } catch (_) {
    log.info('Language file not found $filename');
  }
}

Future<void> loadMessages(
  Locale locale,
  List<String>? availableLocales,
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

Future<void> loadMessagesBuiltin(
  Locale locale,
  Map<String, Map<String, JsonIntlValue>> data,
  JsonIntlData into,
  String defaultLocale,
) async {
  into.appendBuiltin(data[defaultLocale]!);

  if (data.containsKey(locale.languageCode)) {
    into.appendBuiltin(data[locale.languageCode]!);
  }

  if (data.containsKey(locale)) {
    into.appendBuiltin(data[locale]!);
  }
}
