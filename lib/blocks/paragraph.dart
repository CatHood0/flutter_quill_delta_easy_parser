// ignore_for_file: must_be_immutable

import 'package:dart_quill_delta/dart_quill_delta.dart' as fq;
import 'package:equatable/equatable.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

class Paragraph extends Equatable {
  final List<Line> lines;
  ParagraphType? type;
  Map<String, dynamic>? blockAttributes;

  Paragraph({
    required this.lines,
    this.blockAttributes,
    this.type,
  });

  factory Paragraph.fromEmbed(fq.Operation operation) {
    return Paragraph(
      lines: [
        Line(data: operation.data, attributes: operation.attributes),
      ],
      type: ParagraphType.embed,
    );
  }

  void insert(Line line) {
    if (line.data is String || line.data is Map) {
      lines.add(line);
      return;
    }
    throw Exception(
        'Unique valid data type are a { "attributes" } or a string. The value type: ${line.data.runtimeType} isn\'t valid');
  }

  void removeLine(int index) {
    lines.removeAt(index);
  }

  void setType(ParagraphType? lineType) {
    type = lineType;
  }

  void setTypeSafe(ParagraphType? lineType) {
    if (type != null) return;
    type = lineType;
  }

  void setAttributes(Map<String, dynamic>? attrs) {
    blockAttributes = attrs;
  }

  void clean() {
    lines.clear();
  }

  Paragraph get clone {
    return Paragraph(lines: [...lines], blockAttributes: {...?blockAttributes}, type: type);
  }

  @override
  String toString() {
    return 'Paragraph: {Lines: ${lines.map<String>((line) => line.toString().replaceAll('\n', '\\n')).toList().toString()} // Block Attributes: $blockAttributes // Type: ${type?.name}}';
  }

  @override
  List<Object?> get props => [lines, blockAttributes, type];
}
