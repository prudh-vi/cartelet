import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// A simple HTTP file browser UI to view and download files from the Android device.
class FileBrowserScreen extends StatefulWidget {
  final String ip;
  final int port;

  const FileBrowserScreen({Key? key, required this.ip, required this.port}) : super(key: key);

  @override
  State<FileBrowserScreen> createState() => _FileBrowserScreenState();
}

class _FileBrowserScreenState extends State<FileBrowserScreen> {
  List<dynamic> _files = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  /// Fetches the list of files from the Android device's HTTP server.
  Future<void> _fetchFiles() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // The Android server will expose a /files endpoint returning a JSON list
      final response = await http.get(Uri.parse('http://${widget.ip}:${widget.port}/files'));
      
      if (response.statusCode == 200) {
        setState(() {
          _files = jsonDecode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load files: HTTP ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error connecting to device: $e';
        _isLoading = false;
      });
    }
  }

  /// Initiates a file download (to be implemented fully later).
  void _downloadFile(String filename) {
    // Scaffold for file download logic
    final url = 'http://${widget.ip}:${widget.port}/download/$filename';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Downloading $filename from $url...')),
    );
    // TODO: Implement actual file download and saving to Mac filesystem
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFiles,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchFiles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(
        child: Text('No files found on the device.'),
      );
    }

    return ListView.builder(
      itemCount: _files.length,
      itemBuilder: (context, index) {
        final file = _files[index];
        final filename = file['name'] ?? 'Unknown';
        final isDir = file['isDirectory'] == true;
        final size = file['size'] ?? 0;

        return ListTile(
          leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
          title: Text(filename),
          subtitle: Text(isDir ? 'Directory' : '$size bytes'),
          trailing: isDir ? null : IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadFile(filename),
          ),
          onTap: () {
            if (!isDir) {
              _downloadFile(filename);
            } else {
              // TODO: Navigate into directory
            }
          },
        );
      },
    );
  }
}
