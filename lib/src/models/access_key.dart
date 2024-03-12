class AccessKey {
  String blockHash;
  int nonce;

  AccessKey(this.blockHash, this.nonce);

  static AccessKey fromJson(json) {
    return AccessKey(json['block_hash'] ?? '', json['nonce'] ?? -1);
  }
}
