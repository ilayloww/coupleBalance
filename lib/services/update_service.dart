import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
  final String statusMessage;

  const UpdateProgressState({
    this.progress = 0.0,
    this.isDone = false,
    this.error,
    this.filePath,
    this.statusMessage = 'Downloading...',
  });

  UpdateProgressState copyWith({
    double? progress,
    bool? isDone,
    String? error,
    String? filePath,
    String? statusMessage,
  }) {
    return UpdateProgressState(
      progress: progress ?? this.progress,
      isDone: isDone ?? this.isDone,
      error: error, // Nullable override
      filePath: filePath ?? this.filePath,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class UpdateService {
  static const String _owner = 'ilayloww';
  static const String _repo = 'coupleBalance';
  static const String _latestReleaseUrl =
      'https://api.github.com/repos/$_owner/$_repo/releases/latest';

  /// Allowed download URL prefixes (pin to GitHub domains).
  static const List<String> _allowedUrlPrefixes = [
    'https://github.com/',
    'https://objects.githubusercontent.com/',
  ];

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

          // Extract expected SHA-256 hash from release body
          String? releaseBody = releaseData['body'] as String?;
          String? expectedHash = _extractSha256(
            releaseBody,
            assets,
            downloadUrl,
          );

          if (downloadUrl != null && context.mounted) {
            _showUpdateDialog(
              context,
              downloadUrl,
              latestVersion,
              expectedHash,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking for updates: $e');
      }
    }
  }

  /// Extracts SHA-256 hash from the release body text.
  ///
  /// Supports formats:
  /// - `SHA256: <hex>`  (single APK)
  /// - `SHA256-arm64-v8a: <hex>`  (per-ABI APKs)
  /// - `SHA256-armeabi-v7a: <hex>`
  /// - `SHA256-universal: <hex>`
  String? _extractSha256(
    String? releaseBody,
    List<dynamic> assets,
    String? downloadUrl,
  ) {
    if (releaseBody == null || releaseBody.isEmpty || downloadUrl == null) {
      return null;
    }

    // Determine which APK name we're downloading
    String? apkName;
    for (var asset in assets) {
      if (asset['browser_download_url'] == downloadUrl) {
        apkName = asset['name']?.toString().toLowerCase();
        break;
      }
    }

    // Try ABI-specific hash first (e.g., SHA256-arm64-v8a: abc123)
    if (apkName != null) {
      for (final abi in ['arm64-v8a', 'armeabi-v7a', 'x86_64', 'universal']) {
        if (apkName.contains(abi)) {
          final match = RegExp(
            r'SHA256-' + RegExp.escape(abi) + r'\s*:\s*([a-fA-F0-9]{64})',
            caseSensitive: false,
          ).firstMatch(releaseBody);
          if (match != null) {
            return match.group(1)!.toLowerCase();
          }
        }
      }
    }

    // Fall back to generic SHA256: <hash>
    final genericMatch = RegExp(
      r'(?<!\w)SHA256\s*:\s*([a-fA-F0-9]{64})',
      caseSensitive: false,
    ).firstMatch(releaseBody);
    if (genericMatch != null) {
      return genericMatch.group(1)!.toLowerCase();
    }

    return null;
  }

  /// Computes the SHA-256 hash of a file.
  Future<String> _computeFileHash(String filePath) async {
    final file = File(filePath);
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Validates that the download URL is from an allowed domain (HTTPS only).
  bool _isUrlAllowed(String url) {
    if (!url.startsWith('https://')) return false;
    return _allowedUrlPrefixes.any((prefix) => url.startsWith(prefix));
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
    String? expectedHash,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Available'),
        content: Text(
          'A new version ($version) is available. Would you like to update?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startDownloadProcess(context, downloadUrl, expectedHash);
            },
            child: const Text('Update Now'),
          ),
        ],
      ),
    );
  }

  Future<void> _startDownloadProcess(
    BuildContext context,
    String url,
    String? expectedHash,
  ) async {
    // Validate download URL before starting
    if (!_isUrlAllowed(url)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Update blocked: download URL is not from a trusted source.',
            ),
          ),
        );
      }
      return;
    }

    final stateNotifier = ValueNotifier<UpdateProgressState>(
      const UpdateProgressState(),
    );
    final cancelToken = CancelToken();

    // Trigger download in background
    _performDownload(url, expectedHash, stateNotifier, cancelToken);

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
                        state.error!,
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
                      Text(state.statusMessage),
                      const SizedBox(height: 4),
                      Text(
                        '${(state.progress * 100).clamp(0, 100).toStringAsFixed(0)}%',
                      ),
                    ],
                  ],
                ),
                actions: [
                  // Cancel/Close button
                  if (!state.isDone && state.error == null)
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

    // Ensure cancellation if dialog is closed by other means
    if (!cancelToken.isCancelled && !stateNotifier.value.isDone) {
      cancelToken.cancel('Dialog closed');
    }

    stateNotifier.dispose();
  }

  Future<void> _performDownload(
    String url,
    String? expectedHash,
    ValueNotifier<UpdateProgressState> notifier,
    CancelToken cancelToken,
  ) async {
    try {
      Directory? tempDir = await getExternalStorageDirectory();
      String fileName = 'update_${DateTime.now().millisecondsSinceEpoch}.apk';
      String savePath = '${tempDir?.path}/$fileName';
      if (kDebugMode) {
        debugPrint('Downloading to: $savePath');
      }

      await Dio().download(
        url,
        savePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            double progress = (received / total).clamp(0.0, 1.0);
            notifier.value = notifier.value.copyWith(
              progress: progress,
              statusMessage: 'Downloading...',
            );
          }
        },
      );

      // Verify file exists
      if (!await File(savePath).exists()) {
        throw Exception('File downloaded but not found at path');
      }

      // --- Integrity verification ---
      if (expectedHash != null) {
        notifier.value = notifier.value.copyWith(
          statusMessage: 'Verifying integrity...',
        );

        final actualHash = await _computeFileHash(savePath);

        if (actualHash != expectedHash) {
          // Hash mismatch — delete the file and report error
          await File(savePath).delete();
          notifier.value = notifier.value.copyWith(
            error:
                'Integrity check failed: the downloaded file does not match '
                'the expected checksum. The update has been discarded for your safety.',
          );
          return;
        }

        if (kDebugMode) {
          debugPrint('SHA-256 verified successfully.');
        }
      } else {
        // No hash available — this is not an error, just a warning
        if (kDebugMode) {
          debugPrint(
            'No SHA-256 hash found in release notes. '
            'Skipping integrity verification.',
          );
        }
      }

      notifier.value = notifier.value.copyWith(
        progress: 1.0,
        isDone: true,
        filePath: savePath,
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        if (kDebugMode) {
          debugPrint('Download canceled');
        }
      } else {
        if (kDebugMode) {
          debugPrint('Download error: $e');
        }
        notifier.value = notifier.value.copyWith(error: e.toString());
      }
    }
  }

  Future<void> _installApk(BuildContext context, String filePath) async {
    try {
      if (kDebugMode) {
        debugPrint('Installing from: $filePath');
      }
      final result = await OpenFilex.open(
        filePath,
        type: 'application/vnd.android.package-archive',
      );
      if (kDebugMode) {
        debugPrint('Install result: ${result.type} - ${result.message}');
      }

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
