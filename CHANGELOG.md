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
