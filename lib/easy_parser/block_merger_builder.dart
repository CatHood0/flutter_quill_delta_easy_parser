import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

/// [BlockMergerBuilder] is focused in merge only paragraphs with the same block-attributes
@immutable
class BlockMergerBuilder extends MergerBuilder {
  const BlockMergerBuilder();
  @override
  List<Paragraph> buildAccumulation(List<Paragraph> paragraphs) => <Paragraph>[...paragraphs];

  @override
  bool get enabled => true;

  @override
  bool canMergeBothParagraphs({required Paragraph paragraph, required Paragraph nextParagraph}) {
    return false;
  }

  @override
  List<String>? get keysToAccumulate => <String>[
        'list',
        'blockquote',
        'code-block',
        'codeblock',
      ];
}
