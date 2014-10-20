// Copyright (c) 2014, the timezone project authors. Please see the AUTHORS
// file for details. All rights reserved. Use of this source code is governed
// by a BSD-style license that can be found in the LICENSE file.

/// TimeZone initialization for standalone environments.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then((_) {
///  final detroit = getLocation('America/Detroit');
///  final now = new TZDateTime.now(detroit);
/// });
library timezone.standalone;

import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as ospath;
import 'package:timezone/timezone.dart';

export 'package:timezone/timezone.dart' show getLocation, setLocalLocation,
    TZDateTime, timeZoneDatabase;

const _packagesPrefix = 'packages/';

/// Load file
Future<List<int>> _loadAsBytes(String path) {
  final script = Platform.script;
  final scheme = Platform.script.scheme;

  if (scheme.startsWith('http')) {
    return new HttpClient().getUrl(
        new Uri(
            scheme: script.scheme,
            host: script.host,
            port: script.port,
            path: path)).then((req) {
      return req.close();
    }).then((response) {
      // join byte buffers
      return response.fold(
          new BytesBuilder(),
          (b, d) => b..add(d)).then((builder) {
        return builder.takeBytes();
      });
    });

  } else if (scheme == 'file') {
    final packageRoot = Platform.packageRoot;
    if (packageRoot.isNotEmpty && path.startsWith(_packagesPrefix)) {
      final p = ospath.join(packageRoot, path.substring(_packagesPrefix.length));
      return new File(p).readAsBytes();
    }

    final p = ospath.join(ospath.dirname(script.path), path);
    return new File(p).readAsBytes();
  }

  return new Future.error(new UnimplementedError('Unknown script scheme: $scheme'));
}

/// Initialize Time Zone database.
///
/// Throws [TimeZoneInitException] when something is worng.
///
/// ```dart
/// import 'package:timezone/standalone.dart';
///
/// initializeTimeZone().then(() {
///   final detroit = getLocation('America/Detroit');
///   final detroitNow = new TZDateTime.now(detroit);
/// });
/// ```
Future initializeTimeZone([String path = tzDataDefaultPath]) {
  return _loadAsBytes(path).then((rawData) {
    initializeDatabase(rawData);
  }).catchError((e) {
    throw new TimeZoneInitException(e.toString());
  });
}
