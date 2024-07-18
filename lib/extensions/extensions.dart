import 'package:dart_quill_delta/dart_quill_delta.dart';
import 'helpers/string_helper.dart';

extension _IterableIterableExtension<T> on Iterable<Iterable<T>> {
  /// The sequential elements of each iterable in this iterable.
  ///
  /// Iterates the elements of this iterable.
  /// For each one, which is itself an iterable,
  /// all the elements of that are emitted
  /// on the returned iterable, before moving on to the next element.
  Iterable<T> get flattened sync* {
    for (var elements in this) {
      yield* elements;
    }
  }
}

extension DeltaDenormilazer on Delta {
  Delta fullDenormalizer() {
    if (isEmpty) return this;

    final List<Map<String, dynamic>> denormalizedOps =
        map<List<Map<String, dynamic>>>((Operation op) => denormalize(op.toJson())).flattened.toList();
    return Delta.fromOperations(denormalizedOps.map<Operation>((e) => Operation.fromJson(e)).toList());
  }

  List<Map<String, dynamic>> denormalize(Map<String, dynamic> op) {
    const newLine = '\n';
    final insertValue = op['insert'];
    if (insertValue is Map || insertValue == newLine) {
      return <Map<String, dynamic>>[op];
    }

    final List<String> newlinedArray = tokenizeWithNewLines(insertValue.toString());

    if (newlinedArray.length == 1) {
      return <Map<String, dynamic>>[op];
    }

    // Copy op in to keep its attributes, but replace the insert value with a newline.
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
