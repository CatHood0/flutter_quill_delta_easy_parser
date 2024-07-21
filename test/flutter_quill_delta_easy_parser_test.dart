import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Should convert image to paragraph embed', () {
    final Delta delta = Delta()
      ..insert({'image': '/device/user/to/path/file.jpg'})
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph(
        lines: [
          Line(data: {'image': '/device/user/to/path/file.jpg'}),
        ],
        type: ParagraphType.embed,
      ),
      Paragraph(
        lines: [
          Line(data: '\n'),
        ],
        type: ParagraphType.block,
      ),
    ]);

    final Document? parsedDocument = RichTextParser().parseDelta(delta);
    expect(
        parsedDocument?.paragraphs.length, expectedDocument.paragraphs.length);

    for (int i = 0; i < expectedDocument.paragraphs.length; i++) {
      expect(parsedDocument?.paragraphs[i].lines.length,
          expectedDocument.paragraphs[i].lines.length);
      for (int j = 0; j < expectedDocument.paragraphs[i].lines.length; j++) {
        expect(parsedDocument?.paragraphs[i].lines[j].data,
            expectedDocument.paragraphs[i].lines[j].data);
        expect(parsedDocument?.paragraphs[i].lines[j].attributes,
            expectedDocument.paragraphs[i].lines[j].attributes);
      }
      expect(parsedDocument?.paragraphs[i].blockAttributes,
          expectedDocument.paragraphs[i].blockAttributes);
      expect(parsedDocument?.paragraphs[i].type,
          expectedDocument.paragraphs[i].type);
    }
  });

  test('Should convert aligned image to paragraph embed', () {
    final Delta delta = Delta()
      ..insert({'image': '/device/user/to/path/file.jpg'})
      ..insert('\n', {"align": "center", "indent": 1})
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph(
        lines: [
          Line(data: {'image': '/device/user/to/path/file.jpg'}),
        ],
        blockAttributes: {"align": "center", "indent": 1},
        type: ParagraphType.embed,
      ),
      Paragraph(
        lines: [
          Line(data: '\n'),
        ],
        type: ParagraphType.block,
      ),
    ]);

    final Document? parsedDocument = RichTextParser().parseDelta(delta);
    expect(
        parsedDocument?.paragraphs.length, expectedDocument.paragraphs.length);

    for (int i = 0; i < expectedDocument.paragraphs.length; i++) {
      expect(parsedDocument?.paragraphs[i].lines.length,
          expectedDocument.paragraphs[i].lines.length);
      for (int j = 0; j < expectedDocument.paragraphs[i].lines.length; j++) {
        expect(parsedDocument?.paragraphs[i].lines[j].data,
            expectedDocument.paragraphs[i].lines[j].data);
        expect(parsedDocument?.paragraphs[i].lines[j].attributes,
            expectedDocument.paragraphs[i].lines[j].attributes);
      }
      expect(parsedDocument?.paragraphs[i].blockAttributes,
          expectedDocument.paragraphs[i].blockAttributes);
      expect(parsedDocument?.paragraphs[i].type,
          expectedDocument.paragraphs[i].type);
    }
  });

  test('Should convert aligned header to paragraph block', () {
    final Delta delta = Delta()
      ..insert("Header title")
      ..insert('\n', {"header": 1})
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph(
        lines: [
          Line(data: "Header title"),
        ],
        blockAttributes: {"header": 1},
        type: ParagraphType.block,
      ),
      Paragraph(
        lines: [
          Line(data: '\n'),
        ],
        type: ParagraphType.block,
      ),
    ]);

    final Document? parsedDocument = RichTextParser().parseDelta(delta);
    expect(
        parsedDocument?.paragraphs.length, expectedDocument.paragraphs.length);

    for (int i = 0; i < expectedDocument.paragraphs.length; i++) {
      expect(parsedDocument?.paragraphs[i].lines.length,
          expectedDocument.paragraphs[i].lines.length);
      for (int j = 0; j < expectedDocument.paragraphs[i].lines.length; j++) {
        expect(parsedDocument?.paragraphs[i].lines[j].data,
            expectedDocument.paragraphs[i].lines[j].data);
        expect(parsedDocument?.paragraphs[i].lines[j].attributes,
            expectedDocument.paragraphs[i].lines[j].attributes);
      }
      expect(parsedDocument?.paragraphs[i].blockAttributes,
          expectedDocument.paragraphs[i].blockAttributes);
      expect(parsedDocument?.paragraphs[i].type,
          expectedDocument.paragraphs[i].type);
    }
  });

  test('Should convert Delta with various attributes', () {
    final Delta delta = Delta()
      ..insert('This is ')
      ..insert('bold', {'bold': true})
      ..insert(' and ')
      ..insert('italic', {'italic': true})
      ..insert(' text with ')
      ..insert('custom color', {'color': '#FF0000'})
      ..insert('\n\n', {'header': 1})
      ..insert('This is a list item')
      ..insert('\n', {'list': 'ordered'})
      ..insert('Another list item')
      ..insert('\n', {'list': 'ordered'})
      ..insert('Third list item')
      ..insert('\n')
      ..insert('This is a ')
      ..insert('link', {'link': 'https://example.com'})
      ..insert(' to a website');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph(
        lines: [
          Line(data: 'This is '),
          Line(data: 'bold', attributes: {'bold': true}),
          Line(data: ' and '),
          Line(data: 'italic', attributes: {'italic': true}),
          Line(data: ' text with '),
          Line(data: 'custom color', attributes: {'color': '#FF0000'}),
        ],
        blockAttributes: {"header": 1},
        type: ParagraphType.block,
      ),
      Paragraph(
          lines: [Line(data: '\n')],
          blockAttributes: {"header": 1},
          type: ParagraphType.block),
      Paragraph(
        lines: [
          Line(data: 'This is a list item'),
        ],
        blockAttributes: {'list': 'ordered'},
        type: ParagraphType.block,
      ),
      Paragraph(
        lines: [
          Line(data: 'Another list item'),
        ],
        blockAttributes: {'list': 'ordered'},
        type: ParagraphType.block,
      ),
      Paragraph(
        lines: [
          Line(data: 'Third list item'),
        ],
        type: ParagraphType.inline,
      ),
      Paragraph(lines: [Line(data: '\n')], type: ParagraphType.block),
      Paragraph(
        lines: [
          Line(data: 'This is a '),
          Line(data: 'link', attributes: {'link': 'https://example.com'}),
          Line(data: ' to a website'),
        ],
        type: ParagraphType.inline,
      ),
    ]);
    final Document? parsedDocument = RichTextParser().parseDelta(delta);
    expect(
        parsedDocument?.paragraphs.length, expectedDocument.paragraphs.length);

    for (int i = 0; i < expectedDocument.paragraphs.length; i++) {
      expect(parsedDocument?.paragraphs[i].lines.length,
          expectedDocument.paragraphs[i].lines.length);
      for (int j = 0; j < expectedDocument.paragraphs[i].lines.length; j++) {
        expect(parsedDocument?.paragraphs[i].lines[j].data,
            expectedDocument.paragraphs[i].lines[j].data);
        expect(parsedDocument?.paragraphs[i].lines[j].attributes,
            expectedDocument.paragraphs[i].lines[j].attributes);
      }
      expect(parsedDocument?.paragraphs[i].blockAttributes,
          expectedDocument.paragraphs[i].blockAttributes);
      expect(parsedDocument?.paragraphs[i].type,
          expectedDocument.paragraphs[i].type);
    }
  });

  test('Should handle empty Delta', () {
    final Delta emptyDelta = Delta();

    final Document? parsedDocument = RichTextParser().parseDelta(emptyDelta);

    expect(parsedDocument, isNull);
  });

  test('Should handle Delta with only newlines', () {
    final Delta deltaWithNewlines = Delta()..insert('\n\n\n\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph(lines: [Line(data: '\n')], type: ParagraphType.block),
      Paragraph(lines: [Line(data: '\n')], type: ParagraphType.block),
      Paragraph(lines: [Line(data: '\n')], type: ParagraphType.block),
      Paragraph(lines: [Line(data: '\n')], type: ParagraphType.block),
    ]);

    final Document? parsedDocument =
        RichTextParser().parseDelta(deltaWithNewlines);
    expect(
        parsedDocument?.paragraphs.length, expectedDocument.paragraphs.length);

    for (int i = 0; i < expectedDocument.paragraphs.length; i++) {
      expect(parsedDocument?.paragraphs[i].lines.length,
          expectedDocument.paragraphs[i].lines.length);
      for (int j = 0; j < expectedDocument.paragraphs[i].lines.length; j++) {
        expect(parsedDocument?.paragraphs[i].lines[j].data,
            expectedDocument.paragraphs[i].lines[j].data);
      }
      expect(parsedDocument?.paragraphs[i].type,
          expectedDocument.paragraphs[i].type);
    }
  });
}
