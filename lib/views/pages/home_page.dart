import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:trackedify/database/database_helper.dart';
import 'package:trackedify/services/theme_controller.dart';
import 'package:trackedify/services/update_service.dart';
import 'package:trackedify/shared/widgets/curvedbox_widget.dart';
import 'package:trackedify/shared/widgets/overview_widget.dart';
import 'package:trackedify/shared/widgets/welcome_widget.dart';
import 'package:trackedify/views/pages/expense_history_page.dart';
import 'package:trackedify/views/widget_tree.dart';
import 'edit_expense_page.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> expenses = [];
  Map<String, Map<String, dynamic>> categoryMap = {}; // name -> {color, icon}

  // voice recognition
  stt.SpeechToText? _speech;
  bool _isListening = false;
  String _lastWords = '';
  bool _voiceAvailable = false;

  bool _voiceEnabled = true; // loaded from DB in _loadVoicePref()

  // guard to avoid concurrent preference reloads
  bool _prefLoadInProgress = false;

  // Map expenseId -> image count
  Map<int, int> _imageCountMap = {};

  final ctrl = ThemeController.instance;

  final overviewKey = GlobalKey<OverviewWidgetState>();

  void refresh() {
    loadCategories();
    loadExpenses();
    overviewKey.currentState?.refresh();
  }

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadExpenses();
    _loadVoicePref();
    _initSpeech(); // will check permission before initializing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  Future<void> _loadVoicePref() async {
    try {
      final v = await DatabaseHelper().isVoiceEnabled();
      if (!mounted) return;
      setState(() => _voiceEnabled = v);
    } catch (_) {}
  }

  /// Initialize speech-to-text only if mic permission is granted.
  Future<void> _initSpeech() async {
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        // Don't initialize if the mic permission is not granted.
        if (!mounted) return;
        setState(() {
          _voiceAvailable = false;
        });
        return;
      }

      _speech = stt.SpeechToText();
      final avail = await _speech!.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (err) {
          if (!mounted) return;
          setState(() {
            _isListening = false;
          });
        },
      );
      if (!mounted) return;
      setState(() {
        _voiceAvailable = avail;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _voiceAvailable = false;
      });
    }
  }

  Future<void> loadCategories() async {
    final dbCategories = await DatabaseHelper().getCategories();
    setState(() {
      categoryMap = {
        for (var cat in dbCategories)
          cat['name']: {
            'color': Color(cat['color']),
            'icon': IconData(cat['icon_code'], fontFamily: 'MaterialIcons'),
          },
      };
    });
  }

  Future<void> loadExpenses() async {
    final db = await DatabaseHelper().database;
    final data = await db.query(
      'expenses',
      orderBy: 'date DESC, id DESC',
      limit: 6,
    );
    setState(() {
      expenses = data;
    });

    await _loadImageCountsForExpenses(data);

    setState(() {});
  }

  /// Efficiently load counts from img_notes for all supplied expenses.
  Future<void> _loadImageCountsForExpenses(
    List<Map<String, dynamic>> data,
  ) async {
    final db = await DatabaseHelper().database;
    if (data.isEmpty) {
      setState(() => _imageCountMap = {});
      return;
    }

    final ids = data.map((e) => e['id'] as int).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      'SELECT expense_id, COUNT(*) as cnt FROM img_notes WHERE expense_id IN ($placeholders) GROUP BY expense_id',
      ids,
    );
    final Map<int, int> counts = {};
    for (var r in rows) {
      final eid = r['expense_id'] as int;
      final cnt = (r['cnt'] is int)
          ? r['cnt'] as int
          : int.parse(r['cnt'].toString());
      counts[eid] = cnt;
    }

    for (final id in ids) {
      counts[id] = counts[id] ?? 0;
    }

    setState(() {
      _imageCountMap = counts;
    });
  }

  Map<String, dynamic> getCategory(String name) {
    return categoryMap[name] ?? {'color': Colors.grey, 'icon': Icons.category};
  }

  String _formatAmount(dynamic amount) {
    if (amount is num) {
      return amount.toDouble().toStringAsFixed(2);
    }
    final parsed = double.tryParse(amount?.toString() ?? '');
    if (parsed != null) return parsed.toStringAsFixed(2);
    return amount?.toString() ?? '0.00';
  }

  /// Fetch image blobs for an expense id from img_notes.
  Future<List<Uint8List>> _fetchImagesForExpense(int expenseId) async {
    final db = await DatabaseHelper().database;
    final rows = await db.query(
      'img_notes',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
    );
    final List<Uint8List> images = [];
    for (final r in rows) {
      final img = r['image'];
      if (img is Uint8List) {
        images.add(img);
      } else if (img is List<int>) {
        images.add(Uint8List.fromList(img));
      } else if (img != null) {
        try {
          images.add(Uint8List.fromList(List<int>.from(img as Iterable<int>)));
        } catch (_) {}
      }
    }
    return images;
  }

  /// Request minimal permissions needed for saving. Returns true if we can proceed.
  Future<bool> _ensureSavePermission() async {
    try {
      if (Platform.isIOS) {
        final status = await Permission.photos.request();
        return status.isGranted;
      } else if (Platform.isAndroid) {
        final storage = await Permission.storage.request();
        if (storage.isGranted) return true;
        final photos = await Permission.photos.request();
        return photos.isGranted;
      }
    } catch (_) {}
    return false;
  }

  /// Save bytes to gallery using saver_gallery
  Future<void> _saveBytesToGallery(Uint8List bytes) async {
    final ok = await _ensureSavePermission();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Permission denied. Cannot save image.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final ts = DateTime.now().millisecondsSinceEpoch;
    final name = 'trackedify_$ts.jpg';
    try {
      await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName: name,
        skipIfExists: false,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.primary,
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Saved to gallery')),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save image: $e')));
    }
  }

  /// Show image viewer with Save option
  void _showImageViewer(Uint8List bytes) {
    final cs = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (context) {
        if (bytes.isEmpty) {
          return const Center(child: CupertinoActivityIndicator());
        } else {
          return Dialog(
            insetPadding: const EdgeInsets.all(12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 20),
                Flexible(
                  fit: FlexFit.tight,
                  child: InteractiveViewer(
                    child: Image.memory(bytes, fit: BoxFit.contain),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(
                            Icons.save_alt,
                            color: ctrl.effectiveColorForRole(
                              context,
                              'primary',
                            ),
                          ),
                          label: const Text('Save to gallery'),
                          onPressed: () {
                            Navigator.pop(context);
                            _saveBytesToGallery(bytes);
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: BorderSide(
                              color: ctrl.effectiveColorForRole(
                                context,
                                'primary',
                              ),
                            ),
                            foregroundColor: ctrl.effectiveColorForRole(
                              context,
                              'primary',
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ctrl.effectiveColorForRole(
                            context,
                            'primary',
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Close',
                          style: TextStyle(color: cs.onPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Future<void> _showNoteSheet(Map<String, dynamic> expense) async {
    final note = (expense['note'] ?? '').toString();
    final hasNote = note.trim().isNotEmpty;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final subtleBg = cs.surfaceContainerHighest;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // header row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Expense',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: cs.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // meta: category / amount / date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: getCategory(
                              expense['category'] ?? '',
                            )['color'],
                            child: Icon(
                              getCategory(expense['category'] ?? '')['icon'],
                              color: cs.onPrimary,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            expense['category'] ?? '',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "-\$${_formatAmount(expense['amount'])}",
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            expense['date'] ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: subtleBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasNote
                        ? Text(
                            note,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                          )
                        : Text(
                            'No note to show',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.8),
                            ),
                          ),
                  ),
                  const SizedBox(height: 18),
                  // images area
                  FutureBuilder<List<Uint8List>>(
                    future: _fetchImagesForExpense(expense['id'] as int),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Column(
                          children: [
                            SizedBox(
                              height: 20,
                              child: Center(
                                child: CupertinoActivityIndicator(),
                              ),
                            ),
                            SizedBox(height: 24),
                          ],
                        );
                      }
                      final imgs = snap.data!;
                      if (imgs.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Images',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 96,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: imgs.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final b = imgs[i];
                                return GestureDetector(
                                  onTap: () => _showImageViewer(b),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      b,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                      cacheWidth: 192,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      );
                    },
                  ),
                  // actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: cs.surface,
                            side: BorderSide(
                              color: ctrl.effectiveColorForRole(
                                context,
                                'primary',
                              ),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    EditExpensePage(expense: expense),
                              ),
                            ).then((_) {
                              // refresh after coming back from edit
                              loadCategories();
                              loadExpenses();
                              overviewKey.currentState?.refresh();
                              NavBarController.apply();
                            });
                          },
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              color: ctrl.effectiveColorForRole(
                                context,
                                'primary',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ctrl.effectiveColorForRole(
                              context,
                              'primary',
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: TextStyle(color: cs.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // -----------------------
  // Voice command handling
  // -----------------------

  Future<void> _onMicPressed() async {
    // ALWAYS re-check the DB preference right when user presses mic.
    final enabled = await DatabaseHelper().isVoiceEnabled();
    if (!mounted) return;
    setState(() => _voiceEnabled = enabled);

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (!_voiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.error,
          content: Row(
            children: [
              Icon(Icons.mic_off, color: cs.onError),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Voice commands are disabled in Settings'),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Check microphone permission before attempting to listen.
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      // Try to request permission interactively.
      final granted = await Permission.microphone.request();
      if (!granted.isGranted) {
        // Persist the user's denial to avoid repeated prompts across sessions.
        await DatabaseHelper().setVoiceEnabled(false);
        if (!mounted) return;
        setState(() => _voiceEnabled = false);

        final isPermanentlyDenied =
            await Permission.microphone.isPermanentlyDenied;
        if (isPermanentlyDenied) {
          if (!mounted) return;
          PanaraInfoDialog.show(
            context,
            title: 'Microphone blocked',
            message:
                'Microphone permission is blocked for this app. To use voice commands, open system settings and allow Microphone permission.',
            buttonText: 'Open settings',
            onTapDismiss: () {
              Navigator.pop(context);
              openAppSettings();
            },
            textColor: Theme.of(context).textTheme.bodySmall?.color,
            panaraDialogType: PanaraDialogType.warning,
          );
        } else {
          if (!mounted) return;
          PanaraInfoDialog.show(
            context,
            title: 'Permission denied',
            message:
                'Microphone permission denied. Voice commands have been disabled.',
            buttonText: 'OK',
            onTapDismiss: () => Navigator.pop(context),
            textColor: Theme.of(context).textTheme.bodySmall?.color,
            panaraDialogType: PanaraDialogType.normal,
          );
        }
        return;
      } else {
        // Permission granted: try to initialize speech (if not already)
        await _initSpeech();
      }
    }

    if (!_voiceAvailable || _speech == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs.error,
          content: Row(
            children: [
              Icon(Icons.mic_off, color: cs.onError),
              const SizedBox(width: 12),
              const Expanded(child: Text('Voice recognition not available')),
            ],
          ),
        ),
      );
      // attempt re-initialize if permission was granted
      await _initSpeech();
      return;
    }

    // If already listening - stop
    if (_isListening) {
      try {
        await _speech!.stop();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      return;
    }

    // start listening
    if (!mounted) return;
    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    try {
      await _speech!.listen(
        onResult: (result) {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _speech!.stop();
            if (!mounted) return;
            setState(() => _isListening = false);
            _handleVoiceCommand(_lastWords);
          }
        },
        listenFor: const Duration(seconds: 12),
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
        listenOptions: stt.SpeechListenOptions(
          cancelOnError: true,
          partialResults: true,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isListening = false);
      final cs2 = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: cs2.error,
          content: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: cs2.onError),
              const SizedBox(width: 12),
              Expanded(child: Text('Voice error: $e')),
            ],
          ),
        ),
      );
    }
  }

  // ---------- parsing & handling voice commands ----------
  Map<String, dynamic>? _parseVoiceCommand(String text) {
    if (text.trim().isEmpty) return null;
    final lowered = text.toLowerCase();

    // first try to find a numeric token exactly
    final tokens = lowered
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.isNotEmpty)
        .toList();
    int amountIndex = -1;
    String? amountToken;
    final numTokenRe = RegExp(r'^\$?\d+(?:[.,]\d+)?$');

    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i].replaceAll(
        RegExp(r'[^\w\.\$]'),
        '',
      ); // remove punctuation except dot and $
      if (numTokenRe.hasMatch(t)) {
        amountIndex = i;
        amountToken = t;
        break;
      }
    }

    if (amountIndex == -1 || amountToken == null) {
      // fallback: try to find number anywhere using regex on full text
      final m = RegExp(r'(\d+(?:[.,]\d+)?)').firstMatch(lowered);
      if (m == null) return null;
      amountToken = m.group(1);
      // find token containing that substring
      amountIndex = tokens.indexWhere((w) => w.contains(amountToken!));
      if (amountIndex == -1) return null;
    }

    // parse amount numeric value
    final rawAmount = amountToken!
        .replaceAll(RegExp(r'[^0-9\.,]'), '')
        .replaceAll(',', '.');
    final amount = double.tryParse(rawAmount);
    if (amount == null) return null;

    // gather candidate categories:
    final categoryNamesLower = categoryMap.keys
        .map((k) => k.toLowerCase())
        .toList();

    // try direct match: if any category name appears as a full word in text, prefer that
    for (final cat in categoryNamesLower) {
      final pattern = RegExp(r'\b' + RegExp.escape(cat) + r'\b');
      if (pattern.hasMatch(lowered)) {
        // find the actual key with original casing
        final real = categoryMap.keys.firstWhere((k) => k.toLowerCase() == cat);
        return {'amount': amount, 'category': real};
      }
    }

    // stopwords that should be ignored when guessing category
    final stopwords = {
      'add',
      'write',
      'expense',
      'expenses',
      'dollar',
      'dollars',
      'cent',
      'cents',
      'usd',
      'taka',
      'paid',
      'spent',
      'for',
      'of',
      'the',
      'a',
      'an',
      'to',
      'by',
      'on',
      'just',
      'only',
      'have',
      'had',
    };

    String? matchedCandidate;

    // check left then right for nearest meaningful token
    for (int offset = 1; offset <= tokens.length; offset++) {
      final leftIdx = amountIndex - offset;
      final rightIdx = amountIndex + offset;

      bool found = false;

      if (leftIdx >= 0) {
        final cand = tokens[leftIdx].replaceAll(RegExp(r'[^\w]'), '');
        final candClean = cand.replaceAll(RegExp(r'\$'), '').trim();
        if (candClean.isNotEmpty && !stopwords.contains(candClean)) {
          matchedCandidate = _normalizeCandidate(candClean);
          if (matchedCandidate != null) found = true;
        }
      }
      if (!found && rightIdx < tokens.length) {
        final cand = tokens[rightIdx].replaceAll(RegExp(r'[^\w]'), '');
        final candClean = cand.replaceAll(RegExp(r'\$'), '').trim();
        if (candClean.isNotEmpty && !stopwords.contains(candClean)) {
          matchedCandidate = _normalizeCandidate(candClean);
          if (matchedCandidate != null) found = true;
        }
      }
      if (found) break;
    }

    // if still not found, fallback to simple previous word
    if (matchedCandidate == null && amountIndex - 1 >= 0) {
      matchedCandidate = _normalizeCandidate(tokens[amountIndex - 1]);
    }

    // final mapping to known category or fallback 'Other'
    String category = 'Other';
    if (matchedCandidate != null && matchedCandidate.isNotEmpty) {
      final matchedReal = categoryMap.keys.firstWhere(
        (k) => k.toLowerCase() == matchedCandidate,
        orElse: () => matchedCandidate!,
      );
      category = matchedReal[0].toUpperCase() + matchedReal.substring(1);
    }

    return {'amount': amount, 'category': category};
  }

  String? _normalizeCandidate(String s) {
    if (s.isEmpty) return null;
    var cleaned = s.toLowerCase();
    // remove currency words and common filler words
    cleaned = cleaned.replaceAll(RegExp(r'^\$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'dollars?$'), '');
    cleaned = cleaned.replaceAll(
      RegExp(r'\b(expense|expenses|add|paid|spent|for|of|the|a|an|usd)\b'),
      '',
    );
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    cleaned = cleaned.trim();
    if (cleaned.isEmpty) return null;
    if (cleaned.length > 40) return null;
    return cleaned;
  }

  Future<void> _handleVoiceCommand(String text) async {
    final parsed = _parseVoiceCommand(text);
    if (parsed == null) {
      if (!mounted) return;
      PanaraInfoDialog.show(
        context,
        title: 'Could not parse',
        message:
            'Sorry, could not parse the expense command. Try something like "Add shopping 20" or "Food 20".',
        buttonText: "Okay",
        onTapDismiss: () {
          Navigator.of(context).pop();
        },
        textColor: Theme.of(context).textTheme.bodySmall?.color,
        panaraDialogType: PanaraDialogType.error,
      );
      return;
    }

    // show confirmation dialog
    if (!mounted) return;
    final amountCtl = TextEditingController(text: parsed['amount'].toString());
    final categoryCtl = TextEditingController(text: parsed['category']);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Expense'),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.all(Radius.circular(10)),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                decoration: const InputDecoration(labelText: 'Amount'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: categoryCtl,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirmed != true) return;

    // validate & insert
    final amountVal = double.tryParse(amountCtl.text.replaceAll(',', '.'));
    if (amountVal == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Theme.of(context).colorScheme.onError,
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text('Invalid amount')),
            ],
          ),
        ),
      );
      return;
    }
    final categoryVal = categoryCtl.text.trim().isEmpty
        ? 'Other'
        : categoryCtl.text.trim();
    final dateStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    await DatabaseHelper().insertExpense(
      category: categoryVal,
      amount: amountVal,
      date: dateStr,
      note: null,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        content: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Added: \$${amountVal.toStringAsFixed(2)} - $categoryVal',
              ),
            ),
          ],
        ),
      ),
    );

    // reload
    await loadCategories();
    await loadExpenses();
  }

  @override
  void dispose() {
    try {
      _speech?.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRefreshVoicePref();
    });

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textColorMuted =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75) ??
        Colors.grey;

    return Scaffold(
      backgroundColor: cs.surface,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              const CurvedboxWidget(),
              OverviewWidget(key: overviewKey),
              const WelcomeWidget(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Recent Expenses',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ExpenseHistoryPage(),
                          ),
                        ).then((_) {
                          loadCategories();
                          loadExpenses();
                          overviewKey.currentState?.refresh();
                          NavBarController.apply();
                        });
                      },
                      child: Text(
                        'Show all',
                        style: TextStyle(
                          fontSize: 14,
                          color: textColorMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: _voiceEnabled
                          ? 'Add by voice'
                          : 'Voice commands disabled',
                      icon: Icon(
                        _voiceEnabled
                            ? FontAwesomeIcons.microphone
                            : FontAwesomeIcons.microphoneSlash,
                        color: !_voiceEnabled
                            ? theme.disabledColor
                            : (_isListening ? cs.error : textColorMuted),
                      ),
                      onPressed: _onMicPressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
          expenses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 70),
                      Icon(
                        Icons.receipt_long,
                        size: 64,
                        color: cs.onSurface.withValues(alpha: 0.12),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No expenses to show',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textColorMuted,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 18),
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    final cat = getCategory(expense['category']);
                    final hasNote = (expense['note'] ?? '')
                        .toString()
                        .trim()
                        .isNotEmpty;
                    final imageCount = _imageCountMap[expense['id']] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showNoteSheet(expense),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: cat['color'],
                                      child: Icon(
                                        cat['icon'],
                                        color: cs.onPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      expense['category'],
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),

                                    if (hasNote) ...[
                                      const SizedBox(width: 5),
                                      Icon(
                                        FontAwesomeIcons.solidNoteSticky,
                                        size: 16,
                                        color: textColorMuted,
                                      ),
                                    ],
                                    if (imageCount > 0) ...[
                                      const SizedBox(width: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            FontAwesomeIcons.solidImage,
                                            size: 16,
                                            color: textColorMuted,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            '$imageCount',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                                  color: textColorMuted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      "-\$${_formatAmount(expense['amount'])}",
                                      style: theme.textTheme.bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    Text(
                                      expense['date'],
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: textColorMuted,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Future<void> _maybeRefreshVoicePref() async {
    if (_prefLoadInProgress) return;
    _prefLoadInProgress = true;
    try {
      await _loadVoicePref();
    } finally {
      _prefLoadInProgress = false;
    }
  }
}
