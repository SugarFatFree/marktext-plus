/// Data models for requirement diagrams
library;

/// The kinds of requirement mermaid defines.
enum RequirementKind {
  requirement('Requirement'),
  functionalRequirement('Functional Requirement'),
  interfaceRequirement('Interface Requirement'),
  performanceRequirement('Performance Requirement'),
  physicalRequirement('Physical Requirement'),
  designConstraint('Design Constraint');

  const RequirementKind(this.label);

  /// Shown in the box header, as mermaid renders it.
  final String label;

  /// The keyword that introduces this kind, matching how it is written.
  static RequirementKind? fromKeyword(String keyword) {
    switch (keyword.toLowerCase()) {
      case 'requirement':
        return RequirementKind.requirement;
      case 'functionalrequirement':
        return RequirementKind.functionalRequirement;
      case 'interfacerequirement':
        return RequirementKind.interfaceRequirement;
      case 'performancerequirement':
        return RequirementKind.performanceRequirement;
      case 'physicalrequirement':
        return RequirementKind.physicalRequirement;
      case 'designconstraint':
        return RequirementKind.designConstraint;
      default:
        return null;
    }
  }
}

/// How likely a requirement is to cause trouble.
enum RequirementRisk {
  low('Low'),
  medium('Medium'),
  high('High');

  const RequirementRisk(this.label);

  final String label;

  static RequirementRisk? fromName(String name) {
    switch (name.toLowerCase()) {
      case 'low':
        return RequirementRisk.low;
      case 'medium':
        return RequirementRisk.medium;
      case 'high':
        return RequirementRisk.high;
      default:
        return null;
    }
  }
}

/// How a requirement is to be checked.
enum VerifyMethod {
  analysis('Analysis'),
  inspection('Inspection'),
  test('Test'),
  demonstration('Demonstration');

  const VerifyMethod(this.label);

  final String label;

  static VerifyMethod? fromName(String name) {
    switch (name.toLowerCase()) {
      case 'analysis':
        return VerifyMethod.analysis;
      case 'inspection':
        return VerifyMethod.inspection;
      case 'test':
        return VerifyMethod.test;
      case 'demonstration':
        return VerifyMethod.demonstration;
      default:
        return null;
    }
  }
}

/// A requirement box.
class Requirement {
  const Requirement({
    required this.name,
    required this.kind,
    this.id,
    this.text,
    this.risk,
    this.verifyMethod,
  });

  /// The identifier used on relationship lines, and the box's title.
  final String name;

  final RequirementKind kind;

  /// The user's own numbering, shown as a row in the box.
  final String? id;

  /// What the requirement says.
  final String? text;

  final RequirementRisk? risk;

  final VerifyMethod? verifyMethod;

  /// The rows drawn under the header, in mermaid's order, omitting any the
  /// source did not give.
  List<(String, String)> get rows => [
        if (id != null) ('Id', id!),
        if (text != null) ('Text', text!),
        if (risk != null) ('Risk', risk!.label),
        if (verifyMethod != null) ('Verification', verifyMethod!.label),
      ];
}

/// An element: something real that satisfies or verifies requirements.
class RequirementElement {
  const RequirementElement({
    required this.name,
    this.type,
    this.docRef,
  });

  final String name;

  /// What sort of thing it is, free text in mermaid.
  final String? type;

  /// Where it is documented.
  final String? docRef;

  List<(String, String)> get rows => [
        if (type != null) ('Type', type!),
        if (docRef != null) ('Doc Ref', docRef!),
      ];
}

/// The ways a requirement can relate to another node.
enum RequirementRelationKind {
  contains('contains'),
  copies('copies'),
  derives('derives'),
  satisfies('satisfies'),
  verifies('verifies'),
  refines('refines'),
  traces('traces');

  const RequirementRelationKind(this.label);

  final String label;

  static RequirementRelationKind? fromName(String name) {
    final wanted = name.trim().toLowerCase();
    for (final kind in RequirementRelationKind.values) {
      if (kind.label == wanted) return kind;
    }
    return null;
  }
}

/// One relationship line.
class RequirementRelation {
  const RequirementRelation({
    required this.source,
    required this.target,
    required this.kind,
  });

  /// The end the arrow points away from.
  final String source;

  /// The end the arrow points at.
  final String target;

  final RequirementRelationKind kind;
}

/// A parsed requirement diagram.
class RequirementDiagramData {
  const RequirementDiagramData({
    required this.requirements,
    required this.elements,
    required this.relations,
  });

  final List<Requirement> requirements;
  final List<RequirementElement> elements;
  final List<RequirementRelation> relations;

  /// The requirement named [name], or null.
  Requirement? requirementByName(String name) {
    for (final requirement in requirements) {
      if (requirement.name == name) return requirement;
    }
    return null;
  }

  /// The element named [name], or null.
  RequirementElement? elementByName(String name) {
    for (final element in elements) {
      if (element.name == name) return element;
    }
    return null;
  }

  /// Header text and rows for the box named [name], or null when nothing of
  /// that name was declared.
  ({String title, String? subtitle, List<(String, String)> rows})? boxFor(
      String name) {
    final requirement = requirementByName(name);
    if (requirement != null) {
      return (
        title: requirement.name,
        subtitle: requirement.kind.label,
        rows: requirement.rows,
      );
    }
    final element = elementByName(name);
    if (element != null) {
      return (title: element.name, subtitle: 'Element', rows: element.rows);
    }
    return null;
  }
}

/// Colours used when drawing a requirement diagram.
class RequirementDiagramColors {
  RequirementDiagramColors._();

  static const int boxFill = 0xFFF3F6FB;
  static const int boxBorder = 0xFF6B7A90;
  static const int headerFill = 0xFFE1E8F2;
  static const int textColor = 0xFF1F2933;
  static const int labelColor = 0xFF52606D;
  static const int edgeColor = 0xFF6B7A90;
}
