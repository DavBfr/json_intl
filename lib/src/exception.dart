// Copyright (c) 2020, David PHAM-VAN <dev.nfet.net@gmail.com>
// All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// Translation error
class JsonIntlException implements Error {
  /// Create a translation error
  const JsonIntlException(this.message);

  /// The message describing the translation error
  final String message;

  @override
  String toString() => message;

  @override
  StackTrace? get stackTrace => null;
}
