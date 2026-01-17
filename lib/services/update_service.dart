import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'package:device_info_plus/device_info_plus.dart';

class UpdateService {
  static const String _owner = 'ilayloww';
  static const String _repo = 'coupleBalance';
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      // Get current version
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      // Get latest release info from GitHub
      var response = await Dio().get(_latestReleaseUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> releaseData = response.data;
        String tagName = releaseData['tag_name'];
        // Remove 'v' prefix if present
        String latestVersion = tagName.replaceAll('v', '');

        if (_isNewerVersion(currentVersion, latestVersion)) {
          // Find APK asset
          List<dynamic> assets = releaseData['assets'];
          String? downloadUrl = await _findCorrectApk(assets);

          if (downloadUrl != null && context.mounted) {
            _showUpdateDialog(context, downloadUrl, latestVersion);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
    }
  }

  Future<String?> _findCorrectApk(List<dynamic> assets) async {
    // If only one APK, just use it
    List<dynamic> apkAssets = assets
        .where((a) => a['name'].toString().endsWith('.apk'))
        .toList();
    if (apkAssets.isEmpty) return null;
    if (apkAssets.length == 1) return apkAssets.first['browser_download_url'];

    // If multiple, try to match ABI
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      List<String> supportedAbis = androidInfo.supportedAbis;

      debugPrint('Device Supported ABIs: $supportedAbis');

      // Try to find match in order of preference (most preferred first)
      for (String abi in supportedAbis) {
        for (var asset in apkAssets) {
          String name = asset['name'].toString().toLowerCase();
          // Standard Flutter split names often contain the ABI
          // e.g. app-arm64-v8a-release.apk
          if (name.contains(abi.toLowerCase())) {
            debugPrint('Found matching APK for ABI $abi: $name');
            return asset['browser_download_url'];
          }
        }
      }
    }

    // Fallback: If no specific match, maybe prefer arm64-v8a if available as user suggested,
    // or just take the first one (risky but better than nothing).
    // Let's try to find 'universal' if exists, otherwise first.
    var universal = apkAssets.firstWhere(
      (a) => a['name'].toString().toLowerCase().contains('universal'),
      orElse: () => null,
    );
    if (universal != null) return universal['browser_download_url'];

    // Last resort: Just return the first one (or maybe the largest one? usually universal is larger)
    return apkAssets.first['browser_download_url'];
  }

  bool _isNewerVersion(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }

  void _showUpdateDialog(
    BuildContext context,
    String downloadUrl,
    String version,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Available'),
        content: Text(
          'A new version ($version) is available. Would you like to update?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _downloadAndInstall(context, downloadUrl);
            },
            child: Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadAndInstall(BuildContext context, String url) async {
    final progressNotifier = ValueNotifier<double>(0.0);

    // Show progress dialog
    // We use a PopScope (or WillPopScope for older Flutter) to prevent back button
    // But PopScope is correctly available in newer Flutter versions.
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: ValueListenableBuilder<double>(
          valueListenable: progressNotifier,
          builder: (context, value, child) {
            return AlertDialog(
              title: const Text('Downloading Update...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: value),
                  const SizedBox(height: 10),
                  Text('${(value * 100).toStringAsFixed(0)}%'),
                ],
              ),
            );
          },
        ),
      ),
    );

    try {
      Directory? tempDir = await getExternalStorageDirectory();
      String savePath = '${tempDir?.path}/update.apk';

      await Dio().download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progressNotifier.value = received / total;
          }
        },
      );

      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        await OpenFilex.open(savePath);
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    } finally {
      progressNotifier.dispose();
    }
  }
}
