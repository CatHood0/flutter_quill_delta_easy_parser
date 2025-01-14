// ignore_for_file: must_be_immutable
import 'package:equatable/equatable.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// Represents a structured document consisting of paragraphs.
class Document extends Equatable {
  /// List of paragraphs contained within the document.
  final List<Paragraph> paragraphs;

  /// Optional setup information for the document.
  SetupInfo? setupInfo;

  Document({
    required this.paragraphs,
    this.setupInfo,
  });

  /// Inserts a new [paragraph] into the document.
  void insert(Paragraph paragraph) {
    paragraphs.add(paragraph);
  }

  /// Returns the last [paragraph] into the document and validate before to avoid exceptions.
  Paragraph getLastSafe() {
    if (paragraphs.isEmpty) paragraphs.add(Paragraph(lines: []));
    return paragraphs.last;
  }

  /// Returns the last [paragraph] into the document.
  Paragraph? getLast() {
    return paragraphs.lastOrNull;
  }

  /// Update a last [paragraph] into the document validating to make more safe the operation.
  void updateLastSafe(Paragraph paragraph) {
    if (paragraphs.isEmpty) {
      paragraphs.add(paragraph);
      return;
    }
    paragraphs[paragraphs.length - 1] = paragraph;
  }

  /// Update a last [paragraph] into the document.
  void updateLast(Paragraph paragraph) {
    paragraphs[paragraphs.length - 1] = paragraph;
  }

  /// Clears all paragraphs from the document.
  void clean() {
    paragraphs.clear();
  }

  /// Removes all empty paragraphs from the document.
  ///
  /// TODO: Deprecated due to upcoming fixes needed.
  @Deprecated('This must not be used since is not used yet. It will be removed in future releases')
  Document removeAllEmptyParagraphs() {
    paragraphs.removeWhere((element) => element.lines.isEmpty);
    return this;
  }

  /// Ensures correct formatting of paragraphs in the document.
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

  /// Returns a list of properties used for equality comparison.
  @override
  List<Object?> get props => [setupInfo, paragraphs];
}
