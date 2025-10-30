import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _useDarkTheme = false;

  static const String _boxName = 'settings';
  Box? _box;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    _box = await Hive.openBox(_boxName);
    setState(() {
      _notifications = _box?.get('notifications', defaultValue: true) as bool? ?? true;
      _useDarkTheme = _box?.get('dark_theme', defaultValue: false) as bool? ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Preferences', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Enable notifications'),
                  value: _notifications,
                  onChanged: (v) {
                    setState(() => _notifications = v);
                    _box?.put('notifications', v);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Use dark theme'),
                  value: _useDarkTheme,
                  onChanged: (v) {
                    setState(() => _useDarkTheme = v);
                    _box?.put('dark_theme', v);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('MyCloudBook'),
              subtitle: const Text('Version 1.0.0'),
            ),
          ),
        ],
      ),
    );
  }
}


