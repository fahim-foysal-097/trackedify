import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:panara_dialogs/panara_dialogs.dart';
import 'package:spendle/database/database_helper.dart';
import 'package:spendle/services/update_service.dart';
import 'package:spendle/shared/constants/text_constant.dart';
import 'package:spendle/shared/widgets/curvedbox_widget.dart';
import 'package:spendle/shared/widgets/overview_widget.dart';
import 'package:spendle/shared/widgets/welcome_widget.dart';
import 'package:spendle/views/pages/expense_history_page.dart';
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

  void refresh() {
    loadCategories();
    loadExpenses();
  }

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadExpenses();
    _initSpeech();
    _loadVoicePref();

    // Automatic update check after first frame (will run only once per app session)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UpdateService.checkForUpdate(context);
    });
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      final avail = await _speech!.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'done' ||
              status == 'notListening' ||
              status == 'notListening') {
            if (_isListening) {
              setState(() {
                _isListening = false;
              });
            }
          }
        },
        onError: (err) {},
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

  Future<void> _loadVoicePref() async {
    try {
      final v = await DatabaseHelper().isVoiceEnabled();
      if (!mounted) return;
      setState(() => _voiceEnabled = v);
    } catch (_) {}
  }

  // Called via post-frame to refresh preference when returning to this page.
  Future<void> _maybeRefreshVoicePref() async {
    if (_prefLoadInProgress) return;
    _prefLoadInProgress = true;
    try {
      await _loadVoicePref();
    } finally {
      _prefLoadInProgress = false;
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

  Future<void> _showNoteSheet(Map<String, dynamic> expense) async {
    final note = (expense['note'] ?? '').toString();
    final hasNote = note.trim().isNotEmpty;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
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
                      const Text(
                        'Expense',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
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
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            expense['category'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            expense['date'] ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // note content / placeholder
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: hasNote
                        ? Text(
                            note,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                          )
                        : const Text(
                            'No note to show',
                            style: TextStyle(fontSize: 15, color: Colors.grey),
                          ),
                  ),
                  const SizedBox(height: 18),
                  // actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.blue),
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
                            });
                          },
                          child: const Text(
                            'Edit',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Close',
                            style: TextStyle(color: Colors.white),
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
    // This ensures toggling in Settings takes effect immediately.
    final enabled = await DatabaseHelper().isVoiceEnabled();
    if (!mounted) return;
    // update local cache so UI reflects the latest value
    setState(() => _voiceEnabled = enabled);

    if (!_voiceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice commands are disabled in Settings'),
        ),
      );
      return;
    }

    if (!_voiceAvailable || _speech == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice recognition not available')),
      );
      // try re-initializing in case permission was granted meanwhile
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
        onResult: (result) async {
          if (!mounted) return;
          setState(() {
            _lastWords = result.recognizedWords;
          });
          if (result.finalResult) {
            // stop listening and perform action
            try {
              await _speech!.stop();
            } catch (_) {}
            if (!mounted) return;
            setState(() => _isListening = false);
            await _handleVoiceCommand(_lastWords);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Voice error: $e')));
    }
  }

  /// Try parse command; returns a parsed map or null
  ///
  /// How it works:
  ///  - tokenize text
  ///  - find the token which exactly matches a numeric pattern (e.g. "20" or "$20" or "20.5")
  ///  - look for category token nearest to that numeric token (left then right), ignoring stopwords
  ///  - also attempt to match any full category names present in the text
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

    // stopwords we should ignore when guessing category
    final stopwords = {
      'add',
      'expense',
      'expenses',
      'dollar',
      'dollars',
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
          if (matchedCandidate != null) {
            found = true;
          }
        }
      }

      if (!found && rightIdx < tokens.length) {
        final cand = tokens[rightIdx].replaceAll(RegExp(r'[^\w]'), '');
        final candClean = cand.replaceAll(RegExp(r'\$'), '').trim();
        if (candClean.isNotEmpty && !stopwords.contains(candClean)) {
          matchedCandidate = _normalizeCandidate(candClean);
          if (matchedCandidate != null) {
            found = true;
          }
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
            'Sorry, could not parse the expense command. Try something like "Add shopping 20" or "Food 20". ',
        buttonText: "Okay",
        onTapDismiss: () {
          Navigator.of(context).pop();
        },
        textColor: Colors.grey.shade700,
        panaraDialogType: PanaraDialogType.error,
      );
      return;
    }

    // show confirmation dialog with only amount + category
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

    // validate & insert (no note)
    final amountVal = double.tryParse(amountCtl.text.replaceAll(',', '.'));
    if (amountVal == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid amount')));
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
        content: Text(
          'Added: \$${amountVal.toStringAsFixed(2)} - $categoryVal',
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
    // updates immediately after returning from Settings.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeRefreshVoicePref();
    });

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              const CurvedboxWidget(),
              OverviewWidget(),
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
                  'Expense History',
                  style: KTextstyle.headerBlackText,
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
                        });
                      },
                      child: const Text(
                        'Show all',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
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
                            ? Colors.grey
                            : (_isListening ? Colors.red : Colors.black54),
                      ),
                      onPressed: _onMicPressed,
                    ),
                  ],
                ),
              ],
            ),
          ),
          ListView.builder(
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

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 5, 16, 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showNoteSheet(expense),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
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
                                child: Icon(cat['icon'], color: Colors.white),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                expense['category'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (hasNote) ...[
                                const SizedBox(width: 5),
                                const Icon(
                                  FontAwesomeIcons.solidNoteSticky,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ],
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "-\$${_formatAmount(expense['amount'])}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                expense['date'],
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
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
}
