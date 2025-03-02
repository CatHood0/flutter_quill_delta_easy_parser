import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Should convert image to paragraph embed', () {
    final Delta delta = Delta()
      ..insert({'image': '/device/user/to/path/file.jpg'})
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.fromRawEmbed(
        data: {'image': '/device/user/to/path/file.jpg'},
      ),
      Paragraph.newLine()
    ]);

    final Document? parsedDocument = DocumentParser().parseDelta(delta: delta);
    _execExpects(parsedDocument, expectedDocument);
  });

  test('Should convert aligned image to paragraph embed', () {
    final Delta delta = Delta()
      ..insert({'image': '/device/user/to/path/file.jpg'})
      ..insert('\n', {"align": "center", "indent": 1})
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.fromRawEmbed(
        data: {'image': '/device/user/to/path/file.jpg'},
        blockAttributes: {"align": "center", "indent": 1},
      ),
      Paragraph.newLine(),
    ]);

    final Document? parsedDocument = DocumentParser().parseDelta(delta: delta);
    _execExpects(parsedDocument, expectedDocument);
  });

  test('should remove unnecessary new lines', () {
    final Delta delta = Delta.fromOperations([
      Operation.insert(
          'This is an interesting example about how the easy parser can work ',
          {'bold': true}),
      Operation.insert('\n'),
      Operation.insert(
          'but, sometimes, it could get a unexpected behavior, so... we make some test to avoid that '),
      Operation.insert('\n'),
      Operation.insert(
          'but 2, sometimes, it could get a unexpected behavior, so... we make some test to avoid that'),
      Operation.insert('\n'),
    ]);

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.sealed(
        lines: [
          Line.fromData(
            data:
                "This is an interesting example about how the easy parser can work ",
            attributes: {'bold': true},
          ),
          Line.fromData(
            data:
                "but, sometimes, it could get a unexpected behavior, so... we make some test to avoid that ",
          ),
          Line.fromData(
            data:
                "but 2, sometimes, it could get a unexpected behavior, so... we make some test to avoid that",
          ),
        ],
        type: ParagraphType.inline,
      ),
      Paragraph.newLine(),
    ]);

    final Document? parsedDocument = DocumentParser().parseDelta(delta: delta);
    _execExpects(parsedDocument, expectedDocument);
  });

  test(
      'should merge similar operations that contains same attributes (even if both does not contains them)',
      () {
    final Delta delta = Delta.fromOperations([
      Operation.insert('This is an interesting example', {'bold': true}),
      Operation.insert(' about how the easy parser can work ', {'bold': true}),
      Operation.insert('but, sometimes, it could get a unexpected behavior,'),
      Operation.insert(' so... we make some test to avoid that'),
      Operation.insert('\n'),
    ]);

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.sealed(
        lines: [
          Line(
            fragments: [
              TextFragment(
                data:
                    "This is an interesting example about how the easy parser can work ",
                attributes: {'bold': true},
              ),
              TextFragment(
                data:
                    "but, sometimes, it could get a unexpected behavior, so... we make some test to avoid that",
              ),
            ],
          ),
        ],
        type: ParagraphType.inline,
      ),
      Paragraph.newLine(),
    ]);

    final Document? parsedDocument = DocumentParser().parseDelta(delta: delta);
    _execExpects(parsedDocument, expectedDocument);
  });

  test('Should convert aligned header to paragraph block', () {
    final Delta delta = Delta()
      ..insert("Header title")
      ..insert('\n', {"header": 1})
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.sealed(
        lines: [
          Line.fromData(data: "Header title"),
        ],
        blockAttributes: {"header": 1},
        type: ParagraphType.block,
      ),
      Paragraph.newLine()
    ]);

    final Document? parsedDocument = DocumentParser().parseDelta(delta: delta);
    _execExpects(parsedDocument, expectedDocument);
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
      ..insert(' to a website')
      ..insert('\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.sealed(
        lines: [
          Line(
            fragments: [
              TextFragment(data: 'This is '),
              TextFragment(data: 'bold', attributes: {'bold': true}),
              TextFragment(data: ' and '),
              TextFragment(data: 'italic', attributes: {'italic': true}),
              TextFragment(data: ' text with '),
              TextFragment(
                  data: 'custom color', attributes: {'color': '#FF0000'}),
            ],
          ),
        ],
        blockAttributes: {"header": 1},
        type: ParagraphType.block,
      ),
      Paragraph(
        lines: <Line>[Line.newLine()],
        blockAttributes: {"header": 1},
        type: ParagraphType.lineBreak,
      ),
      Paragraph(
        lines: [
          Line.fromData(data: 'This is a list item'),
          Line.fromData(data: 'Another list item'),
        ],
        blockAttributes: {'list': 'ordered'},
        type: ParagraphType.block,
      ),
      Paragraph(
        lines: [
          Line.fromData(data: 'Third list item'),
          Line(
            fragments: [
              TextFragment(data: 'This is a '),
              TextFragment(
                  data: 'link', attributes: {'link': 'https://example.com'}),
              TextFragment(data: ' to a website'),
            ],
          ),
        ],
        type: ParagraphType.inline,
      ),
      Paragraph.newLine(),
    ]);
    final Document? parsedDocument = DocumentParser().parseDelta(delta: delta);
    _execExpects(parsedDocument, expectedDocument);
  });

  test('Should handle empty Delta', () {
    final Delta emptyDelta = Delta();

    final Document? parsedDocument =
        DocumentParser().parseDelta(delta: emptyDelta);

    expect(parsedDocument, isNull);
  });

  test('Should handle Delta with only newlines', () {
    final Delta deltaWithNewlines = Delta()..insert('\n\n\n\n');

    final Document expectedDocument = Document(paragraphs: [
      Paragraph.newLine(),
      Paragraph.newLine(),
      Paragraph.newLine(),
      Paragraph.newLine(),
    ]);

    final Document? parsedDocument =
        DocumentParser().parseDelta(delta: deltaWithNewlines);
    _execExpects(parsedDocument, expectedDocument);
  });
}

void _execExpects(Document? parsedDocument, Document expectedDocument) {
  expect(
    parsedDocument?.paragraphs.length,
    expectedDocument.paragraphs.length,
    reason: 'Len difference: Parsed(${parsedDocument?.paragraphs.length ?? -1})'
        ' is not the same of the Expected(${expectedDocument.paragraphs.length}).\n'
        'Parsed: ${parsedDocument?.toPrettyString()}'
        '|------------\nExpected: ${expectedDocument.toPrettyString()}',
  );

  for (int i = 0; i < expectedDocument.paragraphs.length; i++) {
    expect(
      parsedDocument?.paragraphs[i].length,
      expectedDocument.paragraphs[i].length,
      reason:
          'Len lines in paragraph($i) difference: Parsed(${parsedDocument?.paragraphs[i].length})'
          ' is not the same of the Expected(${expectedDocument.paragraphs[i].length}).\n'
          'Parsed Lines: ${parsedDocument?.paragraphs[i].toPrettyString()},\n'
          'Expected Lines: ${expectedDocument.paragraphs[i].toPrettyString()}',
    );
    for (int j = 0; j < expectedDocument.paragraphs[i].lines.length; j++) {
      final Line? line = parsedDocument?.paragraphs[i].lines[j];
      final Line expectedLine = expectedDocument.paragraphs[i].lines[j];
      expect(
        line,
        expectedLine,
        reason: 'The paragraph at $i into the line at index $j is not'
            ' the same of the expected line. '
            '\nParsed: ${line?.toPrettyString()},\nExpected: ${expectedLine.toPrettyString()}\n',
      );
      for (int k = 0; k < expectedLine.length; k++) {
        final TextFragment? fragment = line?.rawFragments[k];
        final TextFragment expectedFragment = expectedLine.rawFragments[k];
        expect(
          fragment?.data,
          expectedFragment.data,
          reason: 'The paragraph at $i into the line at index $j has not'
              ' the same data value/type of the expected line. '
              '\nParsed: "${fragment?.data}", \nExpected: "${expectedFragment.data}"',
        );
        expect(
          fragment?.attributes,
          expectedFragment.attributes,
          reason: 'The paragraph at $i into the line at index $j has not'
              ' the same attributes of the expected line. '
              '\nParsed: ${fragment?.attributes}, \nExpected: ${expectedFragment.attributes}',
        );
      }
    }
    expect(
      parsedDocument?.paragraphs[i].blockAttributes,
      expectedDocument.paragraphs[i].blockAttributes,
      reason: 'Block difference at paragraph($i).\n'
          'Parsed: ${parsedDocument?.paragraphs[i].blockAttributes},\nExpected: ${expectedDocument.paragraphs[i].blockAttributes}',
    );
    expect(
      parsedDocument?.paragraphs[i].type,
      expectedDocument.paragraphs[i].type,
      reason: 'ParagraphType difference at paragraph($i).\n'
          'Parsed: "${parsedDocument?.paragraphs[i].type}",\nExpected: "${expectedDocument.paragraphs[i].type}"',
    );
  }
}
