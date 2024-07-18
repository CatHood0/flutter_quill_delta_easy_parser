import 'package:equatable/equatable.dart';

class QHyperLink extends Equatable {
  final String text;
  final String link;

  const QHyperLink({
    required this.text,
    required this.link,
  });

  @override
  List<Object?> get props => [text, link];
}
