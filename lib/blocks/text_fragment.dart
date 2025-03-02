import 'package:collection/collection.dart';

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

  /// Clears the data and attributes of the line, setting them to `null`.
  void cleanLine() {
    attributes = null;
  }

  @override
  String toString() {
    attributes ??= null;
    return 'TextFragment: "${data is String ? '$data'.replaceAll('\n', '\\n') : data}"${attributes == null ? '' : ', attributes: $attributes'}';
  }

  @override
  bool operator ==(covariant TextFragment other) {
    if (identical(this, other)) return true;
    return (data is Map && other.data is Map
            ? _equality.equals(data as Map, other.data as Map)
            : data == other.data) &&
        _equality.equals(
          attributes,
          other.attributes,
        );
  }

  @override
  int get hashCode => Object.hash(data, attributes);
}

const MapEquality _equality = MapEquality();
