import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Simple state class to manage the dialog UI
class UpdateProgressState {
  final double progress; // 0.0 to 1.0
  final bool isDone;
  final String? error;
  final String? filePath;

  const UpdateProgressState({
    this.progress = 0.0,
    this.isDone = false,
    this.error,
    this.filePath,
  });

  UpdateProgressState copyWith({
    double? progress,
    bool? isDone,
    String? error,
    String? filePath,
  }) {
    return UpdateProgressState(
      progress: progress ?? this.progress,
      isDone: isDone ?? this.isDone,
      error: error, // Nullable override
      filePath: filePath ?? this.filePath,
    );
  }
}

class UpdateService {
  static const String _owner = 'ilayloww';
  static const String _repo = 'coupleBalance';
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  Future<void> checkForUpdate(BuildContext context) async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      String currentVersion = packageInfo.version;

      var response = await Dio().get(_latestReleaseUrl);
      if (response.statusCode == 200) {
        Map<String, dynamic> releaseData = response.data;
        String tagName = releaseData['tag_name'];
        String latestVersion = tagName.replaceAll('v', '');

        if (_isNewerVersion(currentVersion, latestVersion)) {
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
    List<dynamic> apkAssets = assets
        .where((a) => a['name'].toString().endsWith('.apk'))
        .toList();
    if (apkAssets.isEmpty) return null;
    if (apkAssets.length == 1) return apkAssets.first['browser_download_url'];

    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      List<String> supportedAbis = androidInfo.supportedAbis;

      for (String abi in supportedAbis) {
        for (var asset in apkAssets) {
          String name = asset['name'].toString().toLowerCase();
          if (name.contains(abi.toLowerCase())) {
            return asset['browser_download_url'];
          }
        }
      }
    }

    var universal = apkAssets.firstWhere(
      (a) => a['name'].toString().toLowerCase().contains('universal'),
      orElse: () => null,
    );
    if (universal != null) return universal['browser_download_url'];

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
              _startDownloadProcess(context, downloadUrl);
            },
            child: Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownloadProcess(BuildContext context, String url) async {
    final stateNotifier = ValueNotifier<UpdateProgressState>(
      const UpdateProgressState(),
    );
    final cancelToken = CancelToken();

    // Trigger download in background
    _performDownload(url, stateNotifier, cancelToken);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: ValueListenableBuilder<UpdateProgressState>(
            valueListenable: stateNotifier,
            builder: (context, state, child) {
              return AlertDialog(
                title: Text(
                  state.isDone
                      ? 'Download Complete'
                      : state.error != null
                      ? 'Download Failed'
                      : 'Downloading Update...',
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state.error != null)
                      Text(
                        'Error: ${state.error}',
                        style: const TextStyle(color: Colors.red),
                      )
                    else if (state.isDone)
                      const Text('The update is ready to install.')
                    else ...[
                      LinearProgressIndicator(
                        value: state.progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${(state.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ],
                ),
                actions: [
                  // Cancel/Close button
                  if (!state.isDone)
                    TextButton(
                      onPressed: () {
                        if (!cancelToken.isCancelled) {
                          cancelToken.cancel('User canceled');
                        }
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel'),
                    ),

                  // Install button appears when done
                  if (state.isDone)
                    ElevatedButton(
                      onPressed: () {
                        if (state.filePath != null) {
                          _installApk(context, state.filePath!);
                        }
                      },
                      child: const Text('Install'),
                    ),

                  if (state.error != null)
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                ],
              );
            },
          ),
        );
      },
    );

    // Ensure cancellation if dialog is closed by other means (though barrierDismissible is false)
    if (!cancelToken.isCancelled && !stateNotifier.value.isDone) {
      cancelToken.cancel('Dialog closed');
    }

    stateNotifier.dispose();
  }

  Future<void> _performDownload(
    String url,
    ValueNotifier<UpdateProgressState> notifier,
    CancelToken cancelToken,
  ) async {
    try {
      Directory? tempDir = await getExternalStorageDirectory();
      String fileName = 'update_${DateTime.now().millisecondsSinceEpoch}.apk';
      String savePath = '${tempDir?.path}/$fileName';
      debugPrint('Downloading to: $savePath');

      await Dio().download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total).clamp(0.0, 1.0);
            notifier.value = notifier.value.copyWith(progress: progress);
          }
        },
      );

      // Verify
      if (await File(savePath).exists()) {
        notifier.value = notifier.value.copyWith(
          progress: 1.0,
          isDone: true,
          filePath: savePath,
        );
      } else {
        throw Exception('File downloaded but not found at path');
      }
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        debugPrint('Download canceled');
        // We might not need to update state if dialog is closing,
        // but if the dialog is still open (e.g. error view), we can show it.
        // Usually if canceled, the dialog is already popping.
      } else {
        debugPrint('Download error: $e');
        notifier.value = notifier.value.copyWith(error: e.toString());
      }
    }
  }

  Future<void> _installApk(BuildContext context, String filePath) async {
    try {
      debugPrint('Installing from: $filePath');
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint('Install result: ${result.type} - ${result.message}');

      if (result.type != ResultType.done) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Installation attempt finished: ${result.message}'),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error launching installer: $e')),
        );
      }
    }
  }
}
