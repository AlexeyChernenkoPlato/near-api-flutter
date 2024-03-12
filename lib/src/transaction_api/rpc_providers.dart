import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:near_api_flutter/src/models/access_key.dart';
import '../constants.dart';
import '../models/block_details.dart';

class NEARNetRPCProvider extends RPCProvider {
  NEARNetRPCProvider(super.providerURL);

  NEARNetRPCProvider.testnet() : super("https://rpc.testnet.near.org");

  NEARNetRPCProvider.mainnet() : super("https://rpc.mainnet.near.org");
}

/// Manages RPC calls
abstract class RPCProvider {
  String providerURL;

  RPCProvider(this.providerURL);

  Future<BlockDetails> getBlockDetails() async {
    final payload = {
      "jsonrpc": "2.0",
      "id": "dontcare",
      "method": "block",
      "params": {"finality": "final"}
    };
    final jsonBody = await _callRpc(payload);
    final result = jsonBody['result'];
    if (result != null) {
      return BlockDetails.fromJson(result);
    }

    throw jsonBody;
  }

  /// Calls near RPC API's getAccessKeys for nonce and block hash
  Future<AccessKey> findAccessKey(accountId, publicKey) async {
    final payload = {
      "jsonrpc": "2.0",
      "id": "dontcare",
      "method": "query",
      "params": {
        "request_type": "view_access_key",
        "finality": "optimistic",
        "account_id": accountId,
        "public_key": "ed25519:$publicKey"
      }
    };

    final jsonBody = await _callRpc(payload);

    return AccessKey.fromJson(jsonBody['result']);
  }

  /// Calls near RPC API's broadcast_tx_commit to broadcast the transaction and waits until transaction is fully complete.
  Future<Map<String, dynamic>> broadcastTransaction(
    String encodedTransaction,
  ) async {
    final payload = {
      "jsonrpc": "2.0",
      "id": "dontcare",
      "method": "broadcast_tx_commit",
      "params": [encodedTransaction]
    };

    return _callRpc(payload);
  }

  /// Allows you to call a contract method as a view function.
  Future<Map<dynamic, dynamic>> callViewFunction(
    String contractId,
    String methodName,
    String methodArgs,
    int? blockId,
  ) async {
    var payload = <String, dynamic>{
      "jsonrpc": "2.0",
      "id": "dontcare",
      "method": "query",
      "params": <String, dynamic>{
        "request_type": "call_function",
        "finality": "optimistic",
        "account_id": contractId,
        "method_name": methodName,
        "args_base64": methodArgs,
      }
    };

    if (blockId != null) {
      payload["params"]["block_id"] = blockId;
    }

    return _callRpc(payload);
  }

  Future<Map<String, dynamic>> _callRpc(
    Map<String, dynamic> payload,
  ) async {
    Map<String, String> headers = {};
    headers[Constants.contentType] = Constants.applicationJson;

    http.Response responseData = await http.post(
      Uri.parse(providerURL),
      headers: headers,
      body: jsonEncode(payload),
    );

    final jsonBody = jsonDecode(responseData.body);
    return jsonBody;
  }
}
