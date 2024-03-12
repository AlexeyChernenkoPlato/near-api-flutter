import 'block_header.dart';

class BlockDetails {
  late final String author;
  late final BlockHeader header;

  BlockDetails({
    required this.author,
    required this.header,
  });

  BlockDetails.fromJson(Map<String, dynamic> json) {
    author = json['author'];
    header = BlockHeader.fromJson(json['header']);
  }
}
