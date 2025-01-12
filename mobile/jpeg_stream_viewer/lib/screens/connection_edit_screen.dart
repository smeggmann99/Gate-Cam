import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jpegsv/localization/localization.dart';
import 'package:jpegsv/models/stream_element.dart';
import 'package:jpegsv/widgets/action_list_item.dart';
import 'package:jpegsv/screens/action_edit_screen.dart';

class ConnectionEditScreen extends StatefulWidget {
  final StreamElement? element;

  const ConnectionEditScreen({super.key, this.element});

  @override
  State<ConnectionEditScreen> createState() => _ConnectionEditScreenState();
}

class _ConnectionEditScreenState extends State<ConnectionEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late List<ActionElement> _actions;

  AppLocalizations get localizations => AppLocalizations.of(context);

  final Set<int> _selectedIndexes = {};
  bool _isSelectionMode = false;
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.element?.name ?? '');
    _urlController = TextEditingController(text: widget.element?.url ?? '');
    _usernameController =
        TextEditingController(text: widget.element?.username ?? '');
    _passwordController =
        TextEditingController(text: widget.element?.password ?? '');
    _actions = List.from(widget.element?.actions ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _addAction() async {
    final newAction = ActionElement(
      name: '',
      icon: '',
      endpoint: '',
      method: 'GET',
      headers: {},
    );

    final updatedAction = await Navigator.push<ActionElement>(
      context,
      MaterialPageRoute(
        builder: (context) => ActionEditScreen(action: newAction),
      ),
    );

    if (updatedAction != null) {
      setState(() {
        _actions.add(updatedAction);
      });
    }
  }

  void _editAction(int index) async {
    final updatedAction = await Navigator.push<ActionElement>(
      context,
      MaterialPageRoute(
        builder: (context) => ActionEditScreen(action: _actions[index]),
      ),
    );

    if (updatedAction != null) {
      setState(() {
        _actions[index] = updatedAction;
      });
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final selectedCount = _selectedIndexes.length;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(localizations
              .translate('screens.connection_edit.labels.delete_selected')),
          content: Text(
            localizations.translateWithParams(
                'screens.connection_edit.labels.delete_selected_confirmation',
                {'amount': selectedCount.toString()}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(localizations
                  .translate('screens.connection_edit.buttons.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(localizations
                  .translate('screens.connection_edit.buttons.delete')),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      _deleteSelected();
    }
  }

  void _deleteSelected() {
    setState(() {
      _actions = _actions
          .asMap()
          .entries
          .where((entry) => !_selectedIndexes.contains(entry.key))
          .map((entry) => entry.value)
          .toList();
      _selectedIndexes.clear();
      _isSelectionMode = false;
    });
  }

  void _toggleSelectMode(bool isSelectMode) {
    setState(() {
      _isSelectionMode = isSelectMode;
      if (!isSelectMode) {
        _selectedIndexes.clear();
      }
    });
  }

  void _updateSelectionState() {
    if (_selectedIndexes.isEmpty) {
      _toggleSelectMode(false);
    }
  }

  String _getAppBarTitle() {
    return _isSelectionMode
        ? localizations.translateWithParams(
            'screens.connection_edit.labels.selected',
            {'amount': _selectedIndexes.length.toString()})
        : (widget.element == null
            ? localizations.translate('screens.connection_edit.title_alt')
            : localizations.translate('screens.connection_edit.title'));
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.isEmpty ||
        _urlController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(localizations.translate(
                'screens.connection_edit.labels.please_fill_all_fields'))),
      );
      return;
    }

    final box = Hive.box<StreamElement>('stream_elements');

    if (widget.element == null) {
      final newElement = StreamElement(
        name: _nameController.text,
        url: _urlController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        actions: _actions,
      );
      await box.add(newElement);
    } else {
      widget.element!.name = _nameController.text;
      widget.element!.url = _urlController.text;
      widget.element!.username = _usernameController.text;
      widget.element!.password = _passwordController.text;
      widget.element!.actions = _actions;
      await widget.element!.save();
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          if (_isSelectionMode) ...[
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: _confirmDeleteSelected,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => _toggleSelectMode(false),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.save),
                tooltip: localizations
                    .translate('screens.connection_edit.buttons.save'),
                onPressed: _saveChanges,
              ),
            ),
        ],
      ),
      body: ListView(
        padding:
            const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 84),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                  labelText: localizations.translate(
                      'screens.connection_edit.labels.connection_name')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                  labelText: localizations
                      .translate('screens.connection_edit.labels.endpoint')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                  labelText: localizations
                      .translate('screens.connection_edit.labels.username')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: localizations
                    .translate('screens.connection_edit.labels.password'),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isObscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                ),
              ),
              obscureText: _isObscure,
            ),
          ),
          const SizedBox(height: 24),
          if (_actions.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_remove, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(localizations.translate(
                      'screens.connection_edit.labels.no_actions_available')),
                ],
              ),
            )
          else ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                localizations
                    .translate('screens.connection_edit.labels.actions'),
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
          ],
          ListView.builder(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _actions.length,
            itemBuilder: (context, index) {
              final action = _actions[index];
              final isSelected = _selectedIndexes.contains(index);

              return ActionListItem(
                action: action,
                isSelected: isSelected,
                isSelectionMode: _isSelectionMode,
                onTap: () {
                  if (_isSelectionMode) {
                    setState(() {
                      if (isSelected) {
                        _selectedIndexes.remove(index);
                      } else {
                        _selectedIndexes.add(index);
                      }
                      _updateSelectionState();
                    });
                  }
                },
                onLongPress: () {
                  if (!_isSelectionMode) {
                    _toggleSelectMode(true);
                    _selectedIndexes.add(index);
                  }
                },
                onCheckboxChanged: (checked) {
                  setState(() {
                    if (checked ?? false) {
                      _selectedIndexes.add(index);
                    } else {
                      _selectedIndexes.remove(index);
                    }
                    _updateSelectionState();
                  });
                },
                onEdit: () => _editAction(index),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: _addAction,
              icon: const Icon(Icons.add),
              label: Text(localizations
                  .translate('screens.connection_edit.buttons.add_action')),
            ),
    );
  }
}
