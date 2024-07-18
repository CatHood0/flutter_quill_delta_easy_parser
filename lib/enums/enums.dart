/// Enumerates different types of paragraphs that can be represented.
///
/// This enum defines three types of paragraphs:
/// - [inline]: Represents inline paragraphs typically used for short text or elements
///   embedded within larger content.
/// - [block]: Denotes block-level paragraphs, which are standalone elements
///   separated from adjacent content by line breaks or other spacing.
/// - [embed]: Indicates embedded content paragraphs, such as multimedia or
///   external content integrated within a document.
enum ParagraphType {
  /// Inline paragraph type for short text or elements within larger content.
  inline,

  /// Block-level paragraph type, representing standalone elements.
  block,

  /// Embedded content paragraph type, integrating external or multimedia content.
  embed,
}
