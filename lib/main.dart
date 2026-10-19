import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'app_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices.create();
  if (kDebugMode) services.log.stream.listen((line) => debugPrint('LOG $line'));
  services.start();
  runApp(ShiftPadApp(services: services));
}
