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

import 'package:flutter/widgets.dart';

import 'json_intl.dart';
import 'json_intl_data.dart';
import 'loaders.dart';

@immutable
class JsonIntlDelegate extends LocalizationsDelegate<JsonIntl> {
  const JsonIntlDelegate({
    this.availableLocales,
    this.base = 'assets/intl',
    this.debug = false,
    this.mock = false,
  })  : assert(debug != null),
        assert(mock != null),
        assert(base != null);

  final String base;

  final bool debug;

  final bool mock;

  final List<String> availableLocales;

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
  bool shouldReload(JsonIntlDelegate old) => false;
}
