import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:meta/meta.dart';

/// Accumulator is a base class that give to us some methods that let us build
@immutable
abstract class MergerBuilder {
  const MergerBuilder();

  /// Indicates the block-level keys to take in account to accumulate
  List<String>? get keysToAccumulate;

  /// Decides if we will merge the current Pr ↓ with the nextParagraph
  bool get enabled => keysToAccumulate != null && keysToAccumulate!.isNotEmpty;
  bool canMergeBothParagraphs({required Paragraph paragraph, required Paragraph nextParagraph});

  Iterable<Paragraph> buildAccumulation(List<Paragraph> paragraphs);
}

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
  bool canMergeBothParagraphs({required Paragraph paragraph, required Paragraph nextParagraph}) {
    if (_paragraphIsNewLine(paragraph) || _paragraphIsNewLine(nextParagraph)) {
      return false;
    }
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

  bool _paragraphIsNewLine(Paragraph pr) {
    return pr.isNewLine;
  }

  @override
  List<String>? get keysToAccumulate => null;
}
