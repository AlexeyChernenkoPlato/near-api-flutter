import 'dart:convert';

import 'package:bs58/bs58.dart';
import 'package:near_api_flutter/near_api_flutter.dart';
import 'package:rps/domain/dtos/auth_dto.dart';
import 'package:rps/utils/logger_util.dart';

class NearCaller {
  static Future<dynamic> callViewMethod({
    required String contractId,
    required AuthDto auth,
    required String method,
    Map<String, dynamic>? args,
    int? blockId,
  }) async {
    final contract = _getContract(contractId, auth);
    final resp =
        await contract.callViewFuntion(method, jsonEncode(args ?? {}), blockId);
    return _handleViewResp(resp);
  }

  static Future<dynamic> callChangeMethod({
    required String contractId,
    required AuthDto auth,
    required String method,
    Map<String, dynamic>? args,
    double? nearAmount,
  }) async {
    final contract = _getContract(contractId, auth);
    var resp = {};
    do {
      resp = await contract.callFunction(
          method, jsonEncode(args ?? {}), nearAmount ?? 0);
      debugLogger.i(jsonEncode(resp));
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

  static Contract _getContract(String contractId, AuthDto auth) {
    return Contract(
      contractId,
      Account(
        accountId: auth.accountId,
        keyPair: KeyPair(
          PrivateKey(base58.decode(auth.privateKey)),
          PublicKey(base58.decode(auth.publicKey)),
        ),
        provider: NEARTestNetRPCProvider(),
      ),
    );
  }
}
