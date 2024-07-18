// ignore_for_file: must_be_immutable

import 'package:equatable/equatable.dart';
import 'package:flutter_quill_delta_easy_parser/blocks/hyperlink.dart';

class SetupInfo extends Equatable{
  int numberedLists;
  List<QHyperLink> hyperlinks;

  SetupInfo({
    required this.numberedLists,
    required this.hyperlinks,
  });

  @override
  // TODO: implement props
  List<Object?> get props => [numberedLists, hyperlinks];
}
