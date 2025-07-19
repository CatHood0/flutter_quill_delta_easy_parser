import 'package:collection/collection.dart';
import 'package:flutter_quill_delta_easy_parser/extensions/extensions.dart';

class TextFragment {
  /// The main data object associated with the line.
  Object data;

  /// Optional attributes associated with the line data.
  Map<String, dynamic>? attributes;

  /// Constructs a [TextFragment] instance with optional initial [data] and [attributes].
  TextFragment({
    required this.data,
    this.attributes,
  });

  /// Determines if this contains a custom object
  bool get isEmbedFragment => data is! String;

  /// Determines if this contains plain text
  bool get isText => data is String;

  /// Determines if this `TextFragment` is fully empty
  /// with no data into it
  bool get isBlank => isText
      ? data.cast<String>().trim().isEmpty
      : data.cast<dynamic>().isEmpty;

  /// Sets the attributes of the line to [attrs].
  ///
  /// If [attrs] is `null`, no changes are made to the current attributes.
  void setAttributes(Map<String, dynamic>? attrs) {
    if (attrs == null) return;
    attributes = attrs;
  }

  /// Merges additional [attrs] into the current attributes.
  ///
  /// If [attributes] is `null`, creates a new map and adds [attrs] to it.
  void mergeAttributes(Map<String, dynamic> attrs) {
    attributes?.addAll(attrs);
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
  @Deprecated(
      'cleanLine is no longer used and will be removed in future releases. Use cleanAttributes instead')
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

// ignore: always_specify_types, strict_raw_type
const MapEquality _equality = MapEquality();
