import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

class RichTextParser {
  final Document _document = Document(paragraphs: [], setupInfo: SetupInfo(numberedLists: 0, hyperlinks: []));
  bool _isNumberedListActive = false;
  Map<String, dynamic>? lastAttributes;

  Document? parseDelta(fq.Delta delta) {
    if (delta.isEmpty) return null;
    _document.clean();
    lastAttributes = null;
    _isNumberedListActive = false;
    final List<fq.Operation> denormalizedOperations = delta.fullDenormalizer().operations;
    bool wasPreviousNewLine = false;
    bool ignoreNewLine = false;
    for (int index = 0; index < denormalizedOperations.length; index++) {
      ignoreNewLine = true;
      final fq.Operation operation = denormalizedOperations.elementAt(index);
      final nextOp = denormalizedOperations.elementAtOrNull(index + 1);
      // Verify first if the current if a line with just a new line before the last one that is the definitive block attribute
      //
      // An example of this could be
      // { "insert": "\n", { "header": 1 } }, { "insert": "\n", { "header": 1 } }, { "insert": "Text block breaker" }
      // When verify that the next operation has not the same attrs, then will ignore that new line since
      // that one is the definitive (it was the unique insert with the block attribute, but
      // denormalizer makes this to do more easy store on it)
      if (nextOp != null && mapEquality(operation.attributes, nextOp.attributes)) {
        ignoreNewLine = false;
      }
      _parseOperation(operation, wasPreviousNewLine, ignoreNewLine);
      wasPreviousNewLine = operation.data == '\n';
    }
    return _document.ensureCorrectFormat();
  }

  void _parseOperation(fq.Operation operation, [bool wasPreviousNewLine = false, bool ignoreNewLine = true]) {
    if (operation.data is Map) {
      if ((operation.data as Map)['formula'] != null) {
        _insertFormula(operation);
      } else {
        _insertEmbed(operation, wasPreviousNewLine);
      }
    } else if (operation.data == '\n') {
      _insertNewLine(operation, ignoreNewLine);
    } else {
      _insertText(operation);
    }
  }

  void _startNewParagraph({fq.Operation? operation}) {
    _document.insert(Paragraph(lines: [if (operation != null) Line(data: operation.data)]));
  }

  void _insertEmbed(fq.Operation operation, bool asNewParagraph) {
    if (asNewParagraph) {
      _document.insert(Paragraph.fromEmbed(operation));
    } else {
      _document.paragraphs[_document.paragraphs.length - 1]
          .insert(Line(data: operation.data, attributes: operation.attributes));
    }
    _isNumberedListActive = false;
    if (asNewParagraph) {
      _startNewParagraph();
    }
  }

  void _insertFormula(fq.Operation operation) {
    if (_document.paragraphs.isEmpty) {
      _startNewParagraph();
    }
    _document.insert(Paragraph.fromEmbed(operation));
  }

  void _insertNewLine(fq.Operation operation, bool ignoreNewLine) {
    if (operation.attributes != null) {
      _document.paragraphs[_document.paragraphs.length - 1].blockAttributes = operation.attributes;
      _document.paragraphs[_document.paragraphs.length - 1].type = ParagraphType.block;
      if (operation.attributes?['list'] == 'ordered') {
        if (!_isNumberedListActive) {
          _document.setupInfo?.numberedLists++;
          _isNumberedListActive = true;
        }
      } else {
        _isNumberedListActive = false;
      }
    }
    _startNewParagraph(operation: ignoreNewLine ? null : operation);
  }

  void _insertText(fq.Operation operation) {
    if (_document.paragraphs.isEmpty) {
      _startNewParagraph();
    }
    if (operation.attributes != null) {
      _document.paragraphs[_document.paragraphs.length - 1]
          .insert(Line(data: operation.data, attributes: operation.attributes));
      if (operation.attributes?['link'] != null) {
        _document.setupInfo?.hyperlinks
            .add(QHyperLink(text: operation.data as String, link: operation.attributes?['link']!));
      }
    } else {
      _document.paragraphs[_document.paragraphs.length - 1].insert(Line(data: operation.data as String));
    }
  }
}
