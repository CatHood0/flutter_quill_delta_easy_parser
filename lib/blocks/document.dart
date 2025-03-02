import 'package:collection/collection.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// Represents a structured document consisting of paragraphs.
class Document {
  /// List of paragraphs contained within the document.
  final List<Paragraph> paragraphs;

  Document({
    required Iterable<Paragraph> paragraphs,
  }) : paragraphs = <Paragraph>[] {
    for (var pr in paragraphs) {
      insert(pr);
    }
  }

  /// Inserts a new [paragraph] into the document.
  void insert(Paragraph paragraph) {
    final Paragraph? lastParagraph = paragraphs.lastOrNull;
    if (lastParagraph != null) {
      if (lastParagraph.isEmpty || (lastParagraph.last?.isEmpty ?? false)) {
        lastParagraph.insertAll(paragraph.lines);
        lastParagraph.setType(paragraph.type);
        lastParagraph.blockAttributes = lastParagraph.blockAttributes;
        if((lastParagraph.isBlock || lastParagraph.isEmbed || lastParagraph.isNewLine) && !lastParagraph.isSealed) {
          lastParagraph.seal(sealLines: true);
        }
        updateLast(paragraph);
        return;
      }
    }
    paragraphs.add(paragraph);
  }

  void updateParagraphSafe(Paragraph paragraph) {
    if (exist(paragraph)) {
      updateParagraph(paragraph);
      return;
    }
    paragraphs.add(paragraph);
  }

  /// Returns the last [paragraph] into the document and validate before to avoid exceptions.
  Paragraph getLastSafe() {
    if (paragraphs.isEmpty) Paragraph.base();
    return paragraphs.last;
  }

  /// Returns the last [paragraph] into the document.
  Paragraph? getLast({Paragraph Function()? orElse}) {
    return paragraphs.lastOrNull ?? orElse?.call();
  }

  /// Returns a [bool] value that indicates if the [Paragraph] exists into the [Document].
  bool exist(Paragraph pr) {
    if (paragraphs.isEmpty) return false;
    return paragraphs.contains(pr) || paragraphs.firstWhereOrNull((e) => e.id == pr.id) != null;
  }

  /// Update a last [paragraph] into the document validating to make more safe the operation.
  void updateLastSafe(Paragraph paragraph) {
    if (paragraphs.isEmpty) {
      paragraphs.add(paragraph);
      return;
    }
    paragraphs[paragraphs.length - 1] = paragraph;
  }

  Paragraph? getParagraph(Paragraph paragraph) {
    if (paragraphs.isEmpty) return null;
    return paragraphs.firstWhereOrNull((pr) => pr.id == paragraph.id || pr == paragraph);
  }

  Paragraph? getParagraphBefore(Paragraph paragraph) {
    if (paragraphs.isEmpty) return null;
    final int index = paragraphs.indexWhere((pr) => pr.id == paragraph.id || pr == paragraph);
    if (index <= 0) return null;
    return paragraphs.elementAt(index - 1);
  }

  Paragraph? getParagraphAfter(Paragraph paragraph) {
    if (paragraphs.isEmpty) return null;
    final int index = paragraphs.indexWhere((pr) => pr.id == paragraph.id || pr == paragraph);
    if (index < 0 && (index + 1) >= paragraphs.length) return null;
    return paragraphs.elementAt(index + 1);
  }

  /// Update a [paragraph] into the document validating to make more safe the operation.
  void updateParagraph(Paragraph paragraph) {
    int lastIndex = paragraphs.lastIndexOf(paragraph);
    // make a second check to be sure that it does exist or not
    if (lastIndex == -1 && paragraphs.isNotEmpty) {
      lastIndex = paragraphs.indexWhere((pr) => pr.id == paragraph.id);
    }
    if (paragraphs.isEmpty || lastIndex == -1) {
      throw StateError('Not found element of type ${paragraph.runtimeType} with id: ${paragraph.id}');
    }
    paragraphs[lastIndex] = paragraph;
  }

  /// Update a last [paragraph] into the document.
  void updateLast(Paragraph paragraph) {
    paragraphs[paragraphs.length - 1] = paragraph;
  }

  /// Clears all paragraphs from the document.
  void clean() {
    paragraphs.clear();
  }

  /// Ensures correct formatting of paragraphs in the document.
  @Deprecated('ensureCorrectFormat is no longer used and will be removed in future releases')
  Document ensureCorrectFormat() {
    return this;
  }

  /// Returns a string representation of the document.
  @override
  String toString() {
    return 'Paragraphs: ${paragraphs.map((paragraph) => paragraph.toString()).toList().toString()}';
  }

  /// Returns a version of the string that can be readed more easily.
  String toPrettyString() {
    final StringBuffer buffer = StringBuffer('  Paragraph:\n');
    final String rawParagraph = paragraphs.map((Paragraph paragraph) {
      for (final Line line in paragraph.lines) {
        buffer.writeln('  ${line.toPrettyString(indent: '  ')}');
      }
      final String attrStr = paragraph.blockAttributes != null
          ? 'Paragraph Attributes: ${paragraph.blockAttributes ?? <String, dynamic>{}}'
          : "";
      final String typeStr = 'Type: ${paragraph.type.name}';
      if (attrStr.isNotEmpty) {
        buffer.write('    $attrStr\n');
      }
      if (typeStr.isNotEmpty) {
        buffer.write('    $typeStr\n');
      }
      final String str = '$buffer';
      buffer
        ..clear()
        ..write('  Paragraph:\n');
      return str;
    }).join();
    return 'Document:\n$rawParagraph';
  }

  @override
  bool operator ==(covariant Document other) {
    if (identical(this, other)) return true;
    return ListEquality().equals(paragraphs, other.paragraphs);
  }

  @override
  int get hashCode => Object.hashAll(paragraphs);
}
