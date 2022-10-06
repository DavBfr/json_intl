// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:simple_mustache/simple_mustache.dart';

import 'json_intl.dart';
import 'json_intl_value.dart';

/// Extensions on BuildContext to shortcut the translations
extension BuildContextJsonIntl on BuildContext {
  /// General purpose translation
  ///
  /// Return the string corresponding to [key], using [map] and [filters] to
  /// replace the mustache-like variables.
  /// [gender] helps to choose the right translation variant for the specified
  /// gender.
  /// [value] is a number that helps to choose the right translation variant
  /// according to the current language rules.
  /// If [strict] is [false] the language rules are bent to always return the
  /// values for zero, one and two.
  String tr(
    Symbol key, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    JsonIntlGender? gender,
    int? count,
    bool? strict,
  }) {
    return JsonIntl.of(this).translate(
      key,
      gender: gender,
      count: count,
      map: map,
      filters: filters,
      strict: strict,
    );
  }
}
