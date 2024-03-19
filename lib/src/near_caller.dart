import 'dart:convert';

import 'package:bs58/bs58.dart';
import 'package:near_api_flutter/near_api_flutter.dart';

class NearCaller {
  static Future<dynamic> callViewMethod({
    required String contractId,
    required String method,
    Map<String, dynamic>? args,
    int? blockId,
  }) async {
    final contract = Contract(contractId);
    final resp = await contract.callViewFunction(
        NEARNetRPCProvider.testnet(), method, jsonEncode(args ?? {}), blockId);
    return _handleViewResp(resp);
  }

  static Future<dynamic> callChangeMethod({
    required String contractId,
    required String accountId,
    required String privateKey,
    required String publicKey,
    required String method,
    Map<String, dynamic>? args,
    String? nearAmount,
  }) async {
    final contract = Contract(contractId);
    var resp = {};
    do {
      resp = await contract.callFunction(
          callerAccount: getAccount(accountId, privateKey, publicKey),
          functionName: method,
          functionArgs: jsonEncode(args ?? {}),
          yoctoNearAmount: nearAmount ?? '0');
    } while (jsonEncode(resp).contains("InvalidNonce"));
    return _handleChangeResp(resp);
  }

  static dynamic _handleViewResp(Map<dynamic, dynamic> resp) {
    var res = resp["result"];
    if (res == null) throw resp;
    res = res["result"];
    if (res == null) throw resp;
    return jsonDecode(utf8.decode(res.cast<int>()));
  }

  static dynamic _handleChangeResp(Map<dynamic, dynamic> resp) {
    final res = resp["result"];
    if (res == null) throw resp;
    final status = res["status"];
    if (status == null || status["Failure"] != null) throw resp;
    final val = status["SuccessValue"];
    if (val == null || val.runtimeType == Null) throw resp;
    return val;
  }

  static Account getAccount(
    String accountId,
    String privateKey,
    String publicKey,
  ) {
    return Account(
      accountId: accountId,
      keyPair: KeyPair(
        PrivateKey(base58.decode(privateKey)),
        PublicKey(base58.decode(publicKey)),
      ),
      provider: NEARNetRPCProvider.testnet(),
    );
  }
}
