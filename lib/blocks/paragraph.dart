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
  final List<Line> _lines;

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
    required List<Line> lines,
    required this.type,
    this.blockAttributes,
  })  : _lines = List<Line>.from(lines),
        id = nanoid(8),
        _sealed =
            lines.isNotEmpty && lines.length == 1 && lines.first.isNotEmpty
                ? lines.first.length > 1
                    ? false
                    : lines.single.isNewLine || lines.single.isEmbedFragment
                : false;

  factory Paragraph.withLine() {
    return Paragraph(
      lines: <Line>[
        Line(
          fragments: [],
        ),
      ],
      type: ParagraphType.inline,
    );
  }

  factory Paragraph.base() {
    return Paragraph(
      lines: <Line>[],
      type: ParagraphType.inline,
    );
  }

  factory Paragraph.newLine({Map<String, dynamic>? blockAttributes}) {
    return Paragraph(
      lines: <Line>[
        Line.newLine(),
      ],
      blockAttributes: blockAttributes,
      type: ParagraphType.lineBreak,
    )..seal();
  }

  /// Constructs a [Paragraph] instance from a Object embed.
  /// [operation] is the Quill Delta operation representing the embed.
  factory Paragraph.fromRawEmbed(
      {required Object data,
      Map<String, dynamic>? attributes,
      Map<String, dynamic>? blockAttributes}) {
    return Paragraph(
      lines: <Line>[
        Line.fromData(data: data, attributes: attributes),
      ],
      blockAttributes: blockAttributes,
      type: data is String
          ? blockAttributes != null
              ? ParagraphType.block
              : ParagraphType.inline
          : ParagraphType.embed,
    )..seal();
  }

  /// Constructs a [Paragraph] instance from a Quill Delta embed operation.
  ///
  /// This factory method creates a paragraph with a single line from the provided embed operation.
  ///
  /// [operation] is the Quill Delta operation representing the embed.
  factory Paragraph.fromEmbed(fq.Operation operation) {
    return Paragraph(
      lines: <Line>[
        Line.fromData(data: operation.data!, attributes: operation.attributes),
      ],
      type:
          operation.data is String ? ParagraphType.inline : ParagraphType.embed,
    )..seal();
  }

  List<Line> get lines => List<Line>.unmodifiable(_lines);
  Line? get last => _lines.lastOrNull;
  Line? get first => _lines.firstOrNull;
  int get length => _lines.length;
  bool get isEmpty => _lines.isEmpty;
  bool get isNotEmpty => !isEmpty;
  bool get isBlock => type == ParagraphType.block && blockAttributes != null;
  bool get isEmbed =>
      type == ParagraphType.embed && lines.first.isEmbedFragment;
  bool get isNewLine =>
      type == ParagraphType.lineBreak && lines.single.isNewLine;
  @Deprecated('Use isTextInsert')
  bool get isInsertText => type == ParagraphType.inline;
  bool get isTextInsert => type == ParagraphType.inline;
  bool get isSealed => _sealed;
  bool containsSameAttributes(Map<String, dynamic>? attrs) {
    return mapEquality(blockAttributes, attrs);
  }

  void seal() {
    _sealed = true;
  }

  void insertEmptyLine() {
    if (_sealed) {
      throw StateError('Cannot be inserted when $runtimeType is sealed');
    }
    if (_lines.isNotEmpty) {
      _lines.last.seal();
    }
    _lines.add(Line(fragments: []));
  }

  /// Inserts a new Line into the paragraph.
  void insert(Line line) {
    if (_sealed) {
      throw StateError(
          'Element of type ${line.runtimeType} cannot be inserted when $runtimeType is sealed');
    }
    _lines.add(line);
  }

  void updateLine(int index, Line line) {
    if (_sealed) {
      throw StateError(
          'Element of type ${line.runtimeType} at $index cannot be updated when $runtimeType is sealed');
    }
    _lines[index] = line;
  }

  void insertTextFragment(TextFragment fragment) {
    if (_sealed) {
      throw StateError(
          'Element of type ${fragment.runtimeType} cannot be inserted when $runtimeType is sealed');
    }
    _lines[_lines.length - 1].addFragment(fragment);
  }

  /// Removes last line from the paragraph.
  void removeLastLine() {
    if (_sealed) {
      throw StateError(
          'Cannot be removed the Element at ${_lines.length - 1} when $runtimeType is sealed');
    }
    _lines.removeLast();
  }

  /// Removes a line from the paragraph at the specified index.
  ///
  /// [index] is the index of the line to be removed.
  void removeLine(int index) {
    if (_sealed) {
      throw StateError(
          'Cannot be removed the Element at $index when $runtimeType is sealed');
    }
    _lines.removeAt(index);
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
  @Deprecated(
      'setTypeSafe is no longer used and will be removed in future releases.')
  void setTypeSafe(ParagraphType? lineType) {}

  /// Sets additional attributes for the paragraph block.
  ///
  /// [attrs] is a map containing the additional attributes to be set.
  void setAttributes(Map<String, dynamic>? attrs) {
    blockAttributes = attrs;
  }

  /// Clears all lines from the paragraph.
  void clean() {
    _lines.clear();
  }

  /// Creates a clone of the current paragraph.
  Paragraph get clone {
    return Paragraph(
      lines: [..._lines],
      blockAttributes: blockAttributes == null ? null : {...blockAttributes!},
      type: type,
    );
  }

  @override
  String toString() {
    return 'Paragraph: {'
        'id: $id, '
        'Lines: ${lines.map<String>((line) => line.toString()).toList().toString()} '
        '${blockAttributes != null ? 'Paragraph Attributes: $blockAttributes' : ""} '
        'Type: ${type.name}, '
        'Sealed: $_sealed'
        '}';
  }

  String toPrettyString({String indent = ' '}) {
    final StringBuffer buffer = StringBuffer(indent);
    final String rawFragments = _lines.map((Line line) {
      buffer.writeln('${'$indent  '}${line.toString().replaceAll('\n', '¶')},');
      final String str = '$buffer';
      buffer
        ..clear()
        ..write(indent);
      return str;
    }).join();
    return '${indent}Paragraph: [\n$rawFragments${'$indent  '}]';
  }

  @override
  bool operator ==(covariant Paragraph other) {
    if (identical(this, other)) return true;
    return id == other.id &&
        ListEquality().equals(lines, other.lines) &&
        type == other.type &&
        MapEquality().equals(
          blockAttributes,
          other.blockAttributes,
        );
  }

  @override
  int get hashCode => Object.hash(lines, blockAttributes, type, id);
}
