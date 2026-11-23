import 'package:flutter/material.dart';
import 'package:keyboard_dock/keyboard_dock.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'keyboard_dock',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('keyboard_dock')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Sign-up form'),
            subtitle: const Text('Button stays above the keyboard'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const SignUpPage()),
          ),
          ListTile(
            title: const Text('Notes'),
            subtitle: const Text('Toolbar only while typing'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _push(context, const NotesPage()),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Account created')));
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: KeyboardDock(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outlineVariant)),
        ),
        footer: FilledButton(
          onPressed: _submit,
          child: const Text('Create account'),
        ),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Hide the header while typing so small phones have room for
              // the fields.
              KeyboardVisibilityBuilder(
                builder: (context, isKeyboardOpen, child) {
                  return AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: isKeyboardOpen ? const SizedBox.shrink() : child,
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'It only takes a minute.',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
              for (final label in ['Name', 'Email', 'Phone', 'City'])
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: TextFormField(
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) => (value == null || value.length < 8)
                    ? 'At least 8 characters'
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: KeyboardDock(
        visibility: DockVisibility.whenKeyboardOpen,
        decoration: BoxDecoration(color: colors.surfaceContainerHigh),
        footer: Row(
          children: [
            IconButton(onPressed: () {}, icon: const Icon(Icons.format_bold)),
            IconButton(onPressed: () {}, icon: const Icon(Icons.format_italic)),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.format_list_bulleted),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => FocusScope.of(context).unfocus(),
              child: const Text('Done'),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: TextField(
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration.collapsed(hintText: 'Start typing…'),
          ),
        ),
      ),
    );
  }
}
