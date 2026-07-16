import 'dart:convert';
import 'dart:io';

/// A simple utility to check for Over-The-Air (OTA) updates via GitHub Releases.
/// This can be used by both the Android and Mac apps to notify users of new versions.
class OtaUpdater {
  final String owner;
  final String repo;
  final String currentVersion;

  OtaUpdater({
    required this.owner,
    required this.repo,
    required this.currentVersion,
  });

  /// Checks the latest GitHub release and returns the download URL if an update is available.
  /// Returns null if the current version is up to date or an error occurs.
  Future<String?> checkForUpdate() async {
    try {
      final url = Uri.parse('https://api.github.com/repos/$owner/$repo/releases/latest');
      final request = await HttpClient().getUrl(url);
      // GitHub API recommends setting a User-Agent
      request.headers.add('User-Agent', 'Cartelet-OTA-Updater');
      
      final response = await request.close();
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        
        final latestVersion = data['tag_name'] as String?;
        final htmlUrl = data['html_url'] as String?;
        
        if (latestVersion != null && htmlUrl != null) {
          if (_isNewerVersion(latestVersion, currentVersion)) {
            return htmlUrl;
          }
        }
      } else {
        print('Failed to check for updates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error checking for OTA update: $e');
    }
    
    return null;
  }

  /// Basic semantic version comparison.
  bool _isNewerVersion(String latest, String current) {
    // Remove 'v' prefixes if they exist
    final l = latest.replaceAll('v', '').split('.');
    final c = current.replaceAll('v', '').split('.');
    
    for (int i = 0; i < l.length; i++) {
      if (i >= c.length) return true; // latest has more segments (e.g. 1.0.1 vs 1.0)
      
      final lNum = int.tryParse(l[i]) ?? 0;
      final cNum = int.tryParse(c[i]) ?? 0;
      
      if (lNum > cNum) return true;
      if (lNum < cNum) return false;
    }
    
    return false; // They are equal or current is newer
  }
}
