import 'package:collection/collection.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// Represents a structured document consisting of paragraphs.
class Document {
  /// List of paragraphs contained within the document.
  final List<Paragraph> paragraphs;

  Document({
    required this.paragraphs,
  });

  /// Inserts a new [paragraph] into the document.
  void insert(Paragraph paragraph) {
    paragraphs.add(paragraph);
  }

  /// Returns the last [paragraph] into the document and validate before to avoid exceptions.
  Paragraph getLastSafe() {
    if (paragraphs.isEmpty) paragraphs.add(Paragraph.base());
    return paragraphs.last;
  }

  /// Returns the last [paragraph] into the document.
  Paragraph? getLast({Paragraph Function()? orElse}) {
    return paragraphs.lastOrNull ?? orElse?.call();
  }

  /// Update a last [paragraph] into the document validating to make more safe the operation.
  void updateLastSafe(Paragraph paragraph) {
    if(paragraphs.isEmpty) {
      paragraphs.add(paragraph);
      return;
    }
    paragraphs[paragraphs.length - 1] = paragraph;
  }

  /// Update a [paragraph] into the document validating to make more safe the operation.
  void updateParagraph(Paragraph paragraph) {
    int lastIndex = paragraphs.lastIndexOf(paragraph);
    // make a second check to be sure that it does exist or not
    if (lastIndex == -1 && paragraphs.isNotEmpty) {
      lastIndex = paragraphs.indexWhere((pr) => pr.id == paragraph.id);
    }
    if (paragraphs.isEmpty || lastIndex == -1) {
      paragraphs.add(paragraph);
      return;
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
    final List<Paragraph> newParagraphs = [];
    for (int index = 0; index < paragraphs.length; index++) {
      final Paragraph paragraph = paragraphs.elementAt(index);
      if (paragraph.lines.isNotEmpty) {
        final Line line = paragraph.lines.first;
        if (line.data == '\n' && paragraph.lines.length > 1) {
          newParagraphs.add(Paragraph(lines: [Line(data: '\n')], type: ParagraphType.block));
          paragraph.removeLine(0);
          paragraph.setTypeSafe(paragraph.blockAttributes != null ? ParagraphType.block : ParagraphType.inline);
          newParagraphs.add(paragraph.clone);
        } else {
          if (line.data == '\n' && paragraph.blockAttributes == null && paragraph.lines.length == 1) {
            paragraph.setType(ParagraphType.block);
          }
          if (paragraph.blockAttributes != null) {
            paragraph.setTypeSafe(ParagraphType.block);
          } else {
            paragraph.setTypeSafe(ParagraphType.inline);
          }
          newParagraphs.add(paragraph);
        }
      } else if (paragraph.lines.isEmpty) {
        paragraph.insert(Line(data: '\n'));
        paragraph.setTypeSafe(ParagraphType.block);
        newParagraphs.add(paragraph);
      }
    }
    clean();
    paragraphs.addAll([...newParagraphs]);
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
        buffer.writeln('    $line');
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
