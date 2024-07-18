// ignore_for_file: must_be_immutable
import 'package:equatable/equatable.dart';

class Line extends Equatable{
  Object? data;
  Map<String, dynamic>? attributes;

  Line({
    this.data,
    this.attributes,
  });

  void setData(Object? data) {
    this.data = data;
  }

  void setAttributes(Map<String, dynamic>? attrs) {
    if (attrs == null) return;
    attributes = attrs;
  }

  void mergeAttributes(Map<String, dynamic> attrs) {
    attributes?.addAll(attrs);
  }

  Line get clone => Line(data: data, attributes: attributes);

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
