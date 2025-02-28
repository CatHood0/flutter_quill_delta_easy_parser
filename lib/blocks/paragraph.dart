import 'package:collection/collection.dart';
import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';

/// Represents a paragraph consisting of lines of text or embedded content with optional attributes.
///
/// This class encapsulates the structure of a paragraph, which can contain multiple lines
/// and may have associated block-level attributes and a specific paragraph type.
///
/// * [lines] property holds a list of [Line] objects representing individual lines within
/// the paragraph.
/// * [type] property specifies the type of paragraph, if any, such as normal text or an embedded content.
/// * [blockAttributes] property is a map that can hold additional attributes specific to the paragraph block.
///
/// Example usage:
/// ```dart
/// Paragraph paragraph = Paragraph(
///   lines: [
///     Line(data: 'First line'),
///     Line(data: 'Second line'),
///   ],
///   blockAttributes: {'indent': 2,'align': 'right'},
///   type: ParagraphType.block,
/// );
///
/// paragraph.insert(Line(data: 'Third line'));
/// paragraph.setType(ParagraphType.block);
///
/// // if after the insert, you want to avoid another types of 
/// // changes in this paragraph use:
/// paragraph.seal();
/// if(paragraph.isSealed) {
///  // do something
/// }
/// ```
class Paragraph {
  /// List of lines composing the paragraph.
  final List<Line> lines;

  /// The type of the paragraph.
  ///
  /// This can be used to distinguish between different types of paragraphs, such as normal text or embedded content.
  ParagraphType type;

  /// Additional attributes specific to the paragraph block.
  ///
  /// This map can hold any additional metadata or styling information related to the paragraph.
  Map<String, dynamic>? blockAttributes;

  /// Indicates if the paragraph can insert new elements
  bool _sealed;

  final String id;

  Paragraph({
    required this.lines,
    required this.type,
    this.blockAttributes,
  }) : id = nanoid(8), _sealed = false;

  factory Paragraph.base() {
    return Paragraph(
      lines: [],
      type: ParagraphType.inline,
    );
  }

  factory Paragraph.newLine() {
    return Paragraph(
      lines: [
        Line(data: '\n'),
      ],
      type: ParagraphType.lineBreak,
    );
  }

  /// Constructs a [Paragraph] instance from a Quill Delta embed operation.
  ///
  /// This factory method creates a paragraph with a single line from the provided embed operation.
  ///
  /// [operation] is the Quill Delta operation representing the embed.
  factory Paragraph.fromEmbed(fq.Operation operation) {
    return Paragraph(
      lines: [
        Line(data: operation.data, attributes: operation.attributes),
      ],
      type: ParagraphType.embed,
    );
  }

  bool get isBlock => type == ParagraphType.block && blockAttributes != null;
  bool get isEmbed => type == ParagraphType.embed && lines.single.data is Map<String, dynamic>;
  bool get isNewLine => type == ParagraphType.lineBreak && lines.single.data == '\n';
  @Deprecated('Use isTextInsert')
  bool get isInsertText => type == ParagraphType.inline;
  bool get isTextInsert => type == ParagraphType.inline;
  bool get isSealed => _sealed;
  bool containsSameAttributes(Map<String, dynamic>? attrs) {
    return mapEquality(blockAttributes, attrs);
  }

  void seal() => _sealed = true;

  /// Inserts a new Line into the paragraph.
  ///
  /// [line] is the line to be inserted into the paragraph.
  ///
  /// Throws an exception if the data type of [line] is not a string or a map.
  void insert(Line line) {
    if (_sealed) {
      throw StateError('Element of type ${line.runtimeType} cannot be inserted when $runtimeType is sealed');
    }
    if (line.data is String || line.data is Map) {
      if (line.data is String) {
        _mergeWithTail(line);
        return;
      }
      lines.add(line);
      return;
    }
    throw Exception(
        'Invalid data type. Expected a String or Map for line data, but got ${line.data.runtimeType}.');
  }

  void _mergeWithTail(Line line) {
    final Line? previous = lines.lastOrNull;
    void add() {
      lines.add(line);
    }

    if (previous == null ||
        previous.data is! String ||
        line.data is! String ||
        '${previous.data}'.endsWith('\n') ||
        '${line.data}'.endsWith('\n')) {
      add();
      return;
    }
    final int lastIndex = lines.length - 1;
    final bool areAttributesEquals = mapEquality(previous.attributes, line.attributes) ||
        (previous.attributes == null && line.attributes == null);
    if (areAttributesEquals) {
      final String previousData = previous.data as String;
      final String newData = '$previousData${line.data}';
      lines[lastIndex] = Line(
        data: newData,
        attributes: previous.attributes,
      );
      return;
    }
    add();
  }

  /// Removes a line from the paragraph at the specified index.
  ///
  /// [index] is the index of the line to be removed.
  void removeLine(int index) {
    if (_sealed) {
      throw StateError('Cannot be removed the Element at $index when $runtimeType is sealed');
    }
    lines.removeAt(index);
  }

  /// Sets the type of the paragraph.
  ///
  /// [lineType] specifies the type of the paragraph to be set.
  void setType(ParagraphType lineType) {
    type = lineType;
  }

  /// Sets the type of the paragraph if it hasn't been set already.
  ///
  /// [lineType] specifies the type of the paragraph to be set, if not already set.
  @Deprecated('setTypeSafe is no longer used and will be removed in future releases.')
  void setTypeSafe(ParagraphType? lineType) {}

  /// Sets additional attributes for the paragraph block.
  ///
  /// [attrs] is a map containing the additional attributes to be set.
  void setAttributes(Map<String, dynamic>? attrs) {
    blockAttributes = attrs;
  }

  /// Clears all lines from the paragraph.
  void clean() {
    lines.clear();
  }

  /// Creates a clone of the current paragraph.
  Paragraph get clone {
    return Paragraph(
      lines: [...lines],
      blockAttributes: blockAttributes == null ? null : {...blockAttributes!},
      type: type,
    );
  }

  @override
  String toString() {
    return 'Paragraph: {'
        'id: $id, '
        'Lines: ${lines.map<String>((line) => line.toString().replaceAll('\n', '\\n')).toList().toString()} '
        '${blockAttributes != null ? 'Paragraph Attributes: $blockAttributes' : ""} '
        'Type: ${type.name}, '
        'Sealed: $_sealed'
        '}';
  }

  @override
  bool operator ==(covariant Paragraph other) {
    if (identical(this, other)) return true;
    return id == other.id && ListEquality().equals(lines, other.lines) &&
        type == other.type &&
        MapEquality().equals(
          blockAttributes,
          other.blockAttributes,
        );
  }

  @override
  int get hashCode => Object.hash(lines, blockAttributes, type, id);
}
