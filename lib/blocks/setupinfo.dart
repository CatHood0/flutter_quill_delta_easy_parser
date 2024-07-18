// ignore_for_file: must_be_immutable
import 'package:meta/meta.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_quill_delta_easy_parser/blocks/hyperlink.dart';

/// Represents setup information including the count of numbered lists and a list
/// of hyperlinks.
///
/// This class is used to encapsulate configuration data related to numbered lists
/// and hyperlinks within a document or application.
///
/// The [numberedLists] property holds the count of numbered lists present in the
/// document setup.
///
/// The [hyperlinks] property is a list of [QHyperLink] objects representing
/// hyperlinks associated with the setup.
///
/// Example usage:
/// ```dart
/// SetupInfo setup = SetupInfo(
///   numberedLists: 3,
///   hyperlinks: [
///     QHyperLink(url: 'https://example.com', text: 'Example Link'),
///     QHyperLink(url: 'https://another.com', text: 'Another Link'),
///   ],
/// );
/// ```
@experimental
class SetupInfo extends Equatable {
  /// The count of numbered lists in the setup.
  int numberedLists;

  /// List of hyperlinks associated with the setup.
  List<QHyperLink> hyperlinks;

  /// Constructs a [SetupInfo] instance with required properties.
  ///
  /// [numberedLists] specifies the number of numbered lists in the setup.
  ///
  /// [hyperlinks] is a list of [QHyperLink] objects representing hyperlinks.
  SetupInfo({
    required this.numberedLists,
    required this.hyperlinks,
  });

  @override
  List<Object?> get props => [numberedLists, hyperlinks];
}
