import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/extensions.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// A Easy-to-use converter that transform Quill Delta into a Document formatting.
class DocumentParser {
  DocumentParser({
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
  Document? parseDelta({
    required fq.Delta delta,
    bool returnNoSealedCopies = false,
    bool ignoreAllNewLines = false,
  }) {
    if (delta.isEmpty) return null;
    _document.clean();
    final List<fq.Operation> denormalizedOperations =
        delta.denormalize().operations;
    // sometimes, we can find only new lines at the start of the Delta, then to avoid remove them, we
    // will need to add a verification
    bool startParagraphNewLineChecking = false;
    final it = denormalizedOperations.iterator;
    int index = 0;
    while (it.moveNext()) {
      final fq.Operation? previousOperation =
          index == 0 ? null : denormalizedOperations.elementAtOrNull(index - 1);
      final fq.Operation operation = it.current;
      final fq.Operation? nextOp =
          denormalizedOperations.elementAtOrNull(index + 1);
      _checkOperation(index, operation);
      if (nextOp != null) _checkOperation(index, nextOp);

      if (ignoreAllNewLines &&
          operation.data == '\n' &&
          operation.attributes == null) {
        continue;
      }

      if (!startParagraphNewLineChecking) {
        startParagraphNewLineChecking = operation.data != '\n';
      }

      if (operation.data == '\n' &&
          !startParagraphNewLineChecking &&
          !ignoreAllNewLines) {
        _document
            .insert(Paragraph.newLine(blockAttributes: operation.attributes));
        index++;
        continue;
      }

      final bool isParagraphBreak =
          previousOperation?.data != '\n' && operation.data == '\n';
      final bool isBlankLine =
          previousOperation?.data == '\n' && operation.data == '\n';

      final bool hasNextOp = nextOp != null;
      final bool isLastInsertion = isParagraphBreak && !hasNextOp;

      // updates here
      index++;

      if (operation.data is! String) {
        _applyEmbed(operation: operation);
      } else if (operation.data == '\n') {
        _applyNewLine(
          operation: operation,
          isBlankLine: isBlankLine,
          ignoreAllNewLines: ignoreAllNewLines,
          isParagraphBreak: isParagraphBreak,
          isLastInsertion: isLastInsertion,
        );
      } else {
        _applyText(operation, hasNextOp);
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

  void _applyEmbed({required fq.Operation operation}) {
    _document.insert(Paragraph.fromEmbed(operation));
  }

  void _applyNewLine({
    required fq.Operation operation,
    required bool isBlankLine,
    required bool ignoreAllNewLines,
    required bool isParagraphBreak,
    required bool isLastInsertion,
  }) {
    Paragraph? lastParagraph = _document.getLast();
    if (lastParagraph == null) {
      lastParagraph = Paragraph.withLine();
      _document.insert(lastParagraph);
    }
    if (isBlankLine) {
      if (lastParagraph.shouldBreakToNext) {
        lastParagraph.removeLastLine();
        lastParagraph.seal(sealLines: true);
        _document.updateLast(lastParagraph);
      }
      if (!ignoreAllNewLines) {
        _document
            .insert(Paragraph.newLine(blockAttributes: operation.attributes));
      }
    } else if (isLastInsertion && operation.attributes == null) {
      if (!ignoreAllNewLines) {
        _document
            .insert(Paragraph.newLine(blockAttributes: operation.attributes));
      }
    } else if (isParagraphBreak) {
      if (lastParagraph.length > 1 &&
          operation.attributes != null &&
          !lastParagraph.shouldBreakToNext) {
        lastParagraph.unseal();
        final Line lastLine = lastParagraph.removeLastLine();
        lastParagraph.seal(sealLines: true);
        _document.updateLast(lastParagraph);
        _document.insert(
          Paragraph(
            lines: [lastLine],
            blockAttributes: operation.attributes,
            type: ParagraphType.block,
          ),
        );
        return;
      }
      if (operation.attributes != null) {
        lastParagraph.blockAttributes = operation.attributes;
        if (lastParagraph.isTextInsert) {
          lastParagraph.setType(ParagraphType.block);
        }
        lastParagraph.seal(sealLines: true);
        _document.updateParagraph(lastParagraph);
        _startNewParagraph();
        return;
      }
      if (!ignoreAllNewLines) {
        lastParagraph.insertEmptyLine();
      }
    }
  }

  /// Starts a new paragraph in the document.
  void _startNewParagraph() => _document.insert(Paragraph.base());

  /// Inserts text into the document.
  void _applyText(fq.Operation operation, bool hasNextOp) {
    Paragraph? paragraph = _document.getLast();
    if (paragraph == null || paragraph.isSealed) {
      paragraph = Paragraph.base();
      _document.insert(paragraph);
    }
    if (paragraph.isEmpty ||
        (paragraph.last!.isSealed && paragraph.last!.isNotEmpty)) {
      paragraph.insert(Line(
        fragments: [],
      ));
    }
    paragraph.insertTextFragment(
      TextFragment(
        data: operation.data!,
        attributes: operation.attributes,
      ),
    );
    _document.updateParagraph(paragraph);
  }

  void _checkOperation(int index, fq.Operation operation) {
    // a basic check to avoid process retain or delete operations
    if (!operation.isInsert) {
      throw StateError(
        'Operation at $index '
        'is "${operation.key}" type and parseDelta() only accepts: "insert" type',
      );
    }
  }
}
