import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

// Note: If you want to see how can look the [Document]s, take a look the test folder
/// Represents a parser that converts the Quill Delta operations into a structured document format.
class RichTextParser {
  final Document _document = Document(
    paragraphs: [],
  );
  bool _isNumberedListActive = false;

  /// Parses a Quill Delta into a structured document.
  ///
  /// Returns the parsed [Document] instance, or null if the delta is empty.
  Document? parseDelta(fq.Delta delta) {
    if (delta.isEmpty) return null;
    _document.clean();
    _isNumberedListActive = false;
    final List<fq.Operation> denormalizedOperations = delta.fullDenormalizer().operations;
    bool wasPreviousNewLine = false;
    bool ignoreNewLine = false;
    bool hasNextOp = true;
    for (int index = 0; index < denormalizedOperations.length; index++) {
      ignoreNewLine = true;
      final fq.Operation operation = denormalizedOperations.elementAt(index);
      final fq.Operation? nextOp = denormalizedOperations.elementAtOrNull(index + 1);
      // a basic check to avoid process retain or delete operations
      if (!operation.isInsert || nextOp != null && !nextOp.isInsert) {
        final type = nextOp != null && nextOp.isInsert ? nextOp.key : operation.key;
        throw StateError(
          'Operation at ${nextOp?.isInsert == false ? index + 1 : index} '
          'is "$type" type and parseDelta() only accepts "insert" types',
        );
      }
      hasNextOp = nextOp != null;

      // Verify first if the current if a line with just a new line before the last one that is the definitive block attribute
      // _It also ensure to validate if the current operation is just a simple new line_
      //
      // An example of this could be
      // { "insert": "\n", { "header": 1 } }, { "insert": "\n", { "header": 1 } }, { "insert": "Text block breaker" }
      // When verify that the next operation has not the same attrs, then will ignore that new line since
      // that one is the definitive (it was the unique insert with the block attribute, but
      // denormalizer makes this to do more easy store on it)
      if (nextOp != null && mapEquality(operation.attributes, nextOp.attributes) ||
          operation.data == '\n' && operation.attributes == null ||
          !hasNextOp) {
        ignoreNewLine = false;
      }

      _parseOperation(
        operation,
        wasPreviousNewLine,
        ignoreNewLine,
        hasNextOp,
      );
      wasPreviousNewLine =
          operation.data == '\n' || '${operation.data}'.startsWith('\n') || '${operation.data}'.endsWith('\n');
    }
    // remove last if needed
    if (_document.paragraphs.isNotEmpty && _document.getLast()!.lines.isEmpty) {
      _document.paragraphs.removeLast();
    }
    return _document;
  }

  /// Internal method to parse a single Quill operation.
  void _parseOperation(
    fq.Operation operation, [
    bool wasPreviousNewLine = false,
    bool ignoreNewLine = true,
    bool hasNextOp = false,
  ]) {
    if (operation.data is Map) {
      _insertEmbed(operation, wasPreviousNewLine, hasNextOp);
    } else if ('${operation.data}'.contains('\n') || operation.data == '\n') {
      _insertNewLine(operation, ignoreNewLine, hasNextOp);
    } else {
      _insertText(operation, hasNextOp);
    }
  }

  /// Starts a new paragraph in the document.
  void _startNewParagraph({fq.Operation? operation}) {
    bool isNewLine = operation?.data == '\n';
    bool hasNewLine = '${operation?.data}'.startsWith('\n') || '${operation?.data}'.endsWith('\n');
    final Paragraph builtInPr = Paragraph(
      lines: [
        if (operation != null) Line(data: operation.data),
      ],
      blockAttributes: isNewLine ? operation?.attributes : null,
      type: (hasNewLine || isNewLine) && operation?.attributes != null
          ? ParagraphType.block
          : (hasNewLine || isNewLine)
              ? ParagraphType.lineBreak
              : ParagraphType.inline,
    );
    _document.insert(builtInPr);
    if (builtInPr.type == ParagraphType.lineBreak || builtInPr.type == ParagraphType.block) {
      _startNewParagraph();
    }
  }

  /// Inserts an embedded object into the document.
  void _insertEmbed(fq.Operation operation, bool wasPreviousNewLine, bool hasNextOp) {
    _document.insert(Paragraph.fromEmbed(operation));
    _isNumberedListActive = false;
  }

  /// Handles the insertion of a new line in the document.
  void _insertNewLine(fq.Operation operation, bool ignoreNewLine, bool hasNextOp) {
    if (operation.attributes != null) {
      Paragraph paragraph = _document.getLastSafe();
      if (paragraph.isEmbed) {
        _document.updateLastSafe(paragraph..blockAttributes = operation.attributes);
        return;
      }
      // if the last added paragraph is already a block or line-break element
      // we need to add it as another element
      bool needsTypeRedefinition = true;
      if (paragraph.isBlock || paragraph.isNewLine) {
        needsTypeRedefinition = false;
        paragraph = Paragraph(lines: [
          Line(data: operation.data),
        ], type: ParagraphType.lineBreak);
      }
      paragraph.blockAttributes = operation.attributes;
      if (!_document.getLastSafe().isEmbed && needsTypeRedefinition) {
        paragraph.setType(ParagraphType.block);
      }
      _document.updateLastSafe(paragraph);
      if (operation.attributes?['list'] == 'ordered') {
        if (!_isNumberedListActive) {
          _isNumberedListActive = true;
        }
      } else {
        _isNumberedListActive = false;
      }
      return;
    } else {
      // if we have a paragraph that is currently empty, we use it instead create a new one
      if (_document.getLast() != null && _document.getLast()!.lines.isEmpty) {
        final Paragraph paragraph = _document.getLastSafe();
        paragraph.insert(Line(data: '\n'));
        paragraph.setType(ParagraphType.lineBreak);
        _document.updateLastSafe(paragraph);
        if (hasNextOp) {
          _startNewParagraph();
        }
        return;
      }
      final Paragraph paragraph = Paragraph(
        lines: [Line(data: '\n')],
        type: ParagraphType.lineBreak,
      );
      _document.insert(paragraph);
      if (hasNextOp) {
        _startNewParagraph();
      }
    }
  }

  /// Inserts text into the document.
  void _insertText(fq.Operation operation, bool hasNextOp) {
    if (_document.paragraphs.isEmpty) {
      _startNewParagraph();
    }
    Paragraph paragraph = _document.getLast()!;
    if (paragraph.type != ParagraphType.inline) {
      paragraph = Paragraph.base();
    }
    paragraph.insert(
      Line(
        data: operation.data,
        attributes: operation.attributes,
      ),
    );
    _document.updateLastSafe(paragraph);
  }
}
