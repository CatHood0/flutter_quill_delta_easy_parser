// ignore_for_file: must_be_immutable

import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:equatable/equatable.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

/// Represents a paragraph consisting of lines of text or embedded content with optional attributes.
///
/// This class encapsulates the structure of a paragraph, which can contain multiple lines
/// and may have associated block-level attributes and a specific paragraph type.
///
/// The [lines] property holds a list of [Line] objects representing individual lines within
/// the paragraph.
///
/// The [type] property specifies the type of paragraph, if any, such as normal text or an embedded content.
///
/// The [blockAttributes] property is a map that can hold additional attributes specific to the paragraph block.
///
/// Example usage:
/// ```dart
/// Paragraph paragraph = Paragraph(
///   lines: [
///     Line(data: 'First line'),
///     Line(data: 'Second line'),
///   ],
///   type: ParagraphType.block,
///   blockAttributes: {'indent': 2,'alignment': 'right'},
/// );
///
/// paragraph.insert(Line(data: 'Third line'));
/// paragraph.setType(ParagraphType.block);
///
/// ```
class Paragraph extends Equatable {
  /// List of lines composing the paragraph.
  final List<Line> lines;

  /// The type of the paragraph.
  ///
  /// This can be used to distinguish between different types of paragraphs, such as normal text or embedded content.
  ParagraphType? type;

  /// Additional attributes specific to the paragraph block.
  ///
  /// This map can hold any additional metadata or styling information related to the paragraph.
  Map<String, dynamic>? blockAttributes;

  /// Constructs a [Paragraph] instance with required properties.
  ///
  /// [lines] specifies the list of lines within the paragraph.
  ///
  /// [type] is an optional parameter that defines the type of the paragraph.
  ///
  /// [blockAttributes] is an optional map that holds additional attributes for the paragraph block.
  Paragraph({
    required this.lines,
    this.blockAttributes,
    this.type,
  });

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

  /// Inserts a new line into the paragraph.
  ///
  /// [line] is the line to be inserted into the paragraph.
  ///
  /// Throws an exception if the data type of [line] is not a string or a map.
  void insert(Line line) {
    if (line.data is String || line.data is Map) {
      lines.add(line);
      return;
    }
    throw Exception(
        'Invalid data type. Expected a String or Map for line data, but got ${line.data.runtimeType}.');
  }

  /// Removes a line from the paragraph at the specified index.
  ///
  /// [index] is the index of the line to be removed.
  void removeLine(int index) {
    lines.removeAt(index);
  }

  /// Sets the type of the paragraph.
  ///
  /// [lineType] specifies the type of the paragraph to be set.
  void setType(ParagraphType? lineType) {
    type = lineType;
  }

  /// Sets the type of the paragraph if it hasn't been set already.
  ///
  /// [lineType] specifies the type of the paragraph to be set, if not already set.
  void setTypeSafe(ParagraphType? lineType) {
    if (type != null) return;
    type = lineType;
  }

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
  ///
  /// Returns a new [Paragraph] instance with identical lines, block attributes, and type.
  Paragraph get clone {
    return Paragraph(
        lines: [...lines], blockAttributes: {...?blockAttributes}, type: type);
  }

  @override
  String toString() {
    return 'Paragraph: {Lines: ${lines.map<String>((line) => line.toString().replaceAll('\n', '\\n')).toList().toString()} // Block Attributes: $blockAttributes // Type: ${type?.name}}';
  }

  @override
  List<Object?> get props => [lines, blockAttributes, type];
}
