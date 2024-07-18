import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'helpers/string_helper.dart';

/// Extension on `Iterable<Iterable<T>>` to flatten nested iterables into a single iterable.
extension _IterableIterableExtension<T> on Iterable<Iterable<T>> {
  /// Flattens the nested iterables into a single iterable of type `T`.
  ///
  /// Iterates through each iterable in this iterable (`Iterable<Iterable<T>>`),
  /// yielding all elements sequentially from each inner iterable in order.
  Iterable<T> get flattened sync* {
    for (var elements in this) {
      yield* elements;
    }
  }
}

/// Extension on `Delta` to denormalize operations within a Quill Delta object.
extension DeltaDenormilazer on Delta {
  /// Fully denormalizes the operations within the Delta.
  ///
  /// Converts each operation in the Delta to a fully expanded form,
  /// where operations that contain newlines are split into separate operations.
  Delta fullDenormalizer() {
    if (isEmpty) return this;

    final List<Map<String, dynamic>> denormalizedOps =
        map<List<Map<String, dynamic>>>(
            (Operation op) => denormalize(op.toJson())).flattened.toList();
    return Delta.fromOperations(
        denormalizedOps.map<Operation>((e) => Operation.fromJson(e)).toList());
  }

  /// Denormalizes a single operation map by splitting newlines into separate operations.
  ///
  /// [op] is a Map representing a single operation within the Delta.
  List<Map<String, dynamic>> denormalize(Map<String, dynamic> op) {
    const newLine = '\n';
    final insertValue = op['insert'];
    if (insertValue is Map || insertValue == newLine) {
      return <Map<String, dynamic>>[op];
    }

    final List<String> newlinedArray =
        tokenizeWithNewLines(insertValue.toString());

    if (newlinedArray.length == 1) {
      return <Map<String, dynamic>>[op];
    }

    // Copy op to retain its attributes, but replace the insert value with a newline.
    final Map<String, dynamic> nlObj = <String, dynamic>{
      ...op,
      ...<String, String>{'insert': newLine}
    };

    return newlinedArray.map((String line) {
      if (line == newLine) {
        return nlObj;
      }
      return <String, dynamic>{
        ...op,
        ...<String, String>{'insert': line},
      };
    }).toList();
  }
}
