// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:json_intl/json_intl.dart';

import 'json_intl.dart';
import 'json_intl_data.dart';
import 'json_intl_value.dart';
import 'loaders.dart';

/// A factory for a set of localized JsonIntl resources to be loaded by a
/// [Localizations] widget.
@immutable
class JsonIntlDelegateBuiltin extends LocalizationsDelegate<JsonIntl> {
  /// Create the factory responsible of loading the language files
  const JsonIntlDelegateBuiltin({
    required this.data,
    this.defaultLocale = 'en',
    this.debug = false,
  });

  /// Default locale to use as fallback
  final String defaultLocale;

  /// The translation data
  final Map<String, Map<Symbol, JsonIntlValue>> data;

  /// Wether to use debug localizations or not.
  /// In debug mode, the string returned will contain debug information
  /// about how it is translated
  final bool debug;

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<JsonIntl> load(Locale locale) async {
    final into = JsonIntlData(debug);
    await loadMessagesBuiltin(locale, data, into, defaultLocale);
    return JsonIntl(locale, into);
  }

  @override
  bool shouldReload(JsonIntlDelegateBuiltin old) => !kReleaseMode;
}
