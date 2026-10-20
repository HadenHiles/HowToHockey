import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design/components/training_components.dart';
import '../design/tokens/app_spacing.dart';
import '../features/accounts/auth_service.dart';
import '../features/profiles/active_player.dart';
import '../features/profiles/display_name.dart';
import '../features/profiles/profile_repository.dart';
import '../features/teams/team_repository.dart';
import 'training_state.dart';
import 'app_page.dart';

final _nameCharacters = FilteringTextInputFormatter.allow(RegExp(r"[\p{L}'’-]", unicode: true));
final _initialCharacter = FilteringTextInputFormatter.allow(RegExp(r'\p{L}', unicode: true));

bool switchPlayer(WidgetRef ref, BuildContext context, String profileId) {
  final session = ref.read(trainingSessionProvider);
  if (ref.read(activePlayerProvider)?.id != profileId && session.startedAt != null && !session.finished) {
    showFeatureMessage(context, 'Finish your current workout before switching players.');
    return false;
  }
  ref.read(activePlayerIdProvider.notifier).choose(profileId);
  return true;
}

/// Create an account with email and password, then the player's own profile.
class EmailSignupPage extends ConsumerStatefulWidget {
  const EmailSignupPage({required this.birthYear, super.key});

  final int? birthYear;

  @override
  ConsumerState<EmailSignupPage> createState() => _EmailSignupPageState();
}

class _EmailSignupPageState extends ConsumerState<EmailSignupPage> {
  final _first = TextEditingController();
  final _initial = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  var _accountCreated = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _accountCreated = ref.read(authServiceProvider).current is SignedInAccount;
  }

  @override
  void dispose() {
    _first.dispose();
    _initial.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    if (normalizeDisplayName('${_first.text.trim()} ${_initial.text.trim()}') == null) return 'Enter your first name and the first letter of your last name.';
    if (_accountCreated) return null;
    if (!looksLikeEmail(_email.text)) return 'That email doesn\'t look right.';
    return passwordProblem(_password.text);
  }

  Future<void> _submit() async {
    if (_busy) return;
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!_accountCreated) {
        await ref.read(authServiceProvider).createEmailAccount(email: _email.text, password: _password.text);
        _accountCreated = true;
      }
      // If this step fails the account already exists, so retrying only repeats the profile.
      await ref.read(profileRepositoryProvider).createOwnProfile(displayName: '${_first.text.trim()} ${_initial.text.trim()}', birthYear: widget.birthYear!, now: clock.now());
      if (mounted) context.go(pendingTeamInviteRoute(ref) ?? '/onboarding/role');
    } on AuthProblem catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.birthYear;
    if (year == null || !canHaveOwnAccount(year, clock.now())) {
      return AppPage(
        title: 'Start with your birth year',
        action: FilledButton(onPressed: () => context.go('/signup'), child: const Text('Back to sign-up')),
        children: const [Text('We need your birth year first, so young players get set up safely.')],
      );
    }
    return AppPage(
      title: 'Create account',
      subtitle: 'Your name shows as a first name and last initial, like Jamie H.',
      actions: [IconButton(tooltip: 'Back', icon: const Icon(Icons.close), onPressed: () => context.go('/signup'))],
      action: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Creating…' : (_accountCreated ? 'Try again' : 'Create account'))),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _first,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                inputFormatters: [_nameCharacters, LengthLimitingTextInputFormatter(24)],
                decoration: const InputDecoration(labelText: 'First name'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _initial,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_initialCharacter, LengthLimitingTextInputFormatter(1)],
                decoration: const InputDecoration(labelText: 'Last initial'),
              ),
            ),
          ],
        ),
        if (!_accountCreated) ...[
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: const [AutofillHints.newPassword],
            autocorrect: false,
            enableSuggestions: false,
            decoration: InputDecoration(
              labelText: 'Password',
              helperText: 'At least $minPasswordLength characters.',
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.md),
          const TrainingCard(child: Text('Your account is created. We just need to finish setting up your profile.')),
        ],
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        TextButton(onPressed: () => context.go('/signin'), child: const Text('I already have an account')),
      ],
    );
  }
}

/// A parent adds a child profile: first name, last initial and birth year.
class AddChildPage extends ConsumerStatefulWidget {
  const AddChildPage({super.key});

  @override
  ConsumerState<AddChildPage> createState() => _AddChildPageState();
}

class _AddChildPageState extends ConsumerState<AddChildPage> {
  final _first = TextEditingController();
  final _initial = TextEditingController();
  int? _year;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _first.dispose();
    _initial.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (normalizeDisplayName('${_first.text.trim()} ${_initial.text.trim()}') == null) {
      setState(() => _error = 'Enter your child\'s first name and the first letter of their last name.');
      return;
    }
    if (_year == null) {
      setState(() => _error = 'Pick your child\'s birth year.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(profileRepositoryProvider).createChildProfile(displayName: '${_first.text.trim()} ${_initial.text.trim()}', birthYear: _year!, now: clock.now());
      if (mounted) context.go('/parent/kids');
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thisYear = clock.now().year;
    return AppPage(
      title: 'Add a child',
      subtitle: 'Kids show as a first name and last initial, like Jamie H. No photos or free-text profiles.',
      actions: [IconButton(tooltip: 'Back to Kids', icon: const Icon(Icons.close), onPressed: () => context.go('/parent/kids'))],
      action: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Adding…' : 'Add child')),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _first,
                textCapitalization: TextCapitalization.words,
                inputFormatters: [_nameCharacters, LengthLimitingTextInputFormatter(24)],
                decoration: const InputDecoration(labelText: 'First name'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _initial,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_initialCharacter, LengthLimitingTextInputFormatter(1)],
                decoration: const InputDecoration(labelText: 'Last initial'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<int>(
          initialValue: _year,
          decoration: const InputDecoration(labelText: 'Birth year'),
          items: [for (var year = thisYear; year >= thisYear - childMaxYears; year--) DropdownMenuItem(value: year, child: Text('$year'))],
          onChanged: (value) => setState(() => _year = value),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Semantics(
            liveRegion: true,
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ],
    );
  }
}

/// A child's device: type in the code from a parent's phone and this device opens Player mode for that child.
class PairDevicePage extends ConsumerStatefulWidget {
  const PairDevicePage({super.key});

  @override
  ConsumerState<PairDevicePage> createState() => _PairDevicePageState();
}

class _PairDevicePageState extends ConsumerState<PairDevicePage> {
  final _code = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final pairing = await ref.read(profileRepositoryProvider).redeemPairingCode(_code.text);
      await ref.read(authServiceProvider).signInWithKidToken(pairing.token);
      if (mounted) context.go('/train');
    } on ProfileException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on AuthProblem catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Set up a kid\'s device',
    subtitle: 'Ask a parent to open Kids, pick you, and tap Pair a kid device. Then type the code here.',
    actions: [IconButton(tooltip: 'Back', icon: const Icon(Icons.close), onPressed: () => context.go('/welcome'))],
    action: FilledButton(onPressed: _busy ? null : _submit, child: Text(_busy ? 'Checking…' : 'Pair this device')),
    children: [
      TextField(
        controller: _code,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')), LengthLimitingTextInputFormatter(9)],
        decoration: const InputDecoration(labelText: '8-digit code'),
        onSubmitted: (_) => _submit(),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
    ],
  );
}

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  var _showPassword = false;
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_busy) return;
    if (!looksLikeEmail(_email.text) || _password.text.isEmpty) {
      setState(() => _error = 'Enter your email and password.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).signInWithEmail(email: _email.text, password: _password.text);
      if (mounted) context.go(pendingTeamInviteRoute(ref) ?? '/train');
    } on AuthProblem catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (!looksLikeEmail(_email.text)) {
      setState(() => _error = 'Enter your email above, then tap Forgot password.');
      return;
    }
    try {
      await ref.read(authServiceProvider).sendPasswordReset(_email.text);
      // The same message either way, so this can't be used to find out who has an account.
      if (mounted) showFeatureMessage(context, 'If there\'s an account for that email, we\'ve sent a link to reset your password.');
    } on AuthProblem catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) => AppPage(
    title: 'Sign in',
    actions: [IconButton(tooltip: 'Back', icon: const Icon(Icons.close), onPressed: () => context.canPop() ? context.pop() : context.go('/welcome'))],
    action: FilledButton(onPressed: _busy ? null : _signIn, child: Text(_busy ? 'Signing in…' : 'Sign in')),
    children: [
      TextField(
        controller: _email,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        decoration: const InputDecoration(labelText: 'Email'),
      ),
      const SizedBox(height: AppSpacing.md),
      TextField(
        controller: _password,
        obscureText: !_showPassword,
        autofillHints: const [AutofillHints.password],
        autocorrect: false,
        enableSuggestions: false,
        decoration: InputDecoration(
          labelText: 'Password',
          suffixIcon: IconButton(
            tooltip: _showPassword ? 'Hide password' : 'Show password',
            icon: Icon(_showPassword ? Icons.visibility_off : Icons.visibility),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.md),
        Semantics(
          liveRegion: true,
          child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        ),
      ],
      const SizedBox(height: AppSpacing.sm),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(onPressed: _reset, child: const Text('Forgot password?')),
      ),
      const SizedBox(height: AppSpacing.md),
      TextButton(onPressed: () => context.go('/signup'), child: const Text('Create an account instead')),
    ],
  );
}

/// Shows who is signed in and what they can do about it. Used in the Me and Parent account sheets.
class AccountSummary extends ConsumerWidget {
  const AccountSummary({required this.onNavigate, super.key});

  /// Called with a route after the sheet should close.
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(authStateProvider).value ?? const SignedOut();
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (state) {
        SignedInAccount(:final email, :final emailVerified) => [
          Text('Account', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          Text(email == null ? 'You\'re signed in.' : 'Signed in as $email.'),
          if (!emailVerified) ...[const SizedBox(height: AppSpacing.xs), Text('Check your email to confirm your address.', style: theme.textTheme.bodySmall)],
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(onPressed: () => unawaited(ref.read(authServiceProvider).signOut()), icon: const Icon(Icons.logout), label: const Text('Sign out')),
          const SizedBox(height: AppSpacing.sm),
          TextButton.icon(
            onPressed: () => unawaited(confirmAndDeleteAccount(context, ref)),
            style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete account'),
          ),
        ],
        KidDeviceSession() => [
          Text('Kid device', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          const Text('A parent paired this device. It opens Player mode for one child only.'),
          const SizedBox(height: AppSpacing.xl),
          OutlinedButton.icon(onPressed: () => unawaited(ref.read(authServiceProvider).signOut()), icon: const Icon(Icons.link_off), label: const Text('Unpair this device')),
        ],
        _ => [
          Text('Account', style: theme.textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xs),
          const Text('You\'re using the app as a guest. Create an account to keep your players safe across devices.'),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(onPressed: () => onNavigate('/signup'), icon: const Icon(Icons.person_add_alt), label: const Text('Create an account')),
          const SizedBox(height: AppSpacing.sm),
          OutlinedButton.icon(onPressed: () => onNavigate('/signin'), icon: const Icon(Icons.login), label: const Text('Sign in')),
        ],
      },
    );
  }
}

Future<void> confirmAndDeleteAccount(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete your account?'),
      content: const Text(
        'This permanently deletes your account, your player profile, every child profile you added, and their saved progress. Paired kid devices are signed out. This can\'t be undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep my account')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(dialogContext).colorScheme.error, foregroundColor: Theme.of(dialogContext).colorScheme.onError),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Delete everything'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;
  try {
    await ref.read(profileRepositoryProvider).deleteAccount();
    ref.read(activePlayerIdProvider.notifier).clear();
    await ref.read(authServiceProvider).signOut();
    messenger.showSnackBar(const SnackBar(content: Text('Your account was deleted.')));
  } on ProfileException catch (error) {
    messenger.showSnackBar(SnackBar(content: Text(error.message)));
  } on AuthProblem {
    messenger.showSnackBar(const SnackBar(content: Text('Your account was deleted. Close and reopen the app to start fresh.')));
  }
}
