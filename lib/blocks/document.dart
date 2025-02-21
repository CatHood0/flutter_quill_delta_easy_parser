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
    final formattedPrs = _formatParagraph(paragraph);
    if (formattedPrs.isEmpty) {
      paragraphs.add(paragraph);
      return;
    }
    paragraphs.addAll(formattedPrs);
  }

  /// Returns the last [paragraph] into the document and validate before to avoid exceptions.
  Paragraph getLastSafe() {
    if (paragraphs.isEmpty) paragraphs.add(Paragraph.base());
    return paragraphs.last;
  }

  /// Returns the last [paragraph] into the document.
  Paragraph? getLast() {
    return paragraphs.lastOrNull;
  }

  /// Update a last [paragraph] into the document validating to make more safe the operation.
  void updateLastSafe(Paragraph paragraph) {
    final int lastIndex = paragraphs.lastIndexOf(paragraph);
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

  Iterable<Paragraph> _formatParagraph(Paragraph paragraph) {
    final List<Paragraph> newParagraphs = [];
    if (paragraph.lines.isNotEmpty) {
      final Line line = paragraph.lines.first;
      if (line.data == '\n' && paragraph.lines.length > 1) {
        newParagraphs.add(
          Paragraph(
            lines: [Line(data: '\n')],
            type: ParagraphType.lineBreak,
          ),
        );
        paragraph.removeLine(0);
        if (paragraph.lines.isNotEmpty) {
          paragraph.setTypeSafe(paragraph.blockAttributes != null ? ParagraphType.block : ParagraphType.inline);
          newParagraphs.add(paragraph.clone);
        }
      } else {
        if (line.data == '\n' && paragraph.blockAttributes == null && paragraph.lines.length == 1) {
          paragraph.setType(ParagraphType.lineBreak);
        }
        if (paragraph.blockAttributes != null) {
          paragraph.setTypeSafe(ParagraphType.block);
        } else if (paragraph.type != ParagraphType.lineBreak) {
          paragraph.setTypeSafe(ParagraphType.inline);
        }
        newParagraphs.add(paragraph);
      }
    }
    return newParagraphs;
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
    return 'Document:\n'
            '${paragraphs.map((Paragraph paragraph) {
      for (final Line line in paragraph.lines) {
        buffer.write('    $line\n');
      }
      final String attrStr =
          paragraph.blockAttributes != null ? 'Paragraph Attributes: ${paragraph.blockAttributes}' : "";
      final String typeStr = paragraph.type != null ? 'Type: ${paragraph.type?.name}' : '';
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
    })}'
        .replaceAll(RegExp(r',|\.|\(|\)'), '');
  }

  @override
  bool operator ==(covariant Document other) {
    if (identical(this, other)) return true;
    return ListEquality().equals(paragraphs, other.paragraphs);
  }

  @override
  int get hashCode => Object.hashAll(paragraphs);
}
