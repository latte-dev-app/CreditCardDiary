import 'package:flutter/material.dart';
import 'app/app.dart';
import 'app/service_locator.dart';

void main() {
  setupServiceLocator();
  runApp(const MyApp());
}
