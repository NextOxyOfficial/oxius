/// Bengali → English at the point of use.
///
/// WHY THIS EXISTS
///
/// This app was written Bengali-first, with the Bengali text sitting directly
/// in the widget tree. Two habits grew out of that, and both render Bengali to
/// a user who has selected English:
///
///   1. A bare literal:            Text('বাতিল')
///   2. A lookup whose fallback is Bengali:
///                                 Text(_t('common_cancel', 'বাতিল'))
///
/// The second looks translated but is not. `translate()` consults the server
/// payload, then the app's local map, and then returns the call site's own
/// fallback — which in this codebase is the Bengali string. So any key the
/// translation table happens to be missing silently renders Bengali in English
/// mode. Of the 1,381 keys the app asks for, 1,090 had no English anywhere.
/// That is what App Store review saw on an iPad: "Several sections of the app
/// did not change to English, even on selecting English language setting."
///
/// THE FIX
///
/// One dictionary keyed by the Bengali source text itself, so a single table
/// serves both habits: `tr()` for bare literals, and `translate()`'s fallback
/// path for the lookup form. Keying on Bengali rather than on invented keys
/// means Bengali mode is provably unchanged — the key IS the Bengali, returned
/// verbatim — and no call site has to agree on a naming scheme first.
///
/// An unknown string returns the Bengali unchanged. That is deliberate: a
/// missing translation should look like untranslated text, not like a crash or
/// a blank label. `untranslatedBengali()` and the guard test are what stop
/// "returns the input" from quietly becoming the normal case.
library;

import 'bn_en_dictionary.dart';

/// The active language code, mirrored here by [TranslationService] so this
/// library stays free of imports — otherwise the service and the dictionary
/// would import each other.
String _lang = 'bn';

/// Called by TranslationService on load and on every language change.
void setTrLanguage(String code) => _lang = code;

String get trLanguage => _lang;

/// Bengali is the only language whose text is already in the source.
bool get trIsBengali => _lang.isEmpty || _lang.startsWith('bn');

/// Canonical form of a Bengali string, used for both dictionary keys and
/// runtime lookups so the two cannot drift.
///
/// Two Bengali letters have a precomposed and a decomposed spelling that look
/// identical and compare unequal — য় is either U+09DF or U+09AF U+09BC, and
/// likewise ড়/ঢ়. Editors and copy-paste produce both, so the same visible
/// word can miss the dictionary. Everything is folded to the precomposed form.
String canonBn(String s) {
  // Explicit escapes on purpose: written as characters the two spellings
  // are indistinguishable in a source file, so these would be silent
  // no-ops and the normalisation would quietly do nothing.
  var out = s
      .replaceAll('\u09AF\u09BC', '\u09DF') // য + nukta -> য়
      .replaceAll('\u09A1\u09BC', '\u09DC') // ড + nukta -> ড়
      .replaceAll('\u09A2\u09BC', '\u09DD'); // ঢ + nukta -> ঢ়
  // Collapse whitespace runs, including the non-breaking space that comes
  // in with pasted text, so a line-wrapped literal still matches.
  out = out.replaceAll(RegExp(r'[\s\u00A0]+'), ' ').trim();
  return out;
}

/// Trailing punctuation that carries no meaning for the lookup. Kept out of the
/// dictionary so 'নাম' and 'নাম:' do not need two entries, and re-attached to
/// whatever English comes back.
final RegExp _trailing = RegExp(r'^(.*?)([\s:?!.।*…、,]+)$');

/// The English for [bn], or [bn] itself when there is no entry.
String trBn(String bn) {
  if (bn.isEmpty) return bn;
  final key = canonBn(bn);

  final exact = kBnEn[key];
  if (exact != null && exact.isNotEmpty) return exact;

  // 'সেভ করুন:' → look up 'সেভ করুন', return 'Save:'
  final m = _trailing.firstMatch(key);
  if (m != null) {
    final stem = kBnEn[m.group(1)!];
    if (stem != null && stem.isNotEmpty) return stem + m.group(2)!;
  }

  return bn;
}

/// Wrap a Bengali literal in this. Returns the Bengali untouched in Bengali
/// mode, so Bengali rendering cannot regress.
String tr(String bn) => trIsBengali ? bn : trBn(bn);

/// Bengali text with runtime values spliced in.
///
/// `'$n জন মেম্বার'` cannot be a dictionary key — by the time the string
/// exists, `$n` has already become "12", so no fixed key can match. Such
/// strings are rewritten to a template with numbered slots:
///
///     trf('{0} জন মেম্বার', [memberCount])   // → "12 members"
///
/// The template is the dictionary key, so the English can move the slot to
/// wherever English word order needs it.
String trf(String template, List<Object?> args) {
  var out = tr(template);
  for (var i = 0; i < args.length; i++) {
    out = out.replaceAll('{$i}', '${args[i]}');
  }
  return out;
}

/// True when [s] still contains Bengali letters. Used by the guard test to
/// assert that English mode emits none, and available to debug builds.
bool untranslatedBengali(String s) =>
    RegExp(r'[\u0980-\u09FF]').hasMatch(s);

/// Every Bengali key the dictionary knows. Exposed for the guard test.
Iterable<String> get trKeys => kBnEn.keys;
