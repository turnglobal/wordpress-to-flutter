import 'package:flutter/material.dart';
import 'package:wp2fapp/src/app.dart';
import 'package:wp2fapp/src/config/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.loadFromAsset();
  runApp(const Wp2fApp());
}
