import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcutsWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback onNewEvent;
  final VoidCallback onSearch;
  final VoidCallback onToday;
  final VoidCallback? onNextDay;
  final VoidCallback? onPreviousDay;
  final VoidCallback? onNextWeek;
  final VoidCallback? onPreviousWeek;
  final VoidCallback? onNextMonth;
  final VoidCallback? onPreviousMonth;

  const KeyboardShortcutsWidget({
    Key? key,
    required this.child,
    required this.onNewEvent,
    required this.onSearch,
    required this.onToday,
    this.onNextDay,
    this.onPreviousDay,
    this.onNextWeek,
    this.onPreviousWeek,
    this.onNextMonth,
    this.onPreviousMonth,
  }) : super(key: key);

  @override
  State<KeyboardShortcutsWidget> createState() => _KeyboardShortcutsWidgetState();
}

class _KeyboardShortcutsWidgetState extends State<KeyboardShortcutsWidget> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final isCtrlPressed = HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;
    final isAltPressed = HardwareKeyboard.instance.isAltPressed;

    // Ctrl/Cmd + N: New Event
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyN) {
      widget.onNewEvent();
      return KeyEventResult.handled;
    }

    // Ctrl/Cmd + F: Search
    if (isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyF) {
      widget.onSearch();
      return KeyEventResult.handled;
    }

    // T: Today
    if (!isCtrlPressed && event.logicalKey == LogicalKeyboardKey.keyT) {
      widget.onToday();
      return KeyEventResult.handled;
    }

    // Arrow Right: Next day
    if (!isCtrlPressed && !isShiftPressed && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onNextDay?.call();
      return KeyEventResult.handled;
    }

    // Arrow Left: Previous day
    if (!isCtrlPressed && !isShiftPressed && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onPreviousDay?.call();
      return KeyEventResult.handled;
    }

    // Shift + Arrow Right: Next week
    if (isShiftPressed && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      widget.onNextWeek?.call();
      return KeyEventResult.handled;
    }

    // Shift + Arrow Left: Previous week
    if (isShiftPressed && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      widget.onPreviousWeek?.call();
      return KeyEventResult.handled;
    }

    // Shift + Arrow Up: Previous month
    if (isShiftPressed && event.logicalKey == LogicalKeyboardKey.arrowUp) {
      widget.onPreviousMonth?.call();
      return KeyEventResult.handled;
    }

    // Shift + Arrow Down: Next month
    if (isShiftPressed && event.logicalKey == LogicalKeyboardKey.arrowDown) {
      widget.onNextMonth?.call();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: widget.child,
    );
  }
}

class KeyboardShortcutsHelp extends StatelessWidget {
  const KeyboardShortcutsHelp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Atajos de Teclado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildShortcutItem('Ctrl/Cmd + N', 'Crear nuevo evento'),
            _buildShortcutItem('Ctrl/Cmd + F', 'Buscar eventos'),
            _buildShortcutItem('T', 'Ir a hoy'),
            const Divider(),
            const Text(
              'Navegación',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildShortcutItem('←', 'Día anterior'),
            _buildShortcutItem('→', 'Día siguiente'),
            _buildShortcutItem('Shift + ←', 'Semana anterior'),
            _buildShortcutItem('Shift + →', 'Semana siguiente'),
            _buildShortcutItem('Shift + ↑', 'Mes anterior'),
            _buildShortcutItem('Shift + ↓', 'Mes siguiente'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cerrar'),
        ),
      ],
    );
  }

  Widget _buildShortcutItem(String shortcut, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              shortcut,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(description),
          ),
        ],
      ),
    );
  }
}
