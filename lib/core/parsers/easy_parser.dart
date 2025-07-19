import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// Represents a parser that converts the Quill Delta operations into a structured document format.
@Deprecated('RichTextParser is not longer supported, and '
    'it will be removed in future releases. '
    'Use DocumentParser instead')
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

  /// Parses a Quill Delta into a structured document.
  ///
  /// * [returnNoSealedCopies] indicates if will need to return a deep copy of the elements to avoid return a [Paragraph]s that cannot add more elements
  /// * [ignoreAllNewLines] indicates that all the new lines with no block-level target to apply will be ignored
  ///
  @Deprecated('RichTextParser.parseDelta is not longer supported, and '
      'it will be removed in future releases. '
      'Use DocumentParser.parseDelta instead')
  Document? parseDelta(
    fq.Delta delta, {
    bool returnNoSealedCopies = false,
    bool ignoreAllNewLines = false,
  }) {
    return DocumentParser(mergerBuilder: mergerBuilder).parseDelta(
      delta: delta,
      returnNoSealedCopies: returnNoSealedCopies,
      ignoreAllNewLines: ignoreAllNewLines,
    );
  }
}
