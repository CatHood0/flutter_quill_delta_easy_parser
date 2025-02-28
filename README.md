# Flutter Quill Easy Parser

A Dart package designed to transform `Flutter Quill` content into a structured document format, making it easier to handle and convert for various use cases like generating `Word` or `PDF` documents.

## Usage Example

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
    ..insert(' to a website')
    ..insert('\n');

  final Document? document = RichTextParser().parseDelta(delta);
  debugPrint(document.toPrettyString());
}
```

Output in console

```console
Document:
    Paragraph:
        Line: "This is "
        Line: "bold", Attributes: {bold: true}
        Line: " and "
        Line: "italic", Attributes: {italic: true}
        Line: " text with "
        Line: "custom color", Attributes: {color: #FF0000}
        Paragraph Attributes: {header: 1}
        Type: block 
    Paragraph:
        Line: "\n"
        Paragraph Attributes: {header: 1}
        Type: block 
    Paragraph:
        Line: "This is a list item"
        Paragraph Attributes: {list: ordered}
        Type: block 
    Paragraph:
        Line: "Another list item"
        Paragraph Attributes: {list: ordered}
        Type: block 
    Paragraph:
        Line: "Third list item"
        Type: inline 
    Paragraph:
        Line: "This is a "
        Line: "link", Attributes: {link: https://example.com}
        Line: " to a website"
        Type: inline 
```

## What Does the Package Do?

This package transforms the content of a **Quill JS** and **Flutter Quill** editors into an easy-to-work-with paragraph format.

The output of both editors is `Quill Delta` format. While the `Delta` format works great for a browser-based editor like `Quill`, it's not the most convenient data format if you'd like to generate other types of documents (e.g., Word or PDF) from Quill's contents.

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
    type: ParagraphType.inline,
  ),
  Paragraph(
    lines: [Line(data: "The First Major Section")],
    blockAttributes: {"header": 1}
    type: ParagraphType.block,
  ),
  Paragraph(
    lines: [
      Line(data: "We are writing some "),
      Line(data: "bolded text", attributes: {"bold": true})
    ]
    type: ParagraphType.inline,
  ),
  Paragraph.newLine(),
]);
```

## The Paragraph Format

A parsed `Quill JS` document is composed entirely of paragraphs. Each `paragraph` must contain either a lines property, which indicates the content of the paragraph. A `Paragraph` may also contain a `blockAttributes` property, which indicates the formatting of the `Paragraph`.

`Paragraph` looks like:

```dart
class Paragraph {
  final String id;
  final List<Line> lines;
  // this is an enum that contains values like: inline, block, lineBreak and embed
  ParagraphType type;
  // contains all attributes (usually block attributes like "header", "align" or "code-block") 
  //that will be applied to whole lines
  Map<String, dynamic>? blockAttributes; 

  // decides if we want to stop any remove or insert operation type 
  //
  // false by default
  bool _seal;

  Paragraph({
    required this.lines,
    required this.type,
    this.blockAttributes,
  });
}
```

## Lines

A `Line` represents a segment of content within a `Paragraph`. This content can be a simple `String` of characters or a more complex structure such as an `embed`.

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
  ],
  type: ParagraphType.inline,
);
final Paragraph embedPr = Paragraph(
  lines: [Line(data: {'image': 'https://example.com/image.png'})],
  type: ParagraphType.embed,
); 
```

## Attributes

A `Paragraph` can also have a `blockAttributes` property. This property indicates what type of paragraph-level formatting has been applied. For instance, a header is a `Paragraph` that is formatted as a header. Similarly, a bullet point is a `Paragraph` that is formatted as a bullet point. An example of a `Paragraph` with formatting is shown below.

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
