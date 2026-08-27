import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which panel the sidebar is showing.
enum SideBarTab { files, search, toc }

/// Held outside the sidebar widget so the View menu can switch to a panel —
/// jumping to the table of contents, say — without reaching into its state.
final sideBarTabProvider =
    StateProvider<SideBarTab>((ref) => SideBarTab.files);
