import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/ai_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifications = true;
  bool _useDarkTheme = false;
  final _apiKeyController = TextEditingController();
  bool _hasApiKey = false;
  bool _apiKeyVisible = false;

  static const String _boxName = 'settings';
  Box? _box;
  final AIService _aiService = AIService();

  @override
  void initState() {
    super.initState();
    _open();
    _checkAPIKey();
  }

  Future<void> _open() async {
    _box = await Hive.openBox(_boxName);
    setState(() {
      _notifications = _box?.get('notifications', defaultValue: true) as bool? ?? true;
      _useDarkTheme = _box?.get('dark_theme', defaultValue: false) as bool? ?? false;
    });
  }

  Future<void> _checkAPIKey() async {
    try {
      final key = await _aiService.getAPIKey();
      setState(() {
        _hasApiKey = key != null;
        if (_hasApiKey) {
          _apiKeyController.text = '••••••••${key!.substring(key.length - 4)}';
        }
      });
    } catch (_) {
      // Handle error
    }
  }

  Future<void> _saveAPIKey() async {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an API key')),
      );
      return;
    }

    try {
      await _aiService.storeAPIKey(apiKey);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('API key saved successfully')),
        );
        await _checkAPIKey();
        setState(() => _apiKeyVisible = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving API key: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
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
          Text('AI Settings', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Gemini API Key'),
                  subtitle: Text(_hasApiKey ? 'API key configured' : 'Not configured'),
                  trailing: IconButton(
                    icon: Icon(_apiKeyVisible ? Icons.visibility_off : Icons.visibility),
                    onPressed: () {
                      setState(() => _apiKeyVisible = !_apiKeyVisible);
                      if (!_apiKeyVisible && _hasApiKey) {
                        _apiKeyController.text = '••••••••••••';
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _apiKeyController,
                    obscureText: !_apiKeyVisible && _hasApiKey,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: 'Enter your Gemini API key',
                      helperText: 'Get your API key from https://aistudio.google.com/app/apikey',
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (!_hasApiKey || _apiKeyVisible) {
                        setState(() {});
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _saveAPIKey,
                          icon: const Icon(Icons.save),
                          label: const Text('Save API Key'),
                        ),
                      ),
                      if (_hasApiKey) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            _apiKeyController.clear();
                            setState(() {
                              _hasApiKey = false;
                              _apiKeyVisible = true;
                            });
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Change'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text('Usage', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              title: const Text('Usage Dashboard'),
              subtitle: const Text('View your quotas and usage'),
              leading: const Icon(Icons.dashboard),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/usage'),
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


