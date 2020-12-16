// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';
import 'package:simple_mustache/simple_mustache.dart';

import 'json_intl_data.dart';
import 'json_intl_mock_data.dart';
import 'json_intl_value.dart';

/// Main translation entry point.
/// to get an instance of this class, call
/// ```dart
/// JsonIntl.of(context)
/// ```
class JsonIntl {
  /// Create a translation instance from a [Locale] and a [JsonIntlData]
  const JsonIntl(this.locale, this._data);

  /// the locale this object can display
  final Locale locale;

  /// The list of translation units
  final JsonIntlData _data;

  /// Build a mocked translation object that will always return the key
  static const mock = JsonIntl(Locale('en', 'US'), JsonIntlMockData());

  /// Get the nearest JsonIntl instance available within the [context]
  static JsonIntl of(BuildContext context) {
    return Localizations.of<JsonIntl>(context, JsonIntl) ?? mock;
  }

  /// Return the string corresponding to [key], using [map] and [filters] to
  /// replace the mustache-like variables.
  String get(
    String key, [
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
  ]) {
    if (map == null) {
      return _data.translate(key);
    }

    return _data.translateWithMap(
      key,
      map: map,
      filters: filters,
      locale: locale.toLanguageTag(),
    );
  }

  /// Return the string corresponding to [key], using [map] and [filters] to
  /// replace the mustache-like variables.
  /// [value] is a number that helps to choose the right translation variant
  /// according to the current language rules.
  /// If [strict] is [false] the language rules are bent to always return the
  /// values for zero, one and two.
  String count(
    num value,
    String key, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    bool? strict,
  }) {
    return _data.translateWithMap(
      key,
      map: map,
      filters: filters,
      count: value,
      locale: locale.toLanguageTag(),
      strict: strict,
    );
  }

  /// Return the string corresponding to [key], using [map] and [filters] to
  /// replace the mustache-like variables.
  /// [gender] helps to choose the right translation variant for the specified
  /// gender.
  String gender(
    JsonIntlGender gender,
    String key, {
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
  }) {
    return _data.translateWithMap(
      key,
      map: map,
      filters: filters,
      gender: gender,
      locale: locale.toLanguageTag(),
    );
  }

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
  String translate(
    String key, {
    JsonIntlGender? gender,
    int? count,
    Map<String, dynamic>? map,
    Map<String, MustacheFilter>? filters,
    bool? strict,
  }) {
    if (map == null && count == null && gender == null) {
      return _data.translate(key);
    }

    return _data.translateWithMap(
      key,
      map: map,
      filters: filters,
      count: count,
      gender: gender,
      locale: locale.toLanguageTag(),
      strict: strict,
    );
  }
}
