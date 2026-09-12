import 'package:flutter/material.dart';

/// An icon that points the way the text runs.
///
/// Material's rule is that an icon which points somewhere has to point where
/// the reader is going: a chevron that opens a folder points into the tree, and
/// in Arabic the tree indents the other way. The side bar's own indentation was
/// already `EdgeInsetsDirectional` — the arrow beside it was not, so a
/// collapsed folder pointed away from where it would open.
///
/// Two kinds of mirroring, because Material only supplies the first:
///
/// * an icon with a partner facing the other way, which is swapped for it;
/// * one with no partner — `send` is the only one here — which is flipped.
///
/// A flip is not a substitute for a partner. `keyboard_arrow_right` flipped is
/// not `keyboard_arrow_left`: the glyphs are not mirror images of each other,
/// and the difference shows at 16 pixels.
class DirectionalIcon extends StatelessWidget {
  const DirectionalIcon(this.icon, {this.size, this.color, super.key});

  final IconData icon;
  final double? size;
  final Color? color;

  /// Icons that have a counterpart facing the other way.
  ///
  /// One direction only: every entry here is an icon that points the way text
  /// runs in a left-to-right layout, which is the only direction the rest of
  /// the editor is written in.
  /// Not `const`: `IconData` overrides `==`, which a constant map's keys may
  /// not do.
  static final partners = <IconData, IconData>{
    Icons.chevron_right: Icons.chevron_left,
    Icons.keyboard_arrow_right: Icons.keyboard_arrow_left,
    Icons.arrow_forward: Icons.arrow_back,
    Icons.arrow_forward_ios: Icons.arrow_back_ios,
    Icons.navigate_next: Icons.navigate_before,
    Icons.last_page: Icons.first_page,
  };

  @override
  Widget build(BuildContext context) {
    final drawn = Icon(icon, size: size, color: color);
    if (Directionality.of(context) != TextDirection.rtl) return drawn;
    final partner = partners[icon];
    if (partner != null) return Icon(partner, size: size, color: color);
    return Transform.flip(flipX: true, child: drawn);
  }
}
