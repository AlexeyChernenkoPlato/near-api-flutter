class BlockHeader {
  late final String hash;
  late final int height;

  BlockHeader({
    required this.hash,
    required this.height,
  });

  BlockHeader.fromJson(Map<String, dynamic> json) {
    hash = json['hash'];
    height = json['height'];
  }
}
