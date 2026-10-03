// Entrypoint for driving the real app on a device or simulator from the
// Dart tooling (`flutter run -t test_driver/app.dart`). Never shipped.
import 'package:flutter_driver/driver_extension.dart';
import 'package:sudokong/main.dart' as app;

void main() {
  enableFlutterDriverExtension();
  app.main();
}
