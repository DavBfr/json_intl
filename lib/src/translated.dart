// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/widgets.dart';

import 'json_intl.dart';

// ignore_for_file: public_member_api_docs

class Translated extends StatelessWidget {
  const Translated(
    this.keyword, {
    Key? key,
    this.map,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
  }) : super(key: key);

  final String keyword;

  final Map<String, dynamic>? map;

  final TextStyle? style;

  final StrutStyle? strutStyle;

  final TextAlign? textAlign;

  final TextDirection? textDirection;

  final bool? softWrap;

  final TextOverflow? overflow;

  final double? textScaleFactor;

  final int? maxLines;

  final String? semanticsLabel;

  final TextWidthBasis? textWidthBasis;

  @override
  Widget build(BuildContext context) {
    final intl = JsonIntl.of(context);
    final data = intl.get(keyword, map)!;

    return Text(
      data,
      locale: intl.locale,
      maxLines: maxLines,
      overflow: overflow,
      semanticsLabel: semanticsLabel,
      softWrap: softWrap,
      strutStyle: strutStyle,
      style: style,
      textAlign: textAlign,
      textDirection: textDirection,
      textScaleFactor: textScaleFactor,
      textWidthBasis: textWidthBasis,
    );
  }
}
