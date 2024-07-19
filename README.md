# Flutter Quill Easy Parser

A Dart package designed to transform `Flutter Quill` content into a structured document format, making it easier to handle and convert for various use cases like generating `Word` or `PDF` documents.

## Features

- **Delta Parsing**: Converts Quill Delta into a structured document format.
- **Attribute Handling**: Simplifies management of text attributes like bold, italic, colors, etc.
- **Paragraph and Line Structuring**: Organizes content into paragraphs and lines for easy manipulation.

## Usage

```dart
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

void main() {
  final delta = Delta()
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

  final Document? document = RichTextParser().parseDelta(delta);

  if (document != null) {
    print('Parsed Document:');
    document.paragraphs.forEach((paragraph) {
      print('Paragraph:');
      paragraph.lines.forEach((line) {
        print('Line: ${line.data}, Attributes: ${line.attributes}');
      });
      print('Block Attributes: ${paragraph.blockAttributes}');
    });
  }
/*
Document:
    Paragraph:
        Line: This is , Attributes: null
        Line: bold, Attributes: {bold: true}
        Line:  and , Attributes: null
        Line: italic, Attributes: {italic: true}
        Line:  text with , Attributes: null
        Line: custom color, Attributes: {color: #FF0000}
        Block Attributes: {header: 1}
    Paragraph:
        Line: \n, Attributes: null
        Block Attributes: {header: 1}
    Paragraph:
        Line: This is a list item, Attributes: null
        Block Attributes: {list: ordered}
    Paragraph:
        Line: Another list item, Attributes: null
        Block Attributes: {list: ordered}
    Paragraph:
        Line: Third list item, Attributes: null
        Block Attributes: null
    Paragraph:
        Line: This is a , Attributes: null
        Line: link, Attributes: {link: https://example.com}
        Line:  to a website, Attributes: null
        Block Attributes: null
*/
}
```

## What Does the Package Do?

This package transforms the content of a `Quill JS` editor into an easy-to-work-with paragraph format.

By default, a QuillJS editor outputs its content in the `Quill Delta` format. While the `Delta` format works great for a browser-based editor like `Quill`, it's not the most convenient data format if you'd like to generate other types of documents (e.g., Word or PDF) from Quill's contents.

`RichTextParser` will transform a `Quill Delta` into a more convenient paragraph-based format.
How Does It Work?

`Quill JS` outputs a `Delta` with a format like the following:

```dart
final delta = Delta()
    ..insert('Hello, how are you?')
    ..insert('The first Major Section')
    ..insert('\n', {'header': 1})
    ..insert('We are writing some ')
    ..insert('bolded text',{'bold': true})
    ..insert('\n');
```

`RichTextParser` will transform a Quill Delta into an easier-to-work-with paragraph format, like the one below:

```dart

final Document document = Document(paragraphs: [
  Paragraph(
    lines: [Line(data: "Hello, how are you?")]
  ),
  Paragraph(
    lines: [Line(data: "The First Major Section")],
    blockAttributes: {"header": 1}
  ),
  Paragraph(
    lines: [
      Line(data: "We are writing some "),
      Line(data: "bolded text", attributes: {"bold": true})
    ]
  ),
  Paragraph(lines: [Line('\n')], type: ParagraphType.block)
]);
```

## The Paragraph Format

A parsed `Quill JS` document is composed entirely of paragraphs. Each `paragraph` must contain either a lines property, which indicates the content of the paragraph. A `Paragraph` may also contain a `blockAttributes` property, which indicates the formatting of the `Paragraph`.

`Paragraph` looks like:

```dart
class Paragraph {
  final List<Line> lines;
  ParagraphType? type; // this is an enum that contains values like: inline, block and embed
  Map<String, dynamic>? blockAttributes; // contains all attributes (usually block attributes like "heaeder") that will be applied to whole lines

  Paragraph({
    required this.lines,
    this.blockAttributes,
    this.type,
  });
}
```

## Lines

A `Line` represents a segment of content within a `Paragraph`. This content can be a simple `string` of characters or a more complex structure such as an `embed`.

- **data**: This can be either a string (representing text) or a map (representing an embed or other structured content).
- **attributes**: A map containing key-value pairs that describe the formatting or other attributes of the Line.

`Line` looks like:

```dart
class Line{
  Object? data;
  Map<String, dynamic>? attributes;

  Line({
    this.data,
    this.attributes,
  });
}
```

For example, consider the following `Paragraph` in Dart:

```dart

final Paragraph paragraph = Paragraph(
  lines: [
    Line(data: 'I am building a new package in Dart. '),
    Line(data: 'This package will be ', attributes: {'bold': true}),
    Line(data: 'open source', attributes: {'italic': true}),
    Line(data: ' and it will help developers process the text entered into a QuillJS editor.'),
    Line(data: {'image': 'https://example.com/image.png'}),
  ],
);
```

## Attributes

Finally, a `Paragraph` can also have a `blockAttributes` property. This property indicates what type of paragraph-level formatting has been applied. For instance, a header is a `Paragraph` that is formatted as a header. Similarly, a bullet point is a `Paragraph` that is formatted as a bullet point. An example of a `Paragraph` with formatting is shown below.

```dart

final Paragraph bulletPointParagraph = Paragraph(
  lines: [
    Line(data: "I am a bullet point.")
  ],
  blockAttributes: {"list": "bullet"},
  type: ParagraphType.block,
);

final Paragraph bulletPointWithUnderlineParagraph = Paragraph(
  lines: [
    Line(data: "I am also a bullet point, but I have "),
    Line(data: "underlined text", attributes: {"underline": true}),
    Line(data: " included in my paragraph.")
  ],
  blockAttributes: {"list": "bullet"},
  type: ParagraphType.block,
);

final Document document = Document(paragraphs: [bulletPointWithUnderlineParagraph, bulletPointParagraph]);
```

See the test folder for detailed usage examples and test cases.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

## License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](https://github.com/CatHood0/flutter_quill_delta_easy_parser/blob/Main/LICENSE) file for details.
