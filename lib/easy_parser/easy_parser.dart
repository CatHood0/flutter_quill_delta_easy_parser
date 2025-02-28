import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/extensions.dart';
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
  /// * [returnNoSealedCopies] indicates if will need to return a deep copy of the elements to avoid return a [Paragraph]s that cannot add more elements
  /// * [ignoreAllNewLines] indicates that all the new lines with no block-level target to apply will be ignored
  ///
  /// Returns the parsed [Document] instance, or null if the delta is empty.
  Document? parseDelta(
    fq.Delta delta, {
    bool returnNoSealedCopies = false,
    bool ignoreAllNewLines = false,
  }) {
    if (delta.isEmpty) return null;
    _document.clean();
    _isNumberedListActive = false;
    final List<fq.Operation> denormalizedOperations =
        delta.denormalize().operations;
    bool ignoreNewLine = true;
    bool hasNextOp = true;
    int? ignoreNewLineAtIndex = 0;
    for (int index = 0; index < denormalizedOperations.length; index++) {
      final fq.Operation operation = denormalizedOperations.elementAt(index);
      final fq.Operation? nextOp =
          denormalizedOperations.elementAtOrNull(index + 1);
      // a basic check to avoid process retain or delete operations
      if (!operation.isInsert || nextOp != null && !nextOp.isInsert) {
        final type =
            nextOp != null && nextOp.isInsert ? nextOp.key : operation.key;
        throw StateError(
          'Operation at ${nextOp?.isInsert == false ? index + 1 : index} '
          'is "$type" type and parseDelta() only accepts "insert" types',
        );
      }
      ignoreNewLine = operation.data == '\n' && operation.attributes == null;
      hasNextOp = nextOp != null;
      // check if we should ignore the first new line after this operation
      //
      // at this case, we want to avoid something like this:
      //
      // "Paragraph 1, \n, Paragraph 2" => should be parsed to be => "Paragraph 1, Paragraph 2"
      //
      // "Paragraph 1, \n, \n, \n, Paragraph 2" => should be parsed to be => "Paragraph 1, \n, \n, Paragraph 2"
      if (operation.data != '\n' &&
          nextOp?.data == '\n' &&
          nextOp?.attributes == null) {
        ignoreNewLineAtIndex = index + 1;
      }

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
          !hasNextOp) {
        ignoreNewLine = false;
      }

      if (ignoreNewLineAtIndex == index) {
        ignoreNewLineAtIndex = null;
        ignoreNewLine = true;
      }

      if (ignoreAllNewLines) {
        ignoreNewLine = true;
      }

      _parseOperation(
        operation,
        ignoreNewLine,
        hasNextOp,
        ignoreAllNewLines,
      );
    }
    // remove last if needed
    if (_document.paragraphs.isNotEmpty && _document.getLast()!.lines.isEmpty) {
      _document.paragraphs.removeLast();
    }
    if (ignoreAllNewLines) {
      if (_document.getLastSafe().isNewLine) {
        _document.paragraphs.removeLast();
      }
    }
    if (returnNoSealedCopies) {
      return Document(
        paragraphs: _document.paragraphs
            .map(
              (pr) => pr.clone,
            )
            .toList(),
      );
    }
    return _document;
  }

  /// Internal method to parse a single Quill operation.
  void _parseOperation(
    fq.Operation operation, [
    bool ignoreNewLine = true,
    bool hasNextOp = false,
    bool ignoreAllNewLines = false,
  ]) {
    if (operation.data is Map) {
      _insertEmbed(operation, hasNextOp);
    } else if (operation.data == '\n') {
      _insertNewLine(
        operation,
        ignoreNewLine,
        ignoreAllNewLines,
        hasNextOp,
      );
    } else {
      _insertText(operation, hasNextOp);
    }
  }

  /// Starts a new paragraph in the document.
  void _startNewParagraph() => _document.insert(Paragraph.base());

  /// Inserts an embedded object into the document.
  void _insertEmbed(fq.Operation operation, bool hasNextOp) {
    final Paragraph? lastPr = _document.getLast();
    if (lastPr != null && lastPr.lines.isEmpty) {
      lastPr
        ..insert(Line(
          data: operation.data,
          attributes: operation.attributes,
        ))
        ..seal();
      _document.updateParagraph(lastPr);
      _isNumberedListActive = false;
      return;
    }
    _document.insert(Paragraph.fromEmbed(operation)..seal());
    _isNumberedListActive = false;
  }

  /// Handles the insertion of a new line in the document.
  void _insertNewLine(
    fq.Operation operation,
    bool ignoreNewLine,
    bool ignoreAllNewLines,
    bool hasNextOp,
  ) {
    if (operation.attributes != null) {
      Paragraph paragraph = _document.getLastSafe();
      if (paragraph.isEmbed) {
        _document
            .updateParagraph(paragraph..blockAttributes = operation.attributes);
        return;
      }
      // if the last added paragraph is already a block or line-break element
      // we need to add it as another element
      bool needIgnoreUpdate = false;
      if (paragraph.isBlock || paragraph.isNewLine) {
        if (!paragraph.isSealed) {
          _document.updateParagraph(
            paragraph..seal(),
          );
        }
        needIgnoreUpdate = ignoreAllNewLines;
        paragraph = Paragraph(
          lines: [
            Line(data: operation.data),
          ],
          type: ParagraphType.lineBreak,
        )..seal();
      }
      paragraph.blockAttributes = operation.attributes;
      if (!_document.getLastSafe().isEmbed) {
        paragraph.setType(ParagraphType.block);
      }
      if (!needIgnoreUpdate) {
        _document.updateParagraph(paragraph);
      }
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
        paragraph
          ..insert(Line(data: '\n'))
          ..setType(ParagraphType.lineBreak)
          ..seal();
        _document.updateParagraph(paragraph);
        if (hasNextOp) {
          _startNewParagraph();
        }
        return;
      }
      if (!ignoreNewLine || !hasNextOp) {
        final Paragraph paragraph = Paragraph(
          lines: [Line(data: '\n')],
          type: ParagraphType.lineBreak,
        );
        _document.insert(paragraph..seal());
      }
      if (hasNextOp) {
        _startNewParagraph();
      }
    }
  }

  /// Inserts text into the document.
  void _insertText(fq.Operation operation, bool hasNextOp) {
    Paragraph? paragraph = _document.getLast();
    if (paragraph == null ||
        paragraph.type != ParagraphType.inline ||
        paragraph.isSealed) {
      paragraph = Paragraph.base();
    }
    paragraph.insert(
      Line(
        data: operation.data,
        attributes: operation.attributes,
      ),
    );
    _document.updateParagraph(paragraph);
  }
}
