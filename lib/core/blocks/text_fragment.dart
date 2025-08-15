import 'package:collection/collection.dart';
import 'package:flutter_quill_delta_easy_parser/extensions/extensions.dart';
import 'package:flutter_quill_delta_easy_parser/flutter_quill_delta_easy_parser.dart';

import '../../utils/map_equals.dart';

/// Represents a portion of the text into a [Line], separated by
/// the attributes
class TextFragment {
  /// The main data object associated with the line.
  Object data;

  /// Optional attributes associated with the line data.
  Map<String, dynamic>? attributes;

  /// The current length of the fragment
  int? _length;

  TextFragment({
    required this.data,
    this.attributes,
  });

  TextFragment.empty()
      : data = "",
        attributes = null;

  /// Determines if this contains a custom object
  bool get isEmbedFragment => data is! String;

  /// Determines if this contains plain text
  bool get isText => data is String;

  /// Determines if this `TextFragment` is fully empty
  /// with no data into it
  bool get isBlank => isText
      ? data.cast<String>().trim().isEmpty
      : data.cast<dynamic>().isEmpty;

  /// Sets the attributes of the fragment to [attrs].
  ///
  /// If [attrs] is `null`, no changes are made to the current attributes.
  void setAttributes(Map<String, dynamic>? attrs) {
    if (attrs == null) return;
    attributes = attrs;
  }

  /// Returns a Boolean indicating if we can merge the current fragment
  /// with the other one
  bool canMergeWith(TextFragment other) {
    if (data.runtimeType != other.data.runtimeType) return false;
    if (attributes != null && other.attributes == null) return false;
    if (attributes == null && other.attributes != null) return false;
    if (attributes == null && other.attributes == null) return true;
    if (attributes!.isEmpty && other.attributes!.isNotEmpty) return false;
    if (attributes!.isNotEmpty && other.attributes!.isEmpty) return false;
    if (mapEquals(attributes, other.attributes)) {
      return true;
    }

    return true;
  }

  /// Sets the data object of the fragment to [data].
  ///
  /// If [data] is not the same type of the last data registered,
  /// no changes are made to the current [data] on this fragment.
  void setData(Object data) {
    if (data.runtimeType != this.data.runtimeType || data == this.data) return;
    this.data = data;
    _length = null;
  }

  /// Merges additional [attrs] into the current attributes.
  ///
  /// If [attributes] is `null`, creates a new map and adds [attrs] to it.
  void mergeAttributes(Map<String, dynamic> attrs) {
    attributes?.addAll(attrs);
  }

  /// Converts the operation to its plain text representation.
  String toPlain({String Function(Object embedData)? embedBuilder}) {
    return data is String
        ? '$data'
        : embedBuilder?.call(data) ?? Document.kObjectReplacementCharacter;
  }

  int get length => _length ??= isText ? data.cast<String>().length : 1;
  set length(int? len) => _length = len;

  String text({
    String ifNot = Document.kObjectReplacementCharacter,
    String Function(Object d)? ifNotBuilder,
  }) =>
      isText ? getTextValue() : ifNotBuilder?.call(data) ?? ifNot;

  bool get hasAttributes => attributes != null && attributes!.isNotEmpty;
  bool get hasNoAttributes => !hasAttributes;

  bool hasSameAttributes(Map<String, dynamic>? attrs) =>
      mapEquals<String, dynamic>(attributes, attrs);

  /// Returns `true` if this [TextFragment] contains character at specified [offset]
  bool containsOffset(int offset, {bool inclusive = true}) {
    return inclusive
        ? offset >= 0 && offset <= length
        : offset >= 0 && offset < length;
  }

  /// Creates a deep copy of the current [TextFragment] instance.
  TextFragment get clone => TextFragment(data: data, attributes: attributes);

  /// Get the string contained by this fragment
  ///
  /// Return an empty string if the element is an embed fragment
  String getTextValue() {
    if (isEmbedFragment) return "";
    return data.cast<String>();
  }

  /// Get the object contained by this fragment
  T? getValue<T extends Object>() {
    return data.castOrNull<T>();
  }

  /// Get the object map contained by this fragment
  Map<String, dynamic> getEmbedValue() {
    return getValue<Map<String, dynamic>>()!;
  }

  /// Clears the data and attributes of the line, setting them to `null`.
  @Deprecated('cleanLine is no longer used and '
      'will be removed in future releases. '
      'Use cleanAttributes instead')
  void cleanLine() {
    data is String ? data = '' : data = <String, dynamic>{};
    attributes = null;
  }

  /// Clears the data and attributes of the line, setting them to `null`.
  void cleanAttributes() {
    attributes = null;
  }

  @override
  String toString() {
    attributes ??= null;
    return 'TextFragment: "${data is String ? '$data'.replaceAll('\n', '\\n') : data}'
        '"${attributes == null ? '' : ', attributes: $attributes'}';
  }

  @override
  bool operator ==(covariant TextFragment other) {
    if (identical(this, other)) return true;
    return (data is Map && other.data is Map
            ? _equality.equals(
                data as Map,
                other.data as Map,
              )
            : data == other.data) &&
        _equality.equals(
          attributes,
          other.attributes,
        );
  }

  @override
  int get hashCode => Object.hash(data, attributes);
}

// ignore: strict_raw_type
const MapEquality _equality = MapEquality();
