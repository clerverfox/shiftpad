import 'package:flutter/material.dart';

import 'app.dart';
import 'app_services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final services = AppServices.create();
  services.start();
  runApp(ShiftPadApp(services: services));
}
