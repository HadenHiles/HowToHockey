import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:how_to_hockey/app/hockey_app.dart';
import 'package:how_to_hockey/features/accounts/auth_service.dart';
import 'package:how_to_hockey/features/profiles/active_player.dart';
import 'package:how_to_hockey/features/profiles/player_profile.dart';
import 'package:how_to_hockey/features/profiles/profile_repository.dart';
import 'package:how_to_hockey/features/settings/appearance_settings_controller.dart';
import 'package:how_to_hockey/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/test_catalog.dart';

Future<ProviderContainer> mount(WidgetTester tester, {AuthState initial = const GuestSession('guest-1')}) async {
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  final auth = FakeAuthService(initial);
  testProfiles.calls.clear();
  testProfiles.failWith = null;
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      testCatalogOverride,
      testMediaOverride,
      testCuesOverride,
      testRemindersOverride,
      authServiceProvider.overrideWithValue(auth),
      testProfilesOverride,
    ],
  );
  addTearDown(container.dispose);
  tester.view.physicalSize = const Size(1000, 3000);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MyApp()));
  await tester.pumpAndSettle();
  _auth = auth;
  return container;
}

late FakeAuthService _auth;

Future<void> fillSignup(WidgetTester tester, {String first = 'Pat', String initial = 'H', String email = 'pat@example.com', String password = 'correct horse'}) async {
  await tester.enterText(find.widgetWithText(TextField, 'First name'), first);
  await tester.enterText(find.widgetWithText(TextField, 'Last initial'), initial);
  if (find.widgetWithText(TextField, 'Email').evaluate().isNotEmpty) {
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
  }
}

void main() {
  group('age gate to sign-up', () {
    testWidgets('an adult picks a birth year, continues with email, and gets an account and a profile', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/signup');
      await tester.pumpAndSettle();
      // The year list is long and lazily built, so choose the value directly.
      tester.widget<DropdownButtonFormField<int>>(find.byType(DropdownButtonFormField<int>)).onChanged!(DateTime.now().year - 30);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with email'));
      await tester.pumpAndSettle();

      expect(find.text('Create account'), findsWidgets);
      await fillSignup(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();

      expect(_auth.calls, ['create:pat@example.com']);
      expect(testProfiles.calls, ['own:Pat H:${DateTime.now().year - 30}']);
      expect(container.read(appRouterProvider).routeInformationProvider.value.uri.path, '/onboarding/role');
    });

    testWidgets('someone who could be under 13 cannot reach the account form', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/signup/email?year=${DateTime.now().year - 10}');
      await tester.pumpAndSettle();
      expect(find.text('Start with your birth year'), findsWidgets);
      expect(find.widgetWithText(TextField, 'Email'), findsNothing);

      container.read(appRouterProvider).go('/signup/email');
      await tester.pumpAndSettle();
      expect(find.text('Start with your birth year'), findsWidgets);
    });
  });

  group('email sign-up form', () {
    Future<ProviderContainer> open(WidgetTester tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/signup/email?year=${DateTime.now().year - 30}');
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('checks the form before calling anything', (tester) async {
      await open(tester);
      Future<void> trySubmit() async {
        await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
        await tester.pumpAndSettle();
      }

      await trySubmit();
      expect(find.textContaining('first name and the first letter'), findsOneWidget);
      await fillSignup(tester, email: 'not-an-email');
      await trySubmit();
      expect(find.text('That email doesn\'t look right.'), findsOneWidget);
      await fillSignup(tester, password: 'short');
      await trySubmit();
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(_auth.calls, isEmpty);
      expect(testProfiles.calls, isEmpty);
    });

    testWidgets('only lets letters into the name fields and one letter into the initial', (tester) async {
      await open(tester);
      await tester.enterText(find.widgetWithText(TextField, 'First name'), 'J4m<i>e!');
      await tester.enterText(find.widgetWithText(TextField, 'Last initial'), 'Hx9');
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'First name')).controller!.text, 'Jmie');
      expect(tester.widget<TextField>(find.widgetWithText(TextField, 'Last initial')).controller!.text, 'H');
    });

    testWidgets('shows a friendly message when the email is taken and keeps the form', (tester) async {
      await open(tester);
      _auth.failWith = authProblemFor(FirebaseAuthException(code: 'email-already-in-use'));
      await fillSignup(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('already exists'), findsOneWidget);
      expect(testProfiles.calls, isEmpty);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    });

    testWidgets('if the profile step fails the account is kept and only the profile is retried', (tester) async {
      final container = await open(tester);
      testProfiles.failWith = const ProfileException('We couldn\'t reach the server. Check your connection and try again.');
      await fillSignup(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Create account'));
      await tester.pumpAndSettle();
      expect(find.textContaining('reach the server'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsNothing, reason: 'the account exists, so the email and password are done');
      expect(find.text('Try again'), findsOneWidget);

      testProfiles.failWith = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(_auth.calls, ['create:pat@example.com'], reason: 'no second account');
      expect(testProfiles.calls, hasLength(2));
      expect(container.read(appRouterProvider).routeInformationProvider.value.uri.path, '/onboarding/role');
    });
  });

  group('sign in', () {
    testWidgets('signs in and goes to Train', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/signin');
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'pat@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'correct horse');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(_auth.calls, ['signin:pat@example.com']);
      expect(container.read(appRouterProvider).routeInformationProvider.value.uri.path, '/train');
    });

    testWidgets('a wrong password shows one friendly message and stays put', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/signin');
      await tester.pumpAndSettle();
      _auth.failWith = authProblemFor(FirebaseAuthException(code: 'wrong-password'));
      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'pat@example.com');
      await tester.enterText(find.widgetWithText(TextField, 'Password'), 'nope');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('That email and password don\'t match.'), findsOneWidget);
      expect(container.read(appRouterProvider).routeInformationProvider.value.uri.path, '/signin');
    });

    testWidgets('forgot password asks for an email first and never reveals whether it exists', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/signin');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter your email above'), findsOneWidget);
      expect(_auth.calls, isEmpty);

      await tester.enterText(find.widgetWithText(TextField, 'Email'), 'pat@example.com');
      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      expect(_auth.calls, ['reset:pat@example.com']);
      expect(find.textContaining('If there\'s an account for that email'), findsOneWidget);
    });
  });

  group('account sheet', () {
    testWidgets('a guest sees create account and sign in, then the signed-in view after signing up', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      expect(find.text('Guest session'), findsOneWidget);
      await tester.ensureVisible(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
    });

    testWidgets('a signed-in account shows the email and can sign out back to a guest', (tester) async {
      final container = await mount(
        tester,
        initial: const SignedInAccount(uid: 'u1', email: 'pat@example.com', emailVerified: false),
      );
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      expect(find.text('pat@example.com'), findsOneWidget);
      await tester.ensureVisible(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Signed in as pat@example.com.'), findsOneWidget);
      expect(find.textContaining('Check your email'), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(_auth.calls, ['signout']);
      expect(find.text('Create an account'), findsOneWidget);
    });
  });

  group('helpers', () {
    test('Firebase sign-in errors become friendly messages, and sign-in problems never say which part was wrong', () {
      String message(String code) => authProblemFor(FirebaseAuthException(code: code)).message;
      expect(message('wrong-password'), message('user-not-found'));
      expect(message('wrong-password'), message('invalid-credential'));
      expect(message('email-already-in-use'), contains('already exists'));
      expect(message('weak-password'), contains('password'));
      expect(message('network-request-failed'), contains('reach the server'));
      expect(message('too-many-requests'), contains('Wait'));
      expect(message('something-new'), 'Something went wrong. Try again.');
    });

    test('email shape checks catch obvious typos', () {
      for (final good in ['a@b.co', ' pat@example.com ', 'first.last+tag@sub.example.org']) {
        expect(looksLikeEmail(good), isTrue, reason: good);
      }
      for (final bad in ['', 'pat', 'pat@', '@example.com', 'pat@example', 'pat @example.com', 'pat@exa mple.com']) {
        expect(looksLikeEmail(bad), isFalse, reason: bad);
      }
    });

    test('password needs at least 8 characters', () {
      expect(passwordProblem('1234567'), isNotNull);
      expect(passwordProblem('12345678'), isNull);
    });
  });

  group('account deletion and role guards', () {
    testWidgets('deleting asks first, then removes the account and returns to a guest session', (tester) async {
      final container = await mount(
        tester,
        initial: const SignedInAccount(uid: 'u1', email: 'pat@example.com', emailVerified: true),
      );
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('This permanently deletes your account'), findsOneWidget);

      await tester.tap(find.text('Keep my account'));
      await tester.pumpAndSettle();
      expect(testProfiles.calls, isNot(contains('delete-account')));
      expect(_auth.current, isA<SignedInAccount>());

      await tester.tap(find.text('Delete account').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();
      expect(testProfiles.calls, contains('delete-account'));
      expect(_auth.current, isA<GuestSession>());
      expect(find.text('Your account was deleted.'), findsOneWidget);
    });

    testWidgets('a failed deletion keeps the account and says why', (tester) async {
      final container = await mount(
        tester,
        initial: const SignedInAccount(uid: 'u1', email: 'pat@example.com', emailVerified: true),
      );
      testProfiles.failWith = const ProfileException('We couldn\'t reach the server. Check your connection and try again.');
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete account').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete everything'));
      await tester.pumpAndSettle();
      expect(find.textContaining('couldn\'t reach the server'), findsOneWidget);
      expect(_auth.current, isA<SignedInAccount>());
    });

    test('guests can\'t open Parent or Coach; accounts can; kid devices go to Train', () {
      const guest = GuestSession('g');
      const account = SignedInAccount(uid: 'u', email: 'a@b.co', emailVerified: false);
      for (final path in ['/parent', '/parent/kids', '/coach/roster', '/coach']) {
        expect(roleRedirect(guest, path), '/signup', reason: path);
        expect(roleRedirect(const SignedOut(), path), '/signup', reason: path);
        expect(roleRedirect(null, path), '/signup', reason: path);
        expect(roleRedirect(account, path), isNull, reason: path);
        expect(roleRedirect(const KidDeviceSession('k'), path), '/train', reason: path);
      }
      expect(roleRedirect(guest, '/train'), isNull);
      expect(roleRedirect(guest, '/parentage'), isNull);
    });
  });

  group('switch player', () {
    testWidgets('lists the account\'s own profile and children, remembers the choice, and Train as child uses it', (tester) async {
      testProfiles.own = const PlayerProfile(id: 'existing-user', ownerUid: 'existing-user', displayName: 'Pat H.', birthYear: 1985, isChild: false);
      testProfiles.children
        ..clear()
        ..add(const PlayerProfile(id: 'child-1', ownerUid: 'existing-user', displayName: 'Avery H.', birthYear: 2015, isChild: true));
      final container = await mount(
        tester,
        initial: const SignedInAccount(uid: 'existing-user', email: 'pat@example.com', emailVerified: true),
      );
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      expect(find.text('Pat H.'), findsOneWidget);

      await tester.tap(find.text('Pat H.'));
      await tester.pumpAndSettle();
      expect(find.text('Player profile'), findsOneWidget);
      await tester.tap(find.text('Avery H.'));
      await tester.pumpAndSettle();
      expect(find.text('Avery H.'), findsWidgets);
      expect(find.text('CHILD PROFILE'), findsOneWidget);
      expect(container.read(activePlayerIdProvider), 'child-1');
      expect((await SharedPreferences.getInstance()).getString('activePlayerId'), 'child-1');

      container.read(activePlayerIdProvider.notifier).choose('gone');
      expect(container.read(activePlayerProvider)?.displayName, 'Pat H.');
    });

    testWidgets('a kid device shows its own child and cannot switch', (tester) async {
      testProfiles.children
        ..clear()
        ..add(const PlayerProfile(id: 'child-1', ownerUid: 'someone', displayName: 'Avery H.', birthYear: 2015, isChild: true));
      final container = await mount(tester, initial: const KidDeviceSession('child-1'));
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      expect(find.text('Avery H.'), findsOneWidget);
      expect(find.text('Switch player'), findsNothing);
      expect(container.read(switchablePlayersProvider), hasLength(1));
    });
  });

  group('kid device', () {
    testWidgets('a parent\'s code pairs the device and locks it to Player screens', (tester) async {
      final container = await mount(tester);
      container.read(appRouterProvider).go('/pair');
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '1111 2222');
      await tester.tap(find.text('Pair this device'));
      await tester.pumpAndSettle();
      expect(find.textContaining('That code didn\'t work'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      await tester.enterText(find.byType(TextField), '1234 5678');
      await tester.tap(find.text('Pair this device'));
      await tester.pumpAndSettle();
      expect(_auth.current, isA<KidDeviceSession>());
      expect((_auth.current as KidDeviceSession).profileId, 'child-1');
      expect(container.read(appRouterProvider).state.uri.path, '/train');

      for (final path in ['/parent/kids', '/coach/roster', '/signup', '/pair', '/paywall']) {
        container.read(appRouterProvider).go(path);
        await tester.pumpAndSettle();
        expect(container.read(appRouterProvider).state.uri.path, '/train', reason: path);
      }
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      expect(find.text('Switch role'), findsNothing);
      expect(find.text('Kid device'), findsOneWidget);
    });

    test('only parent, coach and sign-in screens are blocked', () {
      expect(kidDeviceRedirect('/parent/kids/x/pair'), '/train');
      expect(kidDeviceRedirect('/coach'), '/train');
      expect(kidDeviceRedirect('/train/session'), isNull);
      expect(kidDeviceRedirect('/library'), isNull);
      expect(kidDeviceRedirect('/parentage'), isNull);
    });

    testWidgets('unpairing returns the device to a guest session', (tester) async {
      final container = await mount(tester, initial: const KidDeviceSession('child-1'));
      container.read(appRouterProvider).go('/me');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Kid device'));
      await tester.tap(find.text('Kid device'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Unpair this device'));
      await tester.pumpAndSettle();
      expect(_auth.current, isA<GuestSession>());
    });
  });
}
