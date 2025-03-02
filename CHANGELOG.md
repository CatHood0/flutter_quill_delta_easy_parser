## 1.1.2

* Fix: typo in documentation about `mergerBuilder` in `DocumentParser`.
* Fix: version typo in README a migration guide.

## 1.1.1

* Fix: typo in README.

## 1.1.0

### Breaking changes

`Line` class has been redesigned so that instead of containing a portion of the text within the `Paragraph`, it contains a new class called `TextFragment`.

#### TextFragment

```dart
class TextFragment {
  Object data;
  Map<String, dynamic>? attributes;

  TextFragment({
    required this.data,
    this.attributes,
  });
}
```

#### Line Redesign

`Line` is now able to behave as what it is, a line completely separate from its siblings.

```dart
class Line {
  final List<TextFragment> _fragments;
  final String id;
  bool _sealed;

  Line({
    required List<TextFragment> fragments,
  });
}
```

#### RichTextParser deprecation

A name change for the parser has been planned for several versions, however, it was in this release that it was decided to deprecate `RichTextParser` and replace it with `DocumentParser`, which is more convenient for the package. However, using `RichTextParser` should still return a usable `Document`, in case for some reason it cannot be renamed.

```diff
- RichTextParser().parseDelta(delta);
+ DocumentParser().parseDelta(delta: delta);
```

**If you need more information about the changes, [check migration guide](https://github.com/CatHood0/flutter_quill_delta_easy_parser/blob/Main/doc/migrations.md)**

* Feat: added `mergerBuilder` param to parser. 
* Fix: issues where the first new lines of the `Delta` are being remove unnecessarily.
* Fix: improved and reorganized general internal API to be have a standard of how it should work. 
* Fix: issues where the paragraphs with only a new-line is considered a `ParagraphType.block`.  
* Fix: `toPrettyString()` bad string return.
* Chore: added `toPrettyString()` for `Paragraph` class.
* Chore(test): improve expect messages to be more readable.

## 1.0.6

* Fix: `toPrettyString()` from Document that is not working as expected.
* Fix: parsing is adding non expected new-line after a common Operation.
* Fix(test): wrong expects valitation of some tests.
* Chore: deprecated `isInsertText()` and replaced by `isTextInsert()`.
* Chore: deprecated `setTypeSafe()` from `Paragraph` class.
* Chore: parsing is adding non expected new-line after a common Operation.
* Feat: now `Paragraph` class support seal behavior (prevent any change type).
* Feat: added support for ignore all new lines into the `Delta` passed using `ignoreAllNewLines`.
* Feat: added support for get non sealed elements using `returnNoSealedCopies`.

## 1.0.5

* Fix: sometimes, the `EmbedObject`s can be merged into a inline `Paragraph`.
* Chore: now the parser divides every `Embed`, `Block`, and `NewLine` if its different types.
* Chore: added a new type of `Paragraph` called `ParagraphType.lineBreak`.
* Chore: deprecate `ensureCorrectFormat()` from `Document` class since it already don't do nothing. 
* Chore: removed `setupInfo` param from `Document` since never was used.
* Chore: removed some exports that shouldn't be part of the public API;

## 1.0.4

* Fix: duplicated new lines
* Fix: some new lines could contain inline type instead block type

## 1.0.3

* Fix: block attributes for embeds are ignored
* Feat: new method to make more safety operations with paragraph and documents
* Chore: added more tests

## 1.0.2

* Fix: first insert with a image throws invalid index access
* Chore: minimal changes on README documentation

## 1.0.1

* Chore: fixed bad License reference on the README 

## 1.0.0

* First release
