/// Display names are a first name and a last initial, such as "Jamie H.".
/// The server checks the same rules; this keeps forms friendly before anything is sent.
final _namePattern = RegExp(r"^(\p{L}[\p{L}'’-]{0,23}) (\p{L})\.?$", unicode: true);

/// Returns the tidied name (for example `Jamie H.`), or null when it isn't a first name and last initial.
String? normalizeDisplayName(String input) {
  final match = _namePattern.firstMatch(input.trim().replaceAll(RegExp(r'\s+'), ' '));
  if (match == null) return null;
  final first = match.group(1)!;
  final runes = first.runes.toList();
  final capitalized = String.fromCharCode(runes.first).toUpperCase() + String.fromCharCodes(runes.skip(1));
  return '$capitalized ${match.group(2)!.toUpperCase()}.';
}

/// Years since birth year at which an account is allowed (certainly 13 or older).
const accountMinYears = 14;

/// Years since birth year up to which a child profile is allowed (certainly 17 or younger).
const childMaxYears = 17;

/// The most child profiles one account can have.
const maxChildProfiles = 3;

bool canHaveOwnAccount(int birthYear, DateTime now) => now.year - birthYear >= accountMinYears;

bool canBeChildProfile(int birthYear, DateTime now) {
  final years = now.year - birthYear;
  return years >= 0 && years <= childMaxYears;
}

/// Two-letter avatar initials from a display name like "Jamie H.".
String initialsOf(String displayName) {
  final parts = displayName.trim().split(' ').where((part) => part.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  return '${String.fromCharCode(parts.first.runes.first)}${parts.length > 1 ? String.fromCharCode(parts.last.runes.first) : ''}'.toUpperCase();
}
