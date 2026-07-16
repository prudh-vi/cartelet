import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_static/shelf_static.dart';

/// A simple HTTP server to serve files from the Android device to the Mac client.
class CarteletFileServer {
  HttpServer? _server;
  final String rootDirectory;

  CarteletFileServer({required this.rootDirectory});

  /// Starts the HTTP server on the given [port].
  Future<void> start({int port = 8081}) async {
    // Handler to serve static files for downloads
    final staticHandler = createStaticHandler(rootDirectory, defaultDocument: 'index.html');

    // A custom router to handle API requests (e.g., getting the file list)
    final handler = const Pipeline()
        .addMiddleware(logRequests())
        .addHandler((Request request) async {
      
      // Endpoint to list files in the current root directory
      if (request.url.path == 'files') {
        return _handleFileListRequest();
      }
      
      // For all other requests, try to serve the static file
      return staticHandler(request);
    });

    _server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
    print('HTTP File Server listening on port ${_server?.port}');
  }

  /// Generates a JSON list of files in the [rootDirectory].
  Response _handleFileListRequest() {
    try {
      final dir = Directory(rootDirectory);
      if (!dir.existsSync()) {
        return Response.notFound('Directory not found');
      }

      final List<Map<String, dynamic>> fileList = [];
      final entities = dir.listSync(followLinks: false);

      for (var entity in entities) {
        final stat = entity.statSync();
        fileList.add({
          'name': entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty),
          'isDirectory': stat.type == FileSystemEntityType.directory,
          'size': stat.size,
          'modified': stat.modified.toIso8601String(),
        });
      }

      return Response.ok(
        jsonEncode(fileList),
        headers: {'Content-Type': 'application/json'},
      );
    } catch (e) {
      return Response.internalServerError(body: 'Failed to read directory: $e');
    }
  }

  /// Stops the HTTP server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    print('HTTP File Server stopped.');
  }
}
