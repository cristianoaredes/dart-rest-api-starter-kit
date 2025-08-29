import 'dart:io';
import 'package:dart_rest_api_starter_kit/server.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  await startMockServer(port: port);
}
