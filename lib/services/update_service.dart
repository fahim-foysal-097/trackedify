import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateService {
  static const _repoOwner = "fahim-foysal-097";
  static const _repoName = "spendle";

  /// Optional GitHub API token for higher rate limit
  static const String? _githubToken = null; // null for none

  /// Session guard: ensure automatic checks run only once per app session.
  /// Manual checks (manualCheck == true) bypass this guard.
  static bool _hasCheckedThisSession = false;

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

  /// Expose a helper to check whether automatic check already ran this session.
  /// (Useful for debugging / tests.)
  static bool hasCheckedThisSession() => _hasCheckedThisSession;

  /// Reset the session flag (rarely needed; useful for tests or developer flows)
  static void resetSessionCheckFlag() {
    _hasCheckedThisSession = false;
  }

  /// Compare two semantic-ish version strings.
  /// Returns:
  ///  - 1 if a > b
  ///  - 0 if a == b
  ///  - -1 if a < b
  /// Non-numeric parts are treated as 0.
  static int _compareVersions(String a, String b) {
    if (a == b) return 0;
    final aParts = a.split(RegExp(r'[-+]'))[0].split('.');
    final bParts = b.split(RegExp(r'[-+]'))[0].split('.');

    final len = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var i = 0; i < len; i++) {
      final ai = i < aParts.length ? int.tryParse(aParts[i]) ?? 0 : 0;
      final bi = i < bParts.length ? int.tryParse(bParts[i]) ?? 0 : 0;
      if (ai > bi) return 1;
      if (ai < bi) return -1;
    }
    return 0;
  }

  /// Open release page in external browser (best-effort).
  static Future<void> _openReleasePage(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (kDebugMode) debugPrint('Could not launch $url');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to open release page: $e');
    }
  }

  /// Check GitHub latest release and compare with current app version
  /// 'manualCheck' = true shows a "latest version" message if up-to-date and
  /// bypasses the once-per-session guard.
  static Future<void> checkForUpdate(
    BuildContext context, {
    bool manualCheck = false,
  }) async {
    // If this is an automatic call and we've already checked, skip.
    if (!manualCheck && _hasCheckedThisSession) {
      return;
    }

    // Mark as checked for the session if this was an automatic invocation.
    if (!manualCheck) {
      _hasCheckedThisSession = true;
    }

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
      if (res.statusCode != 200) {
        if (kDebugMode) {
          debugPrint("GitHub API returned ${res.statusCode}: ${res.body}");
        }
        // On manual checks, inform user we could not reach GitHub
        if (manualCheck && context.mounted) {
          PanaraInfoDialog.show(
            context,
            title: "Update Check Failed",
            message:
                "Couldn't check for updates (GitHub returned ${res.statusCode}).",
            textColor: Colors.black54,
            buttonText: "OK",
            onTapDismiss: () => Navigator.of(context).pop(),
            panaraDialogType: PanaraDialogType.error,
          );
        }
        return;
      }

      final data = jsonDecode(res.body);
      if (data == null || data is! Map) {
        if (kDebugMode) {
          debugPrint("Unexpected GitHub API payload: ${res.body}");
        }
        return;
      }

      final tag = (data["tag_name"] as String?) ?? "";
      final assets = (data["assets"] as List?) ?? [];
      final releaseHtmlUrl =
          (data["html_url"] as String?) ??
          'https://github.com/$_repoOwner/$_repoName/releases/latest';

      if (tag.isEmpty) {
        if (kDebugMode) debugPrint("No tag_name in latest release payload.");
        if (manualCheck && context.mounted) {
          PanaraInfoDialog.show(
            context,
            title: "No Release Found",
            message: "Couldn't get the latest release information.",
            textColor: Colors.black54,
            buttonText: "OK",
            onTapDismiss: () => Navigator.of(context).pop(),
            panaraDialogType: PanaraDialogType.error,
          );
        }
        return;
      }

      final latestVersion = tag.replaceFirst("v", "").trim();

      // Compare versions semantically
      final cmp = _compareVersions(latestVersion, currentVersion);

      if (cmp == 0) {
        if (manualCheck && context.mounted) {
          // Show user message only if this was a manual check
          PanaraInfoDialog.show(
            context,
            title: "Up to Date",
            message: "You are on the latest version (v$currentVersion)",
            textColor: Colors.black54,
            buttonText: "OK",
            onTapDismiss: () => Navigator.of(context).pop(),
            panaraDialogType: PanaraDialogType.success,
          );
        }
        return;
      }

      if (cmp < 0) {
        // latestVersion < currentVersion  => user has a newer app build than GitHub's latest
        if (manualCheck && context.mounted) {
          PanaraInfoDialog.show(
            context,
            title: "You are ahead of releases",
            message:
                "Your installed version is v$currentVersion which is newer than the latest GitHub release (v$latestVersion). This can happen if the release was removed or you installed a pre-release build. No update is available.",
            textColor: Colors.black54,
            buttonText: "OK",
            onTapDismiss: () => Navigator.of(context).pop(),
            panaraDialogType: PanaraDialogType.normal,
          );
        } else {
          if (kDebugMode) {
            debugPrint(
              "Installed version (v$currentVersion) is newer than GitHub latest (v$latestVersion). Skipping update.",
            );
          }
        }
        return;
      }

      // cmp > 0 -> latest > current -> proceed to find APK asset
      final arch = await _getDeviceArch();

      // find apk asset that contains the arch string in its name
      dynamic apkAsset;
      try {
        apkAsset = assets.firstWhere(
          (a) => (a?["name"] as String? ?? "").contains(arch),
          orElse: () => null,
        );
      } catch (_) {
        apkAsset = null;
      }

      if (apkAsset == null) {
        if (kDebugMode) {
          debugPrint(
            "No APK asset found for ABI: $arch on release v$latestVersion",
          );
        }
        if (manualCheck && context.mounted) {
          PanaraInfoDialog.show(
            context,
            title: "Update Available (no installer)",
            message:
                "A new version v$latestVersion is available, but no installer matching your device ABI ($arch) was found for automatic download. Please check the release page on GitHub.",
            textColor: Colors.black54,
            buttonText: "Open Release Page",
            onTapDismiss: () {
              Navigator.of(context).pop();
              _openReleasePage(releaseHtmlUrl);
            },
            panaraDialogType: PanaraDialogType.normal,
          );
        }
        return;
      }

      final apkUrl = apkAsset["browser_download_url"] as String?;

      if (apkUrl == null || apkUrl.isEmpty) {
        if (kDebugMode) {
          debugPrint("APK asset has no download URL for v$latestVersion");
        }
        return;
      }

      if (!context.mounted) return;
      PanaraConfirmDialog.show(
        context,
        title: "Update Available",
        message:
            "A new version v$latestVersion is available (you are on v$currentVersion). Do you want to update?",
        textColor: Colors.black54,
        confirmButtonText: "Update",
        cancelButtonText: "Later",
        onTapCancel: () => Navigator.of(context).pop(),
        onTapConfirm: () {
          Navigator.of(context).pop();
          _downloadAndInstall(apkUrl, latestVersion, context);
        },
        panaraDialogType: PanaraDialogType.normal,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint("Update check failed: $e\n$st");
      }
      if (manualCheck && context.mounted) {
        PanaraInfoDialog.show(
          context,
          title: "Update Check Failed",
          message:
              "An error occurred while checking for updates. Check your Internet connection and try again.",
          textColor: Colors.black54,
          buttonText: "OK",
          onTapDismiss: () => Navigator.of(context).pop(),
          panaraDialogType: PanaraDialogType.error,
        );
      }
    }
  }

  /// Download APK and show progress dialog with cancel button.
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
                              LinearProgressIndicator(
                                value: progress,
                                color: Colors.blue,
                              ),
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
              final children = entity.listSync();
              if (children.isEmpty) {
                await entity.delete();
              }
            } catch (_) {}
          }
        } catch (_) {
          // ignore individual delete errors and continue
        }
      }

      return deletedCount;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('clearDownloadFolder failed: $e');
      }
      return 0;
    }
  }
}
