class FinalExecutionOutcome {
  late final Map<String, dynamic> rpcResult;

  String get hash => rpcResult['transaction']['hash'];

  bool get isSuccessful =>
      !rpcResult.containsKey('error') &&
      rpcResult.containsKey('status') &&
      (rpcResult['status'] as Map).containsKey('SuccessValue');

  FinalExecutionOutcome.fromJson(Map<String, dynamic> json) {
    rpcResult = json;
  }
}
