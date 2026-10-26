/// Maps analyzer elements to source positions.
library;

import 'package:analyzer/dart/element/element.dart';

import '../errors.dart';

/// Returns where [element] is declared, or `null` when it has no position.
///
/// Synthetic and unnamed elements have no position.
SourceLocation? locationOf(Element? element) {
  if (element == null) return null;
  final fragment = element.firstFragment;
  final offset = fragment.nameOffset;
  final unit = fragment.libraryFragment;
  if (offset == null || unit == null) return null;
  final position = unit.lineInfo.getLocation(offset);
  return SourceLocation(
    file: unit.source.fullName,
    line: position.lineNumber,
    column: position.columnNumber,
  );
}

/// A readable name for an annotated element, such as `TodoRoutes.list`.
String elementLabel(Element element) {
  final enclosing = element.enclosingElement;
  if (enclosing is InterfaceElement && element.name != null) {
    return '${enclosing.name}.${element.name}';
  }
  return element.displayName;
}
