import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

/// [NoMergeBuilder] does not accumulate nothing and return the paragraphs as are generated
@immutable
class NoMergeBuilder extends MergerBuilder {
  const NoMergeBuilder();
  @override
  List<Paragraph> buildAccumulation(List<Paragraph> paragraphs) => <Paragraph>[...paragraphs];

  @override
  List<String>? get keysToAccumulate => null;

  @override
  bool get enabled => false;

  @override
  bool canMergeBothParagraphs({required Paragraph paragraph, required Paragraph nextParagraph}) => false;
}
