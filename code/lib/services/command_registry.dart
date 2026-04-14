import 'package:flutter/widgets.dart';

class Command {
  final String id;
  final String label;
  final String description;
  final VoidCallback execute;

  const Command({
    required this.id,
    required this.label,
    required this.description,
    required this.execute,
  });
}

class CommandRegistry {
  CommandRegistry._();
  static final CommandRegistry instance = CommandRegistry._();

  final List<Command> _commands = [];

  List<Command> get commands => List.unmodifiable(_commands);

  void register(Command command) {
    _commands.removeWhere((c) => c.id == command.id);
    _commands.add(command);
  }

  void registerAll(List<Command> commands) {
    for (final cmd in commands) {
      register(cmd);
    }
  }

  void clear() => _commands.clear();

  List<Command> search(String query) {
    if (query.isEmpty) return List.from(_commands);
    final lower = query.toLowerCase();
    return _commands.where((cmd) {
      return cmd.label.toLowerCase().contains(lower) ||
          cmd.description.toLowerCase().contains(lower);
    }).toList();
  }
}
