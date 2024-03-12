import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:near_api_flutter/src/models/access_key.dart';
import 'package:near_api_flutter/src/models/transaction_result/final_execution_outcome.dart';
import 'package:near_api_flutter/src/transaction_api/exponential_backoff.dart';
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

  /// Keep ids unique across all connections.
  late int _nextId;

  RPCProvider(this.providerURL) {
    _nextId = 123;
  }

  Future<FinalExecutionOutcome> checkTxnStatus({
    required String txnHash,
    required String senderAccountId,
  }) async {
    final params = [txnHash, senderAccountId];

    final jsonBody = await _sendJsonRpc("tx", params);
    final result = jsonBody['result'];
    if (result != null) {
      return FinalExecutionOutcome.fromJson(result);
    }

    throw jsonBody;
  }

  Future<BlockDetails> getBlockDetails() async {
    final params = {"finality": "final"};
    final jsonBody = await _sendJsonRpc("block", params);
    final result = jsonBody['result'];
    if (result != null) {
      return BlockDetails.fromJson(result);
    }

    throw jsonBody;
  }

  /// Calls near RPC API's getAccessKeys for nonce and block hash
  Future<AccessKey> findAccessKey(accountId, publicKey) async {
    final params = {
      "request_type": "view_access_key",
      "finality": "optimistic",
      "account_id": accountId,
      "public_key": "ed25519:$publicKey"
    };

    final jsonBody = await _sendJsonRpc("query", params);

    return AccessKey.fromJson(jsonBody['result']);
  }

  /// Calls near RPC API's broadcast_tx_commit to broadcast the transaction and waits until transaction is fully complete.
  Future<Map<String, dynamic>> broadcastTransaction(
    String encodedTransaction,
  ) async {
    final params = [encodedTransaction];

    return _sendJsonRpc("broadcast_tx_commit", params);
  }

  Future<String> broadcastTransactionAsync(
    String encodedTransaction,
  ) async {
    final params = [encodedTransaction];

    final jsonBody = await _sendJsonRpc("broadcast_tx_async", params);
    final txnHash = jsonBody['result'];
    if (txnHash != null) {
      return txnHash;
    }

    throw jsonBody;
  }

  /// Allows you to call a contract method as a view function.
  Future<Map<dynamic, dynamic>> callViewFunction(
    String contractId,
    String methodName,
    String methodArgs,
    int? blockId,
  ) async {
    Map<String, dynamic> params = {
      "request_type": "call_function",
      "finality": "optimistic",
      "account_id": contractId,
      "method_name": methodName,
      "args_base64": methodArgs,
    };

    if (blockId != null) {
      params["block_id"] = blockId;
    }

    return _sendJsonRpc("query", params);
  }

  Future<Map<String, dynamic>> _sendJsonRpc(
    String method,
    dynamic params,
  ) {
    Future<Map<String, dynamic>> callRpc() async {
      final headers = {
        Constants.contentType: Constants.applicationJson,
      };

      final payload = {
        'method': method,
        'params': params,
        'id': (_nextId++),
        'jsonrpc': '2.0',
      };

      http.Response responseData = await http.post(
        Uri.parse(providerURL),
        headers: headers,
        body: jsonEncode(payload),
      );

      return jsonDecode(responseData.body);
    }

    return exponentialBackoff(getResult: callRpc);
  }
}
