// ignore_for_file: must_be_immutable
import 'package:equatable/equatable.dart';

/// Represents a line of data with associated attributes.
///
/// This class encapsulates a data object and optional attributes associated
/// with that data. It provides methods to manipulate and manage the data and
/// attributes.
///
/// Example usage:
/// ```dart
/// // Creating a new Line instance
/// Line line = Line(data: 'Example data', attributes: {'color': 'red'});
///
/// // Setting new data and merging attributes
/// line.setData('Updated data');
/// line.mergeAttributes({'size': '12px'});
///
/// print(line.toString()); // Output: Data: Updated data, attributes: {color: red, size: 12px}
/// ```
class Line extends Equatable {
  /// The main data object associated with the line.
  Object? data;

  /// Optional attributes associated with the line data.
  Map<String, dynamic>? attributes;

  /// Constructs a [Line] instance with optional initial [data] and [attributes].
  Line({
    this.data,
    this.attributes,
  });

  /// Sets the data object of the line to [data].
  void setData(Object? data) {
    this.data = data;
  }

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

  /// Creates a deep copy of the current [Line] instance.
  Line get clone => Line(data: data, attributes: attributes);

  /// Clears the data and attributes of the line, setting them to `null`.
  void cleanLine() {
    data = null;
    attributes = null;
  }

  @override
  String toString() {
    data ??= null;
    attributes ??= null;
    return 'Data: $data, attributes: $attributes';
  }

  @override
  List<Object?> get props => [data, attributes];
}
