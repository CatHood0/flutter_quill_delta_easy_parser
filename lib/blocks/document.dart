// ignore_for_file: must_be_immutable
import 'package:equatable/equatable.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

class Document extends Equatable {
  final List<Paragraph> paragraphs;
  SetupInfo? setupInfo;

  Document({
    required this.paragraphs,
    this.setupInfo,
  });

  void insert(Paragraph paragraph) {
    paragraphs.add(paragraph);
  }

  void clean() {
    paragraphs.clear();
  }

  //TODO: deprecate these functions since we need to fix this
  Document removeAllEmptyParagraphs() {
    paragraphs.removeWhere((element) => element.lines.isEmpty);
    return this;
  }

  //TODO: deprecate these functions since we need to fix this
  Document ensureCorrectFormat() {
    final List<Paragraph> newParagraphs = [];
    for (int index = 0; index < paragraphs.length; index++) {
      final Paragraph paragraph = paragraphs.elementAt(index);
      if (paragraph.lines.isNotEmpty) {
        final Line line = paragraph.lines.first;
        if (line.data == '\n' && paragraph.blockAttributes != null && paragraph.lines.length > 1) {
          newParagraphs.add(Paragraph(lines: [Line(data: '\n')], type: ParagraphType.inline));
          paragraph.removeLine(0);
          paragraph.setTypeSafe(ParagraphType.inline);
          newParagraphs.add(paragraph.clone);
        } else {
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

  @override
  String toString() {
    return 'Paragraphs: ${paragraphs.map((paragraph) => paragraph.toString()).toList().toString()}';
  }

  @override
  // TODO: implement props
  List<Object?> get props => [setupInfo, paragraphs];
}
