/// Visibility prefix of a class member.
///
/// Mermaid uses the UML sigils `+ - # ~` in front of a member name.
enum ClassMemberVisibility {
  /// `+` — public
  public,

  /// `-` — private
  private,

  /// `#` — protected
  protected,

  /// `~` — package/internal
  package,

  /// No sigil written.
  none,
}

/// Renders the UML sigil for a visibility, or an empty string for [none].
String classMemberVisibilitySymbol(ClassMemberVisibility visibility) {
  switch (visibility) {
    case ClassMemberVisibility.public:
      return '+';
    case ClassMemberVisibility.private:
      return '-';
    case ClassMemberVisibility.protected:
      return '#';
    case ClassMemberVisibility.package:
      return '~';
    case ClassMemberVisibility.none:
      return '';
  }
}

/// A single attribute or method inside a class box.
class ClassMember {
  /// Creates a class member.
  const ClassMember({
    required this.name,
    this.visibility = ClassMemberVisibility.none,
    this.type,
    this.isMethod = false,
    this.isStatic = false,
    this.isAbstract = false,
  });

  /// Member name. For methods this includes the parameter list,
  /// e.g. `setName(String name)`.
  final String name;

  /// UML visibility sigil.
  final ClassMemberVisibility visibility;

  /// Declared type: the attribute type, or a method's return type.
  final String? type;

  /// Whether this member is a method rather than an attribute.
  final bool isMethod;

  /// Whether the member carries mermaid's `$` (static) classifier.
  final bool isStatic;

  /// Whether the member carries mermaid's `*` (abstract) classifier.
  final bool isAbstract;

  /// The line as it should be painted inside the class box.
  ///
  /// Mermaid renders attributes as `+name : Type` and methods as
  /// `+name(args) Type`.
  String get displayText {
    final sigil = classMemberVisibilitySymbol(visibility);
    final buffer = StringBuffer(sigil)..write(name);
    if (type != null && type!.isNotEmpty) {
      buffer.write(isMethod ? ' $type' : ' : $type');
    }
    return buffer.toString();
  }
}

/// One class box in a class diagram.
class ClassBox {
  /// Creates a class box.
  const ClassBox({
    required this.id,
    required this.name,
    this.stereotype,
    this.attributes = const [],
    this.methods = const [],
    this.note,
    this.cssClass,
    this.label,
  });

  /// Identifier used by relationship lines and by the layout engine.
  final String id;

  /// Class name shown in the header compartment.
  final String name;

  /// Annotation written as `<<interface>>` / `<<abstract>>` / `<<enumeration>>`.
  final String? stereotype;

  /// Attribute compartment entries.
  final List<ClassMember> attributes;

  /// Method compartment entries.
  final List<ClassMember> methods;

  /// Text of a `note for <class>` attached to this class.
  final String? note;

  /// Class applied via `cssClass` / `class X:::name`.
  final String? cssClass;

  /// Display label set via `class X["Custom Label"]`.
  final String? label;

  /// Header text: the custom label when present, otherwise the name.
  String get displayName => (label != null && label!.isNotEmpty) ? label! : name;

  /// Whether the box renders as an italic, abstract-style header.
  bool get isAbstract =>
      stereotype?.toLowerCase() == 'abstract' ||
      methods.any((m) => m.isAbstract);
}

/// Kind of relationship between two classes.
///
/// Mermaid spells these as `<|--`, `*--`, `o--`, `-->`, `--`, `..>`, `..|>`
/// and `..`.
enum ClassRelationType {
  /// `<|--` — B is a subclass of A.
  inheritance,

  /// `*--` — A is composed of B.
  composition,

  /// `o--` — A aggregates B.
  aggregation,

  /// `-->` — directed association.
  association,

  /// `--` — plain link, no arrow head.
  link,

  /// `..>` — dashed dependency.
  dependency,

  /// `..|>` — dashed realization of an interface.
  realization,

  /// `..` — dashed link, no arrow head.
  dashedLink,
}

/// Everything a class-diagram painter needs beyond the generic node/edge graph.
class ClassDiagramData {
  /// Creates class diagram data.
  const ClassDiagramData({
    required this.classes,
    this.title,
    this.notes = const [],
  });

  /// All class boxes, in declaration order.
  final List<ClassBox> classes;

  /// Optional diagram title from the `title` directive.
  final String? title;

  /// Free-floating notes not attached to a specific class.
  final List<String> notes;

  /// Looks up a class box by its identifier.
  ClassBox? byId(String id) {
    for (final box in classes) {
      if (box.id == id) return box;
    }
    return null;
  }
}
