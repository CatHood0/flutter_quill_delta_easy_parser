import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

/// [CommonMergerBuilder] is focused in merge paragraphs with the same block-attributes or if them are inlines
/// and accept also merge embeds if [mergeEmbeds] param is true
@immutable
class CommonMergerBuilder extends MergerBuilder {
  const CommonMergerBuilder({this.mergeEmbeds = false});

  final bool mergeEmbeds;

  @override
  List<Paragraph> buildAccumulation(List<Paragraph> paragraphs) {
    final List<Paragraph> result = <Paragraph>[];
    final Set<int> indexsIgnore = <int>{};
    for (int i = 0; i < paragraphs.length; i++) {
      final Paragraph curParagraph = paragraphs.elementAt(i);
      final Paragraph? nextParagraph = paragraphs.elementAtOrNull(i + 1);
      if (indexsIgnore.contains(i)) {
        continue;
      }
      // check if the current iteration is the last
      if (nextParagraph == null) {
        result.add(curParagraph);
        break;
      }
      if (canMergeBothParagraphs(paragraph: curParagraph, nextParagraph: nextParagraph)) {
        final Paragraph paragraphResult = Paragraph(
          lines: <Line>[
            ...curParagraph.lines,
            ...nextParagraph.lines,
          ],
          blockAttributes: curParagraph.blockAttributes,
          type: curParagraph.type,
        );
        result.add(paragraphResult);
        indexsIgnore.add(i + 1);
        continue;
      }
      result.add(curParagraph);
    }
    indexsIgnore.clear();
    return <Paragraph>[...result];
  }

  @override
  bool get enabled => true;

  @override
  bool canMergeBothParagraphs({
    required Paragraph paragraph,
    required Paragraph nextParagraph,
  }) {
    return paragraph.isTextInsert && nextParagraph.isTextInsert ||
        (paragraph.isBlock) &&
            nextParagraph.isBlock &&
            mapEquality(
              paragraph.blockAttributes,
              nextParagraph.blockAttributes,
            ) ||
        mergeEmbeds &&
            (paragraph.isBlock) &&
            nextParagraph.isBlock &&
            mapEquality(
              paragraph.blockAttributes,
              nextParagraph.blockAttributes,
              true,
            );
  }
}
