import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_page.dart';

class OwnProfileSetupPage extends StatefulWidget {
  const OwnProfileSetupPage({super.key});
  @override
  State<OwnProfileSetupPage> createState() => _OwnProfileSetupPageState();
}

class _OwnProfileSetupPageState extends State<OwnProfileSetupPage> {
  int? _year;
  @override
  Widget build(BuildContext context) {
    final year = clock.now().year;
    return AppPage(
      title: 'Finish player setup',
      children: [
        const Text('Your account is already created. Add your player profile to train, join teams, or accept coach invites.'),
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: 'Birth year'),
          items: [for (var y = year - 14; y >= year - 100; y--) DropdownMenuItem(value: y, child: Text('$y'))],
          onChanged: (value) => setState(() => _year = value),
        ),
        FilledButton(onPressed: _year == null ? null : () => context.go('/signup/email?year=$_year'), child: const Text('Continue')),
      ],
    );
  }
}
