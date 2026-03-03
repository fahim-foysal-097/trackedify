import 'dart:io';
import 'dart:math' as math;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage>
    with SingleTickerProviderStateMixin {
  String _appName = 'Trackedify';
  String _version = '';
  String _buildNumber = '';
  String _platformInfo = '';
  final String _releasePageUrl =
      'https://fahim-foysal-097.github.io/trackedify-web/releases.html';

  bool _loadingRelease = false;
  String? _latestTitle;
  String? _latestDate;
  List<_ReleaseSection> _latestSections = [];
  List<_ReleaseTag> _latestTags = [];
  String? _releaseFetchError;

  late AnimationController _blobController;
  late List<Animation<double>> _blobAnimations;

  @override
  void initState() {
    super.initState();
    _initBasicInfo();
    _fetchLatestRelease();

    _blobController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _blobAnimations = List.generate(
      6,
      (index) => Tween<double>(begin: 0, end: 2 * math.pi).animate(
        CurvedAnimation(
          parent: _blobController,
          curve: Interval(index * 0.15, 1.0, curve: Curves.easeInOut),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBlob({
    required Color color,
    required double size,
    required Offset position,
    required Animation<double> animation,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final offsetX = math.sin(animation.value) * 30;
        final offsetY = math.cos(animation.value) * 30;
        return Positioned(
          left: position.dx + offsetX,
          top: position.dy + offsetY,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.6),
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        );
      },
    );
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

      const token = '<div class="card mb-4 shadow release-card">';
      final start = body.indexOf(token);
      if (start == -1) {
        throw Exception('Unexpected page structure (no release cards found).');
      }
      final nextStart = body.indexOf(token, start + token.length);
      final firstCardHtml = (nextStart == -1)
          ? body.substring(start)
          : body.substring(start, nextStart);

      final h3Match = RegExp(
        r'<h3[^>]*>([\s\S]*?)</h3>',
        caseSensitive: false,
      ).firstMatch(firstCardHtml);
      if (h3Match != null) {
        final h3Html = h3Match.group(1) ?? '';
        final h3Text = _stripHtml(h3Html).trim();
        final dateMatch = RegExp(
          r'-\s*([A-Za-z]{3,}\s+\d{1,2},\s*\d{4})',
        ).firstMatch(h3Text);
        String date = dateMatch?.group(1)?.trim() ?? '';
        final verMatch = RegExp(r'v?(\d+\.\d+(?:\.\d+)?)').firstMatch(h3Text);
        String ver = verMatch != null
            ? 'v${verMatch.group(1)}'
            : (h3Text.split('-').first.trim());

        _latestTitle = ver;
        _latestDate = date.isNotEmpty ? date : null;
      }

      final tagsMatch = RegExp(
        r'<span[^>]*class="[^"]*release-tags[^"]*"[^>]*>([\s\S]*?)</span>',
        caseSensitive: false,
      ).firstMatch(firstCardHtml);

      final List<_ReleaseTag> parsedTags = [];
      if (tagsMatch != null) {
        final tagsInner = tagsMatch.group(1) ?? '';
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
          Color bg = const Color(0xFF6366F1);
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
              background: const Color(0xFF6366F1),
              foreground: Colors.white,
            ),
          );
        }
      }

      final sectionReg = RegExp(
        r'<h5[^>]*>([\s\S]*?)</h5>\s*<ul[^>]*>([\s\S]*?)</ul>',
        caseSensitive: false,
      );
      final sections = <_ReleaseSection>[];
      for (final m in sectionReg.allMatches(firstCardHtml)) {
        final headingHtml = m.group(1) ?? '';
        final ulHtml = m.group(2) ?? '';
        final heading = _stripHtml(headingHtml).trim();

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

  String _stripHtml(String html) {
    var s = html.replaceAll(RegExp(r'<script[^>]*>[\s\S]*?</script>'), ' ');
    s = s.replaceAll(RegExp(r'<style[^>]*>[\s\S]*?</style>'), ' ');
    s = s.replaceAll(RegExp(r'<[^>]*>'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Animated blobs background
          ...List.generate(6, (index) {
            final colors = [
              const Color(0xFF6366F1),
              const Color(0xFF8B5CF6),
              const Color(0xFFEC4899),
              const Color(0xFFF59E0B),
              const Color(0xFF10B981),
              const Color(0xFF3B82F6),
            ];
            final sizes = [120.0, 150.0, 100.0, 180.0, 130.0, 160.0];
            final positions = [
              const Offset(50, 100),
              const Offset(250, 200),
              const Offset(100, 400),
              const Offset(300, 500),
              const Offset(50, 600),
              const Offset(280, 300),
            ];
            return _buildAnimatedBlob(
              color: colors[index % colors.length],
              size: sizes[index % sizes.length],
              position: positions[index % positions.length],
              animation: _blobAnimations[index],
            );
          }),
          RefreshIndicator(
            onRefresh: _fetchLatestRelease,
            color: const Color(0xFF6366F1),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Hero card with app info
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF6366F1),
                          Color(0xFF8B5CF6),
                          Color(0xFFEC4899),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _appName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Expense Tracker',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildInfoChip(
                              icon: FontAwesomeIcons.codeBranch,
                              label: _version.isNotEmpty ? _version : "?",
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            if (_buildNumber.isNotEmpty)
                              _buildInfoChip(
                                icon: FontAwesomeIcons.hashtag,
                                label: 'Build $_buildNumber',
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.devices,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _platformInfo.isNotEmpty
                                      ? _platformInfo
                                      : 'Platform info unavailable',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildActionButton(
                              icon: FontAwesomeIcons.squareGithub,
                              label: 'GitHub',
                              onPressed: () => _launchURL(
                                'https://github.com/fahim-foysal-097/trackedify',
                              ),
                            ),
                            _buildActionButton(
                              icon: Icons.description_outlined,
                              label: 'Releases',
                              onPressed: () => _launchURL(_releasePageUrl),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Latest release card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF4F46E5,
                          ).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.new_releases,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Latest Release',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (_loadingRelease)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CupertinoActivityIndicator(
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_releaseFetchError != null) ...[
                          Text(
                            _releaseFetchError!,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _fetchLatestRelease,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF4F46E5),
                            ),
                          ),
                        ] else if (_latestTitle == null &&
                            !_loadingRelease) ...[
                          const Text(
                            'No release information available.',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ] else ...[
                          if (_latestTitle != null)
                            Row(
                              children: [
                                Text(
                                  _latestTitle!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_latestDate != null) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    _latestDate!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _launchURL(_releasePageUrl),
                                  icon: const Icon(
                                    Icons.open_in_new,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 12),
                          if (_latestTags.isNotEmpty)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _latestTags.map((t) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: t.background,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    t.label,
                                    style: TextStyle(
                                      color: t.foreground,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          if (_latestTags.isNotEmpty)
                            const SizedBox(height: 12),
                          ..._latestSections.take(2).map((sec) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sec.title.isNotEmpty
                                        ? sec.title
                                        : 'Details',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  ...sec.bullets.take(3).map((b) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 8,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.circle,
                                            size: 6,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              b,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => _launchURL(_releasePageUrl),
                            child: const Text(
                              'View full release notes →',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Credits card
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: 0.25),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Credits',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildCreditItem(
                          icon: Icons.person,
                          title: 'Creator',
                          subtitle: 'Fahim Foysal',
                        ),
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () =>
                              _launchURL('https://github.com/fahim-foysal-097'),
                          borderRadius: BorderRadius.circular(12),
                          child: _buildCreditItem(
                            icon: FontAwesomeIcons.squareGithub,
                            title: 'GitHub Profile',
                            subtitle: '@fahim-foysal-097',
                            trailing: const Icon(
                              Icons.open_in_new,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      'Built with ❤️ using Flutter',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white70),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCreditItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
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
