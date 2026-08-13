// Guards the fix for the App Store 2.1(a) rejection of 8.2.3 (196):
// "Several sections of the app did not change to English, even on selecting
// English language setting."
//
// The mechanism tests must always pass. The coverage test at the bottom is the
// completion metric for the migration: it fails while any string the UI renders
// would still come out Bengali with English selected.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oxius_native/l10n/bn_en_dictionary.dart';
import 'package:oxius_native/l10n/tr.dart';
import 'package:oxius_native/services/translation_service.dart';

/// Bengali letters. Excludes ৳ (U+09F3) and the Bengali digits, which are fine
/// to show an English speaker — a Taka sign is a Taka sign.
final _bnLetter = RegExp(r'[অ-ৎ]');

void main() {
  group('canonBn', () {
    test('folds the decomposed nukta spellings onto the precomposed ones', () {
      // These look identical on screen and compare unequal, which is how the
      // same visible word misses the dictionary.
      expect(canonBn('য়'), 'য়'); // য়
      expect(canonBn('ড়'), 'ড়'); // ড়
      expect(canonBn('ঢ়'), 'ঢ়'); // ঢ়
    });

    test('collapses whitespace runs and non-breaking spaces', () {
      expect(canonBn('  সেভ   করুন '), 'সেভ করুন');
      expect(canonBn('সেভ করুন'), 'সেভ করুন');
      expect(canonBn('সেভ\n      করুন'), 'সেভ করুন');
    });
  });

  group('tr', () {
    setUp(() => setTrLanguage('bn'));

    test('returns Bengali untouched in Bengali mode', () {
      setTrLanguage('bn');
      for (final bn in kBnEn.keys.take(50)) {
        expect(tr(bn), bn, reason: 'Bengali mode must not rewrite anything');
      }
    });

    test('returns English in English mode', () {
      setTrLanguage('en');
      final bn = kBnEn.keys.first;
      expect(tr(bn), kBnEn[bn]);
      expect(_bnLetter.hasMatch(tr(bn)), isFalse);
    });

    test('matches a literal that differs only by nukta spelling', () {
      setTrLanguage('en');
      // Take a dictionary key containing য় and decompose it, which is what a
      // widget literal typed in a different editor looks like.
      final key = kBnEn.keys.firstWhere((k) => k.contains('য়'),
          orElse: () => '');
      if (key.isEmpty) return; // no such entry yet
      final decomposed = key.replaceAll('য়', 'য়');
      expect(decomposed == key, isFalse, reason: 'probe must actually differ');
      expect(tr(decomposed), kBnEn[key]);
    });

    test('re-attaches trailing punctuation the dictionary does not carry', () {
      setTrLanguage('en');
      final key = kBnEn.keys
          .firstWhere((k) => !k.endsWith(':'), orElse: () => kBnEn.keys.first);
      expect(tr('$key:'), '${kBnEn[key]}:');
    });

    test('an unknown string comes back as Bengali, not blank and not a crash',
        () {
      setTrLanguage('en');
      const nonsense = 'এইটা অভিধানে নেই কখনও';
      expect(tr(nonsense), nonsense);
    });
  });

  group('trf', () {
    test('splices runtime values into the numbered slots', () {
      setTrLanguage('bn');
      expect(trf('{0} জন মেম্বার', [12]), '12 জন মেম্বার');
    });
  });

  group('TranslationService.translate — the actual rejection', () {
    final svc = TranslationService();

    test('English mode does NOT fall back to the Bengali at the call site', () {
      // Reproduces the bug exactly: a key with no entry in any table, whose
      // call-site fallback is Bengali. Before the fix this returned the
      // Bengali. 1,090 of the 1,381 keys the app asks for were in this state.
      final bn = kBnEn.keys.first;
      svc.debugSetLanguage('en');
      final out = svc.translate('a_key_no_table_has', fallback: bn);
      expect(out, kBnEn[bn]);
      expect(_bnLetter.hasMatch(out), isFalse,
          reason: 'English selected, Bengali rendered — this is the rejection');
    });

    test('Bengali mode still gets the Bengali fallback verbatim', () {
      final bn = kBnEn.keys.first;
      svc.debugSetLanguage('bn');
      expect(svc.translate('a_key_no_table_has', fallback: bn), bn);
    });

    test('a real server translation still wins over the dictionary', () {
      svc.debugSetLanguage('en', translations: {'k': 'From Server'});
      expect(svc.translate('k', fallback: 'বাংলা'), 'From Server');
    });

    test('selecting a language sets the mirror tr() reads, not just the field',
        () {
      // The cache path used to assign _currentLanguage without calling
      // setTrLanguage, so a language change served from cache left every bare
      // tr() call still returning Bengali while _t() calls switched. The two
      // must never disagree.
      svc.debugSetLanguage('en');
      expect(svc.currentLanguage, 'en');
      expect(trLanguage, 'en');
      expect(trIsBengali, isFalse);

      svc.debugSetLanguage('bn');
      expect(trLanguage, 'bn');
      expect(trIsBengali, isTrue);
    });
  });

  group('dictionary hygiene', () {
    test('no English value contains Bengali letters', () {
      final bad = <String>[];
      kBnEn.forEach((bn, en) {
        if (_bnLetter.hasMatch(en)) bad.add('$bn -> $en');
      });
      expect(bad, isEmpty,
          reason: 'these entries would still render Bengali in English mode');
    });

    test('no empty values, and keys are already canonical', () {
      kBnEn.forEach((bn, en) {
        expect(en.trim(), isNotEmpty, reason: 'empty English for "$bn"');
        expect(canonBn(bn), bn,
            reason: '"$bn" is not canonical, so a runtime lookup will miss it');
      });
    });
  });

  // ── the strict guard ─────────────────────────────────────────────────────
  //
  // Every string actually handed to tr() must have an entry. This needs no
  // source parsing beyond finding the call, so unlike the scan below it cannot
  // be fooled by nested quotes — and it is what fails if someone adds
  // `tr('নতুন কিছু')` without adding the English.
  group('tr() arguments', () {
    test('every Bengali string passed to tr() has a dictionary entry', () {
      final root = Directory('lib');
      if (!root.existsSync()) {
        markTestSkipped('run from the package root');
        return;
      }
      final call = RegExp(r"\btr\(\s*'((?:[^'\\]|\\.)*)'\s*\)");
      final fallback =
          RegExp(r"\b_?t(?:ranslate)?\(\s*'[\w.]+'\s*,\s*(?:fallback:\s*)?'((?:[^'\\]|\\.)*)'");
      final missing = <String, String>{};
      var checked = 0;

      for (final f in root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final rel = f.path.replaceAll(r'\', '/');
        if (rel.endsWith('l10n/bn_en_dictionary.dart')) continue;
        var lineNo = 0;
        for (final line in f.readAsLinesSync()) {
          lineNo++;
          if (line.trim().startsWith('//')) continue;
          for (final re in [call, fallback]) {
            for (final m in re.allMatches(line)) {
              final arg = (m.group(1) ?? '')
                  .replaceAll(r'\n', '\n')
                  .replaceAll(r'\t', '\t')
                  .replaceAll(r"\'", "'")
                  .replaceAll(r'\$', r'$');
              if (!_bnLetter.hasMatch(arg)) continue;
              checked++;
              if (!kBnEn.containsKey(canonBn(arg))) {
                missing[canonBn(arg)] = '$rel:$lineNo';
              }
            }
          }
        }
      }

      if (missing.isNotEmpty) {
        final sample =
            missing.entries.take(20).map((e) => '  ${e.value}  ${e.key}');
        fail('${missing.length} of $checked strings passed to tr() have no '
            'English. Add them to lib/l10n/bn_en_dictionary.dart:\n'
            '${sample.join('\n')}');
      }
    });
  });

  // ── the completion metric ────────────────────────────────────────────────
  //
  // Walks lib/ and finds Bengali that would still reach an English speaker.
  // Fails with the exact list while the migration is unfinished.
  group('coverage', () {
    test('every Bengali literal in lib/ resolves to English', () {
      final root = Directory('lib');
      if (!root.existsSync()) {
        markTestSkipped('run from the package root');
        return;
      }

      final lit = RegExp(r"'([^'\\\n]*(?:\\.[^'\\\n]*)*)'"
          r'|"([^"\\\n]*(?:\\.[^"\\\n]*)*)"');
      final missing = <String, String>{};
      var checked = 0;

      for (final f in root
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final rel = f.path.replaceAll(r'\', '/');
        // The dictionary and the fallback tables are data, not rendered text.
        if (rel.endsWith('l10n/bn_en_dictionary.dart') ||
            rel.endsWith('services/translation_service.dart')) {
          continue;
        }
        var lineNo = 0;
        var inBlock = false;
        for (final line in f.readAsLinesSync()) {
          lineNo++;
          final s = line.trim();
          if (inBlock) {
            if (s.contains('*/')) inBlock = false;
            continue;
          }
          if (s.startsWith('/*')) {
            if (!s.contains('*/')) inBlock = true;
            continue;
          }
          if (s.startsWith('//')) continue;

          for (final m in lit.allMatches(line)) {
            var v = m.group(1) ?? m.group(2) ?? '';
            if (v.isEmpty || !_bnLetter.hasMatch(v)) continue;

            // This is a regex over source, not a Dart parser, so it mis-pairs
            // quotes on a line that nests one inside `${...}` — which is
            // exactly the shape `'${tr('x')} $n ${tr('y')}'` produces. Such a
            // fragment starts mid-expression; it is not a literal the app ever
            // evaluates, so scoring it would report failures that do not exist.
            if (v.startsWith(')') ||
                v.startsWith(']') ||
                v.startsWith('}') ||
                v.contains(r'${')) {
              continue;
            }

            // Match what the app passes at runtime: Dart has already turned
            // `\n` into a newline by then, and canonBn folds it to a space.
            v = v
                .replaceAll(r'\n', '\n')
                .replaceAll(r'\t', '\t')
                .replaceAll(r"\'", "'")
                .replaceAll(r'\"', '"');

            checked++;
            setTrLanguage('en');
            final resolved = tr(v);
            if (_bnLetter.hasMatch(resolved)) {
              missing['$rel:$lineNo'] = v;
            }
          }
        }
      }

      if (missing.isNotEmpty) {
        final sample = missing.entries.take(25).map((e) => '  ${e.key}  ${e.value}');
        fail('${missing.length} of $checked Bengali literals in lib/ have no '
            'English and would render Bengali with English selected.\n'
            '${sample.join('\n')}\n'
            '${missing.length > 25 ? '  ...and ${missing.length - 25} more' : ''}');
      }
    });
  });
}
