import 'dart:io';
import 'package:mock_server/server.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;
  await startMockServer(port: port);
}
