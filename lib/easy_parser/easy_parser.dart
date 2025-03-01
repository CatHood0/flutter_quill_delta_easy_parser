import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/extensions.dart';
import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// Represents a parser that converts the Quill Delta operations into a structured document format.
class RichTextParser {
  RichTextParser({
    this.mergerBuilder = const CommonMergerBuilder(),
  });

  
  /// This is the encharge to merge some paragraphs when they contains the same block attributes
  /// or when contains same types.
  ///
  /// Default implementations:
  ///
  ///  1. [NoMergeBuilder]: don't do nothing
  ///  2. [CommonMergerBuilder] (default merge behavior): check if the [Paragraph] can be merged. It's focused on merge general [Paragraph] (even if them are pure inline types) 
  ///  3. [BlockMergerBuilder]: check just if the [Paragraph]s with block-attributes can be merge into a same one. 
  ///
  /// Example:
  ///
  /// ```dart
  /// // to ignore merging behavior 
  /// final parser1 = RichTextParser(mergerBuilder: NoMergeBuilder())
  /// // to merge [Paragraph]s if them can do it 
  /// final parser2 = RichTextParser(mergerBuilder: CommonMergerBuilder())
  /// // to only merge blocks
  /// final parser3 = RichTextParser(mergerBuilder: BlockMergerBuilder())
  /// ```
  final MergerBuilder mergerBuilder;
  final Document _document = Document(
    paragraphs: [],
  );

  /// Parses a Quill Delta into a structured document.
  ///
  /// * [returnNoSealedCopies] indicates if will need to return a deep copy of the elements to avoid return a [Paragraph]s that cannot add more elements
  /// * [ignoreAllNewLines] indicates that all the new lines with no block-level target to apply will be ignored
  ///
  Document? parseDelta(
    fq.Delta delta, {
    bool returnNoSealedCopies = false,
    bool ignoreAllNewLines = false,
  }) {
    if (delta.isEmpty) return null;
    _document.clean();
    final List<fq.Operation> denormalizedOperations = delta.denormalize().operations;
    bool ignoreNewLine = true;
    bool hasNextOp = true;
    int? ignoreNewLineAtIndex;
    // sometimes, we can find only new lines at the start of the Delta, then to avoid remove them, we
    // will need to add a verification
    bool startParagraphNewLineChecking = false;
    Map<String, dynamic>? lastBlockAttributesKnown;
    for (int index = 0; index < denormalizedOperations.length; index++) {
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
      if (!startParagraphNewLineChecking) {
        startParagraphNewLineChecking = operation.data != '\n';
      }

      if(operation.data == '\n' && !startParagraphNewLineChecking) {
        _document.insert(Paragraph.newLine());
        continue;
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
      if (operation.data != '\n' && nextOp?.data == '\n' && nextOp?.attributes == null) {
        ignoreNewLineAtIndex = index + 1;
      }
      if (operation.data == '\n' && operation.attributes == null && nextOp != null && nextOp.data != '\n') {
        ignoreNewLine = true;
        ignoreNewLineAtIndex = null;
      }

      // Verify first if the current if a line with just a new line before the last one that is the definitive block attribute
      // _It also ensure to validate if the current operation is just a simple new line_
      //
      // An example of this could be
      // { "insert": "\n", { "header": 1 } }, { "insert": "\n", { "header": 1 } }, { "insert": "Text block breaker" }
      // When verify that the next operation has not the same attrs, then will ignore that new line since
      // that one is the definitive (it was the unique insert with the block attribute, but
      // denormalizer makes this to do more easy store on it)
      if (nextOp != null && mapEquality(operation.attributes, nextOp.attributes) || !hasNextOp) {
        ignoreNewLine = false;
      }

      if (ignoreNewLineAtIndex == index) {
        ignoreNewLineAtIndex = null;
        ignoreNewLine = true;
      }

      if (ignoreAllNewLines) {
        ignoreNewLine = true;
      }

      // current op is last
      if (nextOp == null) {
        _insertNewLine(
          operation,
          nextOp,
          false,
          ignoreAllNewLines,
          false,
          false,
        );
        break;
      }

      _parseOperation(
        operation,
        nextOp,
        ignoreNewLine,
        hasNextOp,
        ignoreAllNewLines,
        nextOp.data == '\n' && nextOp.attributes != null,
      );

      final Paragraph? lastPr = _document.getLast();
      if (lastPr == null) {
        lastBlockAttributesKnown = null;
        continue;
      }
      if (lastBlockAttributesKnown != null &&
          operation.data == '\n' &&
          !mapEquality(lastBlockAttributesKnown, lastPr.blockAttributes)) {
        lastPr.seal();
        _document.updateLast(lastPr);
        _startNewParagraph();
      } else if (operation.data == '\n') {
        lastBlockAttributesKnown = operation.attributes == null ? null : {...?operation.attributes};
      }
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
    if (mergerBuilder.enabled) {
      final List<Paragraph> paragraphs = <Paragraph>[..._document.paragraphs];
      _document.clean();
      final Iterable<Paragraph> newParagraphs = mergerBuilder.buildAccumulation(
        paragraphs,
      );
      _document.paragraphs.addAll(newParagraphs);
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
    fq.Operation operation,
    fq.Operation? nextOperation, [
    bool ignoreNewLine = true,
    bool hasNextOp = false,
    bool ignoreAllNewLines = false,
    bool nextIsBlockLevelAttributes = false,
  ]) {
    if (operation.data is Map) {
      _insertEmbed(operation, hasNextOp);
    } else if (operation.data == '\n') {
      _insertNewLine(
        operation,
        nextOperation,
        ignoreNewLine,
        ignoreAllNewLines,
        hasNextOp,
        nextIsBlockLevelAttributes,
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
        ..insert(Line.fromData(
          data: operation.data!,
          attributes: operation.attributes,
        ))
        ..seal();
      _document.updateParagraph(lastPr);
      return;
    }
    if (lastPr != null && lastPr.lines.isNotEmpty && lastPr.lines.first.isEmpty) {
      lastPr
        ..updateLine(
            0,
            Line.fromData(
              data: operation.data!,
              attributes: operation.attributes,
            ))
        ..seal();
      _document.updateParagraph(lastPr);
      return;
    }
    _document.insert(Paragraph.fromEmbed(operation));
  }

  /// Handles the insertion of a new line in the document.
  void _insertNewLine(
    fq.Operation operation,
    fq.Operation? nextOperation,
    bool ignoreNewLine,
    bool ignoreAllNewLines,
    bool hasNextOp,
    bool nextIsBlockLevelAttributes,
  ) {
    if (operation.attributes != null) {
      Paragraph? paragraph = _document.getLast();
      if (paragraph == null) {
        _document.insert(Paragraph.newLine());
        return;
      }
      if (paragraph.isSealed) {
        _startNewParagraph();
      }
      if (paragraph.isEmbed || paragraph.isTextInsert) {
        if (paragraph.isTextInsert) {
          paragraph.setType(ParagraphType.block);
        }
        if (nextIsBlockLevelAttributes) {
          paragraph.seal();
        }
        _document.updateParagraph(paragraph..blockAttributes = operation.attributes);
        return;
      }
      // if the last added paragraph is already a block or line-break element
      // we need to add it as another element
      bool needIgnoreUpdate = false;
      if (paragraph.isSealed) {
        needIgnoreUpdate = ignoreAllNewLines;
        paragraph = Paragraph.newLine();
      }
      if (!needIgnoreUpdate) {
        paragraph.blockAttributes = operation.attributes;
        if (!_document.getLastSafe().isEmbed) {
          if (!paragraph.isNewLine) {
            paragraph.setType(ParagraphType.block);
          }
        }
        if (_document.getLastSafe().isEmpty) {
          _document.updateLastSafe(paragraph);
          return;
        }
        _document.updateParagraph(paragraph);
      }
      return;
    } else {
      Paragraph? paragraph = _document.getLast();
      paragraph ??= Paragraph.base();
      // if we have a paragraph that is currently empty, we use it instead create a new one
      if (paragraph.isEmpty) {
        paragraph
          ..insert(Line.newLine())
          ..setType(ParagraphType.lineBreak)
          ..seal();
        _document.getLast()?.seal();
        _document.updateParagraphSafe(paragraph);
        _startNewParagraph();
        return;
      }
      if (!ignoreNewLine || !hasNextOp) {
        _document.getLast()?.seal();
        bool needNewParagraph = false;
        if (paragraph.last != null && paragraph.last!.isEmpty) {
          paragraph.removeLastLine();
          paragraph.last?.seal();
          needNewParagraph = true;
        }
        if (paragraph.isEmbed || paragraph.isNewLine || paragraph.isSealed || !hasNextOp) {
          final Paragraph newLine = Paragraph.newLine();
          _document.insert(newLine);
          return;
        }
        final Paragraph newLine = Paragraph.newLine();
        _document.insert(newLine);
        if (needNewParagraph) {
          _startNewParagraph();
        }
        return;
      }
      if (nextIsBlockLevelAttributes) {
        _document.updateParagraphSafe(paragraph..seal());
      }
      // next is only a new line
      if (!nextIsBlockLevelAttributes && nextOperation?.data == '\n' && !paragraph.isTextInsert) {
        paragraph.seal();
        _document.updateParagraph(paragraph);
        return;
      }
      if (ignoreNewLine && hasNextOp && !nextIsBlockLevelAttributes) {
        paragraph.last?.seal();
        _document.updateParagraphSafe(paragraph);
        if (nextOperation?.data == '\n' && nextOperation?.attributes == null) {
          if (_document.getLast()?.last?.isEmpty ?? false) {
            _document.getLast()?.removeLastLine();
          }
          _startNewParagraph();
        }
        return;
      }
    }
  }

  /// Inserts text into the document.
  void _insertText(fq.Operation operation, bool hasNextOp) {
    Paragraph? paragraph = _document.getLast();
    if (paragraph == null || paragraph.isSealed) {
      paragraph = Paragraph.base();
      _document.insert(paragraph);
    }
    if (paragraph.isEmpty || (paragraph.last!.isSealed && paragraph.last!.isNotEmpty)) {
      paragraph.insert(Line(
        fragments: [],
      ));
    }
    paragraph.insertTextFragment(
      TextFragment(
        data: operation.data,
        attributes: operation.attributes,
      ),
    );
    _document.updateParagraph(paragraph);
  }
}
