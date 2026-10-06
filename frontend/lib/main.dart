import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
export 'app.dart';

void main() {
  // OIDC redirects to /callback; use path URLs so GoRouter receives that path
  // instead of treating the browser's initial location as the app root.
  usePathUrlStrategy();
  runApp(const MyApp());
}
