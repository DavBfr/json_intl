// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'json_intl.dart';
import 'json_intl_data.dart';
import 'loaders.dart';

/// A factory for a set of localized JsonIntl resources to be loaded by a
/// [Localizations] widget.
@immutable
class JsonIntlDelegate extends LocalizationsDelegate<JsonIntl> {
  /// Create the factory responsible of loading the language files
  const JsonIntlDelegate({
    this.availableLocales,
    this.base = 'assets/intl',
    this.debug = false,
  });

  /// The assets path where to find the localization files
  final String base;

  /// Wether to use debug localizations or not.
  /// In debug mode, the string returned will contain debug information
  /// about how it is translated
  final bool debug;

  /// List of locales that can be used by the application. If null, the locales
  /// will be detected automatically.
  final List<String>? availableLocales;

  @override
  bool isSupported(Locale locale) {
    return true;
  }

  @override
  Future<JsonIntl> load(Locale locale) async {
    final data = JsonIntlData(debug);
    await loadMessages(locale, availableLocales, base, data);
    return JsonIntl(locale, data);
  }

  @override
  bool shouldReload(JsonIntlDelegate old) => !kReleaseMode;
}
