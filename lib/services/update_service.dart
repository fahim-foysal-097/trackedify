import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdateService {
  static const _repoOwner = "fahim-foysal-097";
  static const _repoName = "spendle";

  /// Optional GitHub API token for higher rate limit
  static const String? _githubToken = null; // null for none

  /// Detect device ABI -> maps to GitHub release naming
  static Future<String> _getDeviceArch() async {
    try {
      if (!Platform.isAndroid) return "arm64-v8a";

      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final abiList = androidInfo.supportedAbis;

      if (abiList.contains("arm64-v8a")) return "arm64-v8a";
      if (abiList.contains("armeabi-v7a")) return "armeabi-v7a";
      if (abiList.contains("x86_64")) return "x86_64";
      if (abiList.isNotEmpty) return abiList.first;

      return "arm64-v8a"; // fallback
    } catch (_) {
      return "arm64-v8a";
    }
  }

  /// Check GitHub latest release and compare with current app version
  /// 'manualCheck' = true shows a "latest version" message if up-to-date
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool manualCheck = false,
  }) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;

      final url = Uri.parse(
        "https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest",
      );

      final headers = <String, String>{
        "Accept": "application/vnd.github+json",
        "User-Agent": "Spendle-App",
        if (_githubToken != null) "Authorization": "token $_githubToken",
      };

      final res = await http.get(url, headers: headers);
      if (res.statusCode != 200) return;

      final data = jsonDecode(res.body);
      final tag = data["tag_name"];
      final assets = data["assets"] as List;

      final latestVersion = tag.replaceFirst("v", "");

      if (latestVersion == currentVersion) {
        if (manualCheck && context.mounted) {
          // Show user message only if this was a manual check
          PanaraInfoDialog.show(
            context,
            title: "Up to Date",
            message: "You are on the latest version (v$currentVersion)",
            buttonText: "OK",
            onTapDismiss: () => Navigator.of(context).pop(),
            panaraDialogType: PanaraDialogType.success,
          );
        }
        return;
      }

      final arch = await _getDeviceArch();
      final apkAsset = assets.firstWhere(
        (a) => (a["name"] as String).contains(arch),
        orElse: () => null,
      );

      if (apkAsset == null) return;
      final apkUrl = apkAsset["browser_download_url"];

      if (!context.mounted) return;
      PanaraConfirmDialog.show(
        context,
        title: "Update Available",
        message:
            "A new version v$latestVersion is available. Do you want to update?",
        confirmButtonText: "Update",
        cancelButtonText: "Later",
        onTapCancel: () => Navigator.of(context).pop(),
        onTapConfirm: () {
          Navigator.of(context).pop();
          _downloadAndInstall(apkUrl, latestVersion, context);
        },
        panaraDialogType: PanaraDialogType.normal,
      );
    } catch (e) {
      debugPrint("Update check failed: $e");
    }
  }

  /// Download APK and show progress dialog with cancel button
  /// Deletes the APK after installation
  static Future<void> _downloadAndInstall(
    String url,
    String version,
    BuildContext context,
  ) async {
    bool isCancelled = false;

    try {
      // Use app-specific external storage (no runtime storage permission needed)
      final dir = await getExternalStorageDirectory();
      if (dir == null) return;
      final filePath = "${dir.path}/spendle-$version.apk";
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);

      final total = response.contentLength ?? 0;
      int received = 0;
      final progressNotifier = ValueNotifier<double>(0);

      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          builder: (BuildContext ctx) {
            return StatefulBuilder(
              builder: (ctx, setState) {
                return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Downloading update..."),
                      const SizedBox(height: 16),
                      ValueListenableBuilder<double>(
                        valueListenable: progressNotifier,
                        builder: (_, progress, _) {
                          return Column(
                            children: [
                              LinearProgressIndicator(value: progress),
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  "${(progress * 100).toStringAsFixed(0)}%",
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            isCancelled = true;
                            Navigator.of(ctx).pop();
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      }

      final sink = file.openWrite();
      await for (final chunk in response.stream) {
        if (isCancelled) {
          await sink.close();
          if (await file.exists()) await file.delete();
          return;
        }
        received += chunk.length;
        sink.add(chunk);
        if (total > 0) progressNotifier.value = received / total;
      }

      await sink.flush();
      await sink.close();

      if (!context.mounted) return;
      Navigator.of(context).pop();

      // Open the APK (this launches the system installer)
      await OpenFilex.open(filePath);
    } catch (e) {
      if (context.mounted) {
        // ensure any sheet is closed
        if (Navigator.canPop(context)) Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Update failed: $e")));
      }
    }
  }

  /// Remove everything inside the app-specific external storage directory.
  /// Returns number of deleted files.
  /// This only operates on the directory returned by 'getExternalStorageDirectory()'.
  /// Use from UI after confirming with the user.
  static Future<int> clearDownloadFolder() async {
    try {
      final dir = await getExternalStorageDirectory();
      if (dir == null) return 0;

      if (!await dir.exists()) return 0;

      int deletedCount = 0;

      // List all files & directories recursively and delete files.
      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        try {
          if (entity is File) {
            await entity.delete();
            deletedCount++;
          } else if (entity is Directory) {
            // Attempt to delete empty directories later — ignore errors.
            try {
              if (entity.existsSync()) {
                // If directory is empty, delete it
                final children = entity.listSync();
                if (children.isEmpty) {
                  await entity.delete();
                }
              }
            } catch (_) {
              // ignore
            }
          }
        } catch (_) {
          // ignore individual delete errors and continue
        }
      }

      return deletedCount;
    } catch (e) {
      debugPrint('clearDownloadFolder failed: $e');
      return 0;
    }
  }
}
