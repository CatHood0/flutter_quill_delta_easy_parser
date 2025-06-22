import 'package:collection/collection.dart';
import 'package:flutter_quill_delta_easy_parser/blocks/text_fragment.dart';
import 'package:flutter_quill_delta_easy_parser/extensions/helpers/map_helper.dart';
import 'package:flutter_quill_delta_easy_parser/utils/nano_id_generator.dart';
import 'package:meta/meta.dart';

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
class Line {
  final List<TextFragment> _fragments;
  final String id;
  bool _sealed;

  Line({
    required List<TextFragment> fragments,
    String? id,
  })  : _fragments = List.from(fragments),
        id = id == null || id.trim().isEmpty ? nanoid(8) : id,
        _sealed = fragments.isEmpty
            ? false
            : fragments.isNotEmpty && fragments.length == 1
                ? fragments.first.data == '\n' ||
                    fragments.first.data is Map<String, dynamic>
                : false;

  Line.fromData({
    required Object data,
    String? id,
    Map<String, dynamic>? attributes,
  })  : _fragments = List.from(
          [
            TextFragment(
              data: data,
              attributes: attributes,
            )
          ],
        ),
        id = id == null || id.trim().isEmpty ? nanoid(8) : id,
        _sealed = data == '\n' || data is Map ? true : false;

  Line.newLine({String? id})
      : _fragments = List.from(
          [
            TextFragment(
              data: '\n',
            )
          ],
        ),
        _sealed = true,
        id = id == null || id.trim().isEmpty ? nanoid(8) : id;

  /// Set a sealed state, where we can't do any type of modification to this Line instance
  void seal() {
    _sealed = true;
  }

  /// Removed the sealed state, to allow modification to this Line instance
  void unseal() {
    _sealed = false;
  }

  void removeFragment(TextFragment fragment) {
    if (_sealed) {
      throw StateError(
          'Element of type ${fragment.runtimeType} cannot be removed when $runtimeType is sealed');
    }
    _fragments.remove(fragment);
  }

  void removeFragmentAt(int index) {
    if (_sealed) {
      throw StateError(
          'Cannot make remove operation when $runtimeType is sealed');
    }
    _fragments.removeAt(index);
  }

  void removeFragmentWhere({required bool Function(TextFragment) where}) {
    if (_sealed) {
      throw StateError(
          'Cannot make remove operation when $runtimeType is sealed');
    }
    _fragments.removeWhere(where);
  }

  void updateFragment(int index, TextFragment fragment) {
    if (_sealed) {
      throw StateError(
          'Element of type ${fragment.runtimeType} cannot be updated when $runtimeType is sealed');
    }
    _fragments[index] = fragment;
  }

  void addFragment(TextFragment fragment) {
    if (_sealed) {
      throw StateError(
          'Element of type ${fragment.runtimeType} cannot be inserted when $runtimeType is sealed');
    }
    if (fragment.data is String || fragment.data is Map) {
      if (fragment.data is String) {
        _mergeWithTail(fragment);
        return;
      }
      _fragments.add(fragment);
      return;
    }
  }

  void insertAt(int index, TextFragment fragment) {
    if (_sealed) {
      throw StateError(
          'Element of type ${fragment.runtimeType} cannot be inserted at $index when $runtimeType is sealed');
    }
    _fragments.insert(index, fragment);
    return;
  }

  void insertBefore(int index, TextFragment fragment) {
    if (_sealed) {
      throw StateError(
          'Element of type ${fragment.runtimeType} cannot be inserted before at $index when $runtimeType is sealed');
    }
    _fragments.insert(index - 1, fragment);
    return;
  }

  void _mergeWithTail(TextFragment fragment) {
    final TextFragment? previous = _fragments.lastOrNull;
    void add() {
      _fragments.add(fragment);
    }

    if (previous == null ||
        previous.data is! String ||
        fragment.data is! String ||
        previous.data == '\n' ||
        fragment.data == '\n') {
      add();
      return;
    }
    final int lastIndex = _fragments.length - 1;
    final bool areAttributesEquals =
        mapEquality(previous.attributes, fragment.attributes) ||
            (previous.attributes == null && fragment.attributes == null);
    if (areAttributesEquals) {
      final String previousData = previous.data as String;
      final String newData = '$previousData${fragment.data}';
      _fragments[lastIndex] = TextFragment(
        data: newData,
        attributes: previous.attributes,
      );
      return;
    }
    add();
  }

  /// Creates a copy of the current [Line] instance.
  Line get clone => Line(fragments: <TextFragment>[..._fragments]);

  /// Creates a deep copy of the current [Line] instance.
  Line get deepClone {
    return Line(
      id: id,
      fragments: _fragments
          .map<TextFragment>(
            (TextFragment e) => e.clone,
          )
          .toList(),
    );
  }

  List<TextFragment> get fragments =>
      List<TextFragment>.unmodifiable(_fragments);
  @visibleForTesting
  List<TextFragment> get rawFragments => _fragments;
  int get length => _fragments.length;
  bool get isSingle => _fragments.length == 1;
  String get toPlainText => _fragments
      .map<String>(
        (TextFragment e) => e.data is! String ? '' : e.data.toString(),
      )
      .join();
  int get textLength => _fragments
      .map<int>(
        (TextFragment e) => e.data is! String ? 1 : e.data.toString().length,
      )
      .fold(0, (int a, int b) => a + b);
  bool get isNewLine => isSingle ? _fragments.single.data == '\n' : false;
  bool get isSealed => _sealed;
  bool get isEmbedFragment => _fragments.single.data is Map<String, dynamic>;
  bool get isTextInsert => _fragments.isEmpty || _fragments.first.data != '\n';
  TextFragment? get first => _fragments.firstOrNull;
  TextFragment? get last => _fragments.lastOrNull;
  bool get isEmpty => _fragments.isEmpty;
  bool get isNotEmpty => !isEmpty;

  @override
  String toString() {
    return 'Line: $_fragments, Sealed: $_sealed';
  }

  String toPrettyString({String indent = ' '}) {
    final StringBuffer buffer = StringBuffer(indent);
    final String rawFragments = _fragments.map((TextFragment fragment) {
      buffer.writeln(
          '${'$indent  '}${fragment.toString().replaceAll('\n', '¶')},');
      final String str = '$buffer';
      buffer
        ..clear()
        ..write(indent);
      return str;
    }).join();
    return '${indent}Line: <Sealed value:$_sealed> [\n$rawFragments${'$indent  '}]';
  }

  TextFragment elementAt(int index) {
    return _fragments.elementAt(index);
  }

  TextFragment? elementAtOrNull(int index) {
    return _fragments.elementAtOrNull(index);
  }

  TextFragment operator [](int index) {
    return _fragments[index];
  }

  void operator []=(int index, TextFragment fragment) {
    _fragments[index] = fragment;
  }

  @override
  bool operator ==(covariant Line other) {
    if (identical(this, other)) return true;
    return const ListEquality().equals(_fragments, other._fragments);
  }

  @override
  int get hashCode => Object.hashAll([_fragments]);
}
