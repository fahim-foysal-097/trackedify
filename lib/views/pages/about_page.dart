import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appName = 'Trackedify';
  String _version = '';
  String _buildNumber = '';
  String _platformInfo = '';
  final String _releasePageUrl =
      'https://fahim-foysal-097.github.io/trackedify-website/releases.html';

  bool _loadingRelease = false;
  String? _latestTitle;
  String? _latestDate;
  List<_ReleaseSection> _latestSections = [];
  List<_ReleaseTag> _latestTags = [];
  String? _releaseFetchError;

  @override
  void initState() {
    super.initState();
    _initBasicInfo();
    _fetchLatestRelease();
  }

  Future<void> _initBasicInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final pi = info.packageName;
      final name = info.appName;
      final ver = info.version;
      final build = info.buildNumber;

      String platform = Platform.operatingSystem;
      String platformDetails = '';
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isAndroid) {
          final a = await deviceInfo.androidInfo;
          platformDetails =
              '${a.manufacturer} ${a.model} • Android ${a.version.release}';
        } else if (Platform.isIOS) {
          final i = await deviceInfo.iosInfo;
          platformDetails =
              '${i.name} ${i.utsname.machine} • iOS ${i.systemVersion}';
        } else {
          platformDetails = platform;
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Device info failed: $e');
      }

      if (!mounted) return;
      setState(() {
        _appName = name.isNotEmpty ? name : pi;
        _version = ver;
        _buildNumber = build;
        _platformInfo = platformDetails.isNotEmpty ? platformDetails : platform;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('PackageInfo failed: $e');
    }
  }

  /// Launch external URL
  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (kDebugMode) debugPrint('Could not launch $url');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('launch url error: $e');
    }
  }

  /// Fetch the releases page HTML and extract the first "release card".
  /// The parser is defensive: if structure changes it will store a user friendly error.
  Future<void> _fetchLatestRelease() async {
    setState(() {
      _loadingRelease = true;
      _releaseFetchError = null;
      _latestTitle = null;
      _latestDate = null;
      _latestSections = [];
      _latestTags = [];
    });

    try {
      final res = await http.get(Uri.parse(_releasePageUrl));
      if (res.statusCode != 200) {
        throw Exception('HTTP ${res.statusCode}');
      }
      final body = res.body;

      // Find first card block by looking for the card start token.
      const token = '<div class="card mb-4 shadow release-card">';
      final start = body.indexOf(token);
      if (start == -1) {
        throw Exception('Unexpected page structure (no release cards found).');
      }
      // find next card occurrence to slice a single card; if none, use rest of body
      final nextStart = body.indexOf(token, start + token.length);
      final firstCardHtml = (nextStart == -1)
          ? body.substring(start)
          : body.substring(start, nextStart);

      // Extract the <h3> ... </h3> block (title + date)
      final h3Match = RegExp(
        r'<h3[^>]*>([\s\S]*?)</h3>',
        caseSensitive: false,
      ).firstMatch(firstCardHtml);
      if (h3Match != null) {
        final h3Html = h3Match.group(1) ?? '';
        final h3Text = _stripHtml(h3Html).trim();
        // Try to extract date token like "Sep 28, 2025"
        final dateMatch = RegExp(
          r'-\s*([A-Za-z]{3,}\s+\d{1,2},\s*\d{4})',
        ).firstMatch(h3Text);
        String date = dateMatch?.group(1)?.trim() ?? '';
        // Extract first token that looks like vX.Y.Z
        final verMatch = RegExp(r'v?(\d+\.\d+(?:\.\d+)?)').firstMatch(h3Text);
        String ver = verMatch != null
            ? 'v${verMatch.group(1)}'
            : (h3Text.split('-').first.trim());

        _latestTitle = ver;
        _latestDate = date.isNotEmpty ? date : null;
      }

      // Parse release-tags block (preserve badges)
      final tagsMatch = RegExp(
        r'<span[^>]*class="[^"]*release-tags[^"]*"[^>]*>([\s\S]*?)</span>',
        caseSensitive: false,
      ).firstMatch(firstCardHtml);

      final List<_ReleaseTag> parsedTags = [];
      if (tagsMatch != null) {
        final tagsInner = tagsMatch.group(1) ?? '';
        // find inner spans (tag-badge)
        final spanReg = RegExp(
          r'<span[^>]*class="([^"]*)"[^>]*>([\s\S]*?)</span>',
          caseSensitive: false,
        );
        for (final m in spanReg.allMatches(tagsInner)) {
          final classAttr = m.group(1) ?? '';
          final innerHtml = m.group(2) ?? '';
          final label = _stripHtml(innerHtml).trim();
          if (label.isEmpty) continue;

          final lc = classAttr.toLowerCase();
          Color bg = const Color(0xFF4F46E5);
          Color text = Colors.white;

          if (lc.contains('bg-primary')) {
            bg = const Color(0xFF0D6EFD);
          } else if (lc.contains('bg-success')) {
            bg = Colors.green;
          } else if (lc.contains('bg-warning')) {
            bg = Colors.amber;
          } else if (lc.contains('bg-danger')) {
            bg = Colors.red;
          } else if (lc.contains('bg-info')) {
            bg = Colors.cyan;
          } else if (lc.contains('bg-secondary')) {
            bg = Colors.grey;
          } else if (lc.contains('bg-light')) {
            bg = Colors.grey.shade200;
          }

          if (lc.contains('text-dark') || lc.contains('text-muted')) {
            text = Colors.black87;
          } else if (lc.contains('text-white')) {
            text = Colors.white;
          } else {
            // decide contrast automatically for light backgrounds
            final brightness = ThemeData.estimateBrightnessForColor(bg);
            text = brightness == Brightness.dark
                ? Colors.white
                : Colors.black87;
          }

          parsedTags.add(
            _ReleaseTag(label: label, background: bg, foreground: text),
          );
        }
      }
      // fallback: sometimes release-tags exist outside h3 - try to find any tag-badge spans in card
      if (parsedTags.isEmpty) {
        final badgeReg = RegExp(
          r'<span[^>]*class="[^"]*tag-badge[^"]*"[^>]*>([\s\S]*?)</span>',
          caseSensitive: false,
        );
        for (final m in badgeReg.allMatches(firstCardHtml)) {
          final label = _stripHtml(m.group(1) ?? '').trim();
          if (label.isEmpty) continue;
          parsedTags.add(
            _ReleaseTag(
              label: label,
              background: const Color(0xFF4F46E5),
              foreground: Colors.white,
            ),
          );
        }
      }

      // Find all sections: <h5>Heading</h5> followed by <ul>...</ul>
      final sectionReg = RegExp(
        r'<h5[^>]*>([\s\S]*?)</h5>\s*<ul[^>]*>([\s\S]*?)</ul>',
        caseSensitive: false,
      );
      final sections = <_ReleaseSection>[];
      for (final m in sectionReg.allMatches(firstCardHtml)) {
        final headingHtml = m.group(1) ?? '';
        final ulHtml = m.group(2) ?? '';
        final heading = _stripHtml(headingHtml).trim();

        // extract li items
        final items = <String>[];
        final liReg = RegExp(r'<li[^>]*>([\s\S]*?)</li>', caseSensitive: false);
        for (final li in liReg.allMatches(ulHtml)) {
          final item = _stripHtml(li.group(1) ?? '').trim();
          if (item.isNotEmpty) items.add(item);
        }

        if (heading.isNotEmpty || items.isNotEmpty) {
          sections.add(_ReleaseSection(title: heading, bullets: items));
        }
      }

      // Fallback: if no sections parsed, try to extract plain text for the card
      if (sections.isEmpty) {
        final plain = _stripHtml(firstCardHtml).trim();
        if (plain.isNotEmpty) {
          sections.add(_ReleaseSection(title: 'Notes', bullets: [plain]));
        }
      }

      if (!mounted) return;
      setState(() {
        _latestSections = sections;
        _latestTags = parsedTags;
      });
    } catch (e) {
      if (kDebugMode) debugPrint('fetch release failed: $e');
      if (!mounted) return;
      setState(() {
        _releaseFetchError =
            'Could not fetch latest release notes. Check your internet connection.';
      });
    } finally {
      setState(() => _loadingRelease = false);
    }
  }

  /// Remove HTML tags and collapse whitespace
  String _stripHtml(String html) {
    var s = html.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), ' ');
    s = s.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), ' ');
    s = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: "Back",
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        color: Colors.blueAccent,
        onRefresh: _fetchLatestRelease,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _appName,
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {},
                          icon: const FaIcon(
                            FontAwesomeIcons.codeBranch,
                            size: 14,
                          ),
                          label: Text(
                            _version.isNotEmpty ? _version : "?",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (_buildNumber.isNotEmpty)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.white70),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {},
                            icon: const FaIcon(
                              FontAwesomeIcons.hashtag,
                              size: 14,
                            ),
                            label: Text(
                              'build $_buildNumber',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.devices_outlined,
                          size: 18,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _platformInfo.isNotEmpty
                                ? _platformInfo
                                : 'Platform info unavailable',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () => _launchURL(
                            'https://github.com/fahim-foysal-097/Trackedify',
                          ),
                          icon: const Icon(Icons.code),
                          label: const Text('Source (GitHub)'),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          onPressed: () => _launchURL(_releasePageUrl),
                          icon: const Icon(Icons.description_outlined),
                          label: const Text('Open Release Page'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Latest release card area with new gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header row
                    Row(
                      children: [
                        const Icon(
                          Icons.new_releases_outlined,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Latest release',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                        const Spacer(),
                        if (_loadingRelease)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CupertinoActivityIndicator(
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_releaseFetchError != null) ...[
                      Text(
                        _releaseFetchError!,
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: _fetchLatestRelease,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        label: const Text(
                          'Retry',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ] else if (_latestTitle == null && !_loadingRelease) ...[
                      const Text(
                        'No release information available.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ] else ...[
                      if (_latestTitle != null)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _latestTitle!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                if (_latestDate != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      _latestDate!,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            IconButton(
                              onPressed: () => _launchURL(_releasePageUrl),
                              icon: const Icon(
                                Icons.open_in_new_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      const SizedBox(height: 12),

                      // release-tags badges
                      if (_latestTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _latestTags.map((t) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.12,
                                      ),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  t.label,
                                  style: TextStyle(
                                    color: t.foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                      // Sections as ExpansionTiles styled for dark gradient
                      ..._latestSections.map((sec) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.white24,
                            unselectedWidgetColor: Colors.white70,
                            splashColor: Colors.white12,
                            highlightColor: Colors.white12,
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            collapsedIconColor: Colors.white70,
                            iconColor: Colors.white,
                            title: Text(
                              sec.title.isNotEmpty ? sec.title : 'Details',
                              style: const TextStyle(color: Colors.white),
                            ),
                            children: sec.bullets.isNotEmpty
                                ? sec.bullets.map((b) {
                                    return ListTile(
                                      dense: true,
                                      contentPadding: const EdgeInsets.only(
                                        left: 12,
                                        right: 12,
                                      ),
                                      leading: const Icon(
                                        Icons.circle,
                                        size: 8,
                                        color: Colors.white70,
                                      ),
                                      title: Text(
                                        b,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    );
                                  }).toList()
                                : [
                                    const ListTile(
                                      dense: true,
                                      title: Text('No details available.'),
                                    ),
                                  ],
                          ),
                        );
                      }),

                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _launchURL(_releasePageUrl),
                          child: const Text(
                            'View full release notes',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Credits section with new gradient
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.20),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'Credits',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const ListTile(
                      leading: Icon(Icons.person, color: Colors.white70),
                      title: Text(
                        'Creator: Fahim Foysal',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(
                        FontAwesomeIcons.squareGithub,
                        color: Colors.white70,
                      ),
                      title: const Text(
                        'GitHub',
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.open_in_new,
                        color: Colors.white70,
                      ),
                      onTap: () =>
                          _launchURL('https://github.com/fahim-foysal-097'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Small footer
              Center(
                child: Text(
                  'Trackedify - Built with care',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReleaseSection {
  final String title;
  final List<String> bullets;
  _ReleaseSection({required this.title, required this.bullets});
}

class _ReleaseTag {
  final String label;
  final Color background;
  final Color foreground;
  _ReleaseTag({
    required this.label,
    required this.background,
    required this.foreground,
  });
}
