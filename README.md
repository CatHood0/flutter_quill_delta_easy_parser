# Flutter Quill Easy Parser

A Flutter package designed to transform `Flutter Quill` content into a structured document format, making it easier to handle and convert for various use cases like generating `Word` or `PDF` documents.

> [!TIP]
>
> If you're using version 1.0.6 or minor versions, see [the migration guide to migrate to 1.1.3](https://github.com/CatHood0/flutter_quill_delta_easy_parser/blob/Main/doc/v106_to_v113.md).

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

final Document? document = DocumentParser()
    .parseDelta(
      delta: delta,
      returnNoSealedCopies: false,
      ignoreAllNewLines: false,
    );
debugPrint(document.toPrettyString());
}
```

**Output in console**:

```console
Document:
    Paragraph:
        Line: [
          TextFragment: "This is "
          TextFragment: "bold", Attributes: {bold: true}
          TextFragment: " and "
          TextFragment: "italic", Attributes: {italic: true}
          TextFragment: " text with "
          TextFragment: "custom color", Attributes: {color: #FF0000}
        ]
        Paragraph Attributes: {header: 1}
        Type: block 
    Paragraph:
        Line: [
          TextFragment: "\n"
        ]
        Paragraph Attributes: {header: 1}
        Type: lineBreak 
    Paragraph:
        Line: [
          TextFragment: "This is a list item"
        ]
        Line: [
          TextFragment: "Another list item"
        ]
        Paragraph Attributes: {list: ordered}
        Type: block 
    Paragraph:
        Line: [
          TextFragment: "Third list item",
        ]
        Line: [
          TextFragment: "This is a "
          TextFragment: "link", Attributes: {link: https://example.com}
          TextFragment: " to a website"
        ]
        Type: inline 
```

## What Does `DocumentParser`?

Transforms the content of a **Quill JS** editor and **Flutter Quill** editors into an easy-to-work paragraph format.

The output of both editors is `Delta` format. While the `Delta` format works great, but, when you need to use it to generate other types of documents (e.g., Word or PDF) from Quill's contents, you probably will need to do more work to format the paragraphs correctly without losses the styles.

## Easy example usage

```dart
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

final Delta delta = Delta()
  ..insert('Hello, how are you? ')
  ..insert('The first Major Section')
  ..insert('\n', {'header': 1})
  ..insert('We are writing some ')
  ..insert('bolded text',{'bold': true})
  ..insert('\n');
final Document? parsedDocument = DocumentParser(mergerBuilder: const CommonMergerBuilder()).parseDelta(delta: delta);
/* 
it's equal, to build a document manually like this:
final Document document = Document(paragraphs: [
  Paragraph(
    lines: [
      Line(fragments: [
        TextFragment(data: "Hello, how are you? The first Major Section"),
      ]),
    ],
    blockAttributes: {"header": 1},
    type: ParagraphType.block,
  ),
  Paragraph(
    lines: [
      Line(fragments: [
        TextFragment(data: "We are writing some "),
        TextFragment(data: "bolded text", attributes: {"bold": true})
      ]),
    ],
    type: ParagraphType.inline,
  ),
  Paragraph.newLine(),
]);
*/
```

## MergerBuilder

`MergerBuilder` is an abstract class that allows us to implement our own logic to join different paragraphs. By default, `DocumentParser` implements `CommonMergerBuilder`, which focuses on joining paragraphs that maintain the same types, or the same block-attributes.

Currently, only **3** implementations are available:

* `NoMergerBuilder`: does not execute any code and returns the paragraphs as they are created.
* `BlockMergerBuilder`: joins all paragraphs that contain the same block-attributes (in a row, from the first to the last, not randomly).
* `CommonMergerBuilder` (we already described it above).

```dart
final parser = DocumentParser(mergerBuilder: <the-merger-that-you-want>);
```

## About the `Paragraph`, `Line` and `TextFragment` API

### The Paragraph Format

The `Paragraph` format is a simple format, where an object contains a list of lines, these "lines" are completely separated from the others. The value contained in `blockAttributes` must be applied to all lines, regardless.

Each `Paragraph`, depending on its content and attributes, can have a different type. For example:

* A `Paragraph` whose content is a `Line` that has an object totally different from a string, will be considered as a `ParagraphType.embed`.
* A `Paragraph`, whose content is pure strings, but that contains `blockAttributes`, will be considered a `ParagraphType.block`.
* A `Paragraph`, whose content only has one new-line, will be considered a `ParagraphType.lineBreak` (even if this new line is applied some type of `blockAttribute`).

> [!NOTE] 
> The only reason why a `Paragraph` should contain several lines at the same time, is because these lines share the same **block-attributes** (which may or may not have it).


`Paragraph` looks like:

```dart
class Paragraph {
  final String id;
  // this is an enum that contains values like: inline, block, lineBreak and embed
  ParagraphType type;
  // contains all attributes (usually block attributes like "header", "align" or "code-block") 
  //that will be applied to whole lines
  Map<String, dynamic>? blockAttributes; 

  // Determines if this instance can be modified 
  //
  // false by default to allow any type of modification
  bool _seal;
  final List<Line> _lines;

  Paragraph({
    required this.lines,
    required this.type,
    this.blockAttributes,
    String? id,
  });
}
```

### Line

`Line` class represents a section of the `paragraph` separates of its siblings. 

```dart
class Line {
  final String id;
  final List<TextFragment> _fragments;
  // if the line is sealed, then we cannot 
  // add/remove/update any fragment into it
  bool _sealed;

  Line({
    required List<TextFragment> fragments,
    String? id,
  });

  // General methods
  List<TextFragment> get fragments;
  void removeFragment(TextFragment fragment);
  void addFragment(TextFragment fragment);
  void updateFragment(int index, TextFragment fragment);
}
```

This is useful when we have a **list**, **code-block** or **blockquote**, because every "`Line`" represents another item an allow us create them without make a manual accumulation. By default, all of them are merged using `mergerBuilder` and passing `CommonMergerBuilder` in `DocumentParser`, but, if you want to avoid merge any `Paragraph` with its similar parts, then just use `NoMergerBuilder`. 

You can see now it, like this plain text diagram representation:
```
┌─────────────Paragraph─────────────────┐
│ 1. This is a ordered list item        │
│ 2. This is another ordered list item  │
│ 3. Just a different ordered list item │
└───────────────────────────────────────┘
```

Its similar to create a `Paragraph` like (just when `BlockMergerBuilder` or `CommonMergerBuilder` is being used):

```dart
Paragraph(
 lines: [
   Line(fragments: [
     TextFragment(data: 'This is a ordered list item')
   ]),
   Line(fragments: [
     TextFragment(data: 'This is another ordered list item'),
   ]),
   Line(fragments: [
     TextFragment(data: 'Just a different ordered list item'),
   ]),
 ],
 blockAttributes: {'list': 'ordered'},
 type: ParagraphType.block,
);
```

### TextFragment

A `TextFragment` represents a segment of content within a `Paragraph`. This content can be a simple String of characters or a more complex structure such as an embed.

```dart
class TextFragment{
  Object data;
  Map<String, dynamic>? attributes;

  TextFragment({
    required this.data,
    this.attributes,
  });
}
```

### Paragraph with lines example:

```dart
final Paragraph basicParagraph = Paragraph(
  lines: [
    Line(fragments: [
      TextFragment(data: 'I am building a new package in Dart. '),
      TextFragment(data: 'This package will be ', attributes: {'bold': true}),
      TextFragment(data: 'open source', attributes: {'italic': true}),
      TextFragment(data: ' and it will help developers process the text entered into a QuillJS editor.'),
    ]),
  ],
  type: ParagraphType.inline,
);
// another factory constructors
final Paragraph embedPr = Paragraph.fromRawEmbed(data: {'image': 'https://example.com/image.png'}, attributes: null, blockAttributes: null); 
final Paragraph embedPrWithOp = Paragraph.fromEmbed(data: Operation.insert({'image': 'https://example.com/image.png'})); 
final Paragraph newLinePr = Paragraph.newLine(blockAttributes: null); 
// A `Paragraph` can also have a `blockAttributes` property. This property indicates what type of paragraph-level formatting has 
//  been applied. For instance, a header is a `Paragraph` that is formatted as a header. 
// Similarly, a bullet point is a `Paragraph` that is formatted as a bullet point. 
//
// Example:
final Paragraph bulletListParagraph = Paragraph.auto(
  lines: [Line(fragments: [
      TextFragment(data: "I am also a bullet point, but I have "),
      TextFragment(data: "underlined text", attributes: {"underline": true}),
      TextFragment(data: " included in my paragraph."),
    ]),
  ],
  blockAttributes: {"list": "bullet"},
);

debugPrint(bulletListParagraph.type.name); // output: block 
```

See the test folder for detailed usage examples and test cases.

## License

This project is licensed under the BSD-3-Clause License - see the [LICENSE](https://github.com/CatHood0/flutter_quill_delta_easy_parser/blob/Main/LICENSE) file for details.
