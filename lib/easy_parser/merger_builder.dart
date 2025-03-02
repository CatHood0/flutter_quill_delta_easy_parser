import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

/// Accumulator is a base class that give to us some methods that let us build
@immutable
abstract class MergerBuilder {
  const MergerBuilder();

  bool get enabled;
  /// Decides if we will merge the current Pr ↓ with the nextParagraph
  bool canMergeBothParagraphs({required Paragraph paragraph, required Paragraph nextParagraph});

  Iterable<Paragraph> buildAccumulation(List<Paragraph> paragraphs);
}
