import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// A class responsible for parsing Quill Delta operations into a structured document format.
class RichTextParser {
  final Document _document = Document(
      paragraphs: [], setupInfo: SetupInfo(numberedLists: 0, hyperlinks: []));
  bool _isNumberedListActive = false;

  /// Parses a Quill Delta into a structured document.
  ///
  /// Returns the parsed [Document] instance, or null if the delta is empty.
  Document? parseDelta(fq.Delta delta) {
    if (delta.isEmpty) return null;
    _document.clean();
    _isNumberedListActive = false;
    final List<fq.Operation> denormalizedOperations =
        delta.fullDenormalizer().operations;
    bool wasPreviousNewLine = false;
    bool ignoreNewLine = false;
    for (int index = 0; index < denormalizedOperations.length; index++) {
      ignoreNewLine = true;
      final fq.Operation operation = denormalizedOperations.elementAt(index);
      final nextOp = denormalizedOperations.elementAtOrNull(index + 1);

      // Verify first if the current if a line with just a new line before the last one that is the definitive block attribute
      // _It also ensure to validate if the current operation is just a simple new line_
      //
      // An example of this could be
      // { "insert": "\n", { "header": 1 } }, { "insert": "\n", { "header": 1 } }, { "insert": "Text block breaker" }
      // When verify that the next operation has not the same attrs, then will ignore that new line since
      // that one is the definitive (it was the unique insert with the block attribute, but
      // denormalizer makes this to do more easy store on it)
      if (nextOp != null &&
              mapEquality(operation.attributes, nextOp.attributes) ||
          operation.data == '\n' && operation.attributes == null) {
        ignoreNewLine = false;
      }

      _parseOperation(operation, wasPreviousNewLine, ignoreNewLine);
      wasPreviousNewLine = operation.data == '\n';
    }

    return _document.ensureCorrectFormat();
  }

  /// Internal method to parse a single Quill operation.
  void _parseOperation(fq.Operation operation,
      [bool wasPreviousNewLine = false, bool ignoreNewLine = true]) {
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

  /// Starts a new paragraph in the document.
  void _startNewParagraph({fq.Operation? operation}) {
    _document.insert(
        Paragraph(lines: [if (operation != null) Line(data: operation.data)]));
  }

  /// Inserts an embedded object into the document.
  void _insertEmbed(fq.Operation operation, bool wasPreviousNewLine) {
    if (wasPreviousNewLine || _document.paragraphs.isEmpty) {
      _document.insert(Paragraph.fromEmbed(operation));
    } else {
      final paragraph = _document.getLastSafe();
      paragraph
          .insert(Line(data: operation.data, attributes: operation.attributes));
      _document.updateLastSafe(paragraph);
    }
    _isNumberedListActive = false;
    if (wasPreviousNewLine) {
      _startNewParagraph();
    }
  }

  /// Inserts a formula block into the document.
  void _insertFormula(fq.Operation operation) {
    if (_document.paragraphs.isEmpty) {
      _startNewParagraph();
    }
    _document.insert(Paragraph.fromEmbed(operation));
  }

  /// Handles the insertion of a new line in the document.
  void _insertNewLine(fq.Operation operation, bool ignoreNewLine) {
    if (operation.attributes != null) {
      final paragraph = _document.getLastSafe();
      paragraph.blockAttributes = operation.attributes;
      paragraph.setTypeSafe(ParagraphType.block);
      _document.updateLastSafe(paragraph);
      if (operation.attributes?['list'] == 'ordered') {
        if (!_isNumberedListActive) {
          _document.setupInfo?.numberedLists++;
          _isNumberedListActive = true;
        }
      } else {
        _isNumberedListActive = false;
      }
    } else {
      if (_document.getLast() != null && _document.getLast()!.lines.isEmpty) {
        final paragraph = _document.getLastSafe();
        paragraph.insert(Line(data: '\n'));
        paragraph.setType(ParagraphType.block);
        _document.updateLastSafe(paragraph);
        return;
      }
    }
    _startNewParagraph(operation: ignoreNewLine ? null : operation);
  }

  /// Inserts text into the document.
  void _insertText(fq.Operation operation) {
    if (_document.paragraphs.isEmpty) {
      _startNewParagraph();
    }
    final paragraph = _document.getLast()!;
    if (operation.attributes != null) {
      paragraph
          .insert(Line(data: operation.data, attributes: operation.attributes));
      if (operation.attributes?['link'] != null) {
        _document.setupInfo?.hyperlinks.add(QHyperLink(
            text: operation.data as String,
            link: operation.attributes?['link']!));
      }
    } else {
      paragraph.insert(Line(data: operation.data as String));
    }
    _document.updateLastSafe(paragraph);
  }
}
