import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // DevicePreview wraps the app in a phone frame when running on desktop/web
  // so the team can check the mobile layout without a device. Disabled in
  // release builds so real users never see the frame.
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => App(),
    ),
  );
}
