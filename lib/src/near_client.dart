import 'dart:convert';

import 'models/near_client_result/storage_balance.dart';
import '../near_api_flutter.dart';

class NearClient {
  final NEARNetRPCProvider _rpcProvider;

  NearClient(this._rpcProvider);

  NearClient.testnet() : this(NEARNetRPCProvider.testnet());

  NearClient.mainnet() : this(NEARNetRPCProvider.mainnet());

  Future<String> transferNear({
    required NearWallet payer,
    required String receiverId,
    required double nearAmount,
  }) async {
    final payerAccount = Account(
      accountId: payer.accountId,
      keyPair: payer.keyPair,
      provider: _rpcProvider,
    );

    final result = await payerAccount.sendTokens(nearAmount, receiverId);

    return _getTransactionSignature(result);
  }

  Future<String> storageDeposit({
    required NearWallet payer,
    required String contractId,
    required String receiverId,
    String minStorageDepositYoctoNearAmount = "1250000000000000000000",
  }) async {
    final contract = Contract(contractId);
    final payerAccount = Account(
      accountId: payer.accountId,
      keyPair: payer.keyPair,
      provider: _rpcProvider,
    );
    final methodArgs = jsonEncode({"account_id": receiverId});

    final result = await contract.callFunction(
      payerAccount,
      "storage_deposit",
      methodArgs,
      minStorageDepositYoctoNearAmount,
    );

    return _getTransactionSignature(result);
  }

  Future<String> ftTransfer({
    required NearWallet payer,
    required String contractId,
    required String receiverId,
    required double amount,
  }) async {
    final usdcContract = Contract(contractId);
    final payerAccount = Account(
      accountId: payer.accountId,
      keyPair: payer.keyPair,
      provider: _rpcProvider,
    );
    final methodArgs = jsonEncode({
      "receiver_id": receiverId,
      "amount": amount.toStringAsFixed(0),
    });

    final result = await usdcContract.callFunction(
      payerAccount,
      "ft_transfer",
      methodArgs,
      "1",
    );

    return _getTransactionSignature(result);
  }

  Future<int> ftBalance({
    required String accountId,
    required String contractId,
  }) async {
    final usdcContract = Contract(contractId);
    final methodArgs = jsonEncode({"account_id": accountId});
    final result = await usdcContract.callViewFunction(
      _rpcProvider,
      "ft_balance_of",
      methodArgs,
    );

    final json = _handleViewResponse(result);

    return int.parse(json);
  }

  Future<StorageBalance> storageBalanceOf({
    required String accountId,
    required String contractId,
  }) async {
    final usdcContract = Contract(contractId);
    final methodArgs = jsonEncode({"account_id": accountId});
    final result = await usdcContract.callViewFunction(
      _rpcProvider,
      "storage_balance_of",
      methodArgs,
    );

    final json = _handleViewResponse(result);

    return json != null
        ? StorageBalance.fromJson(json)
        : StorageBalance.empty();
  }

  static dynamic _handleViewResponse(Map<dynamic, dynamic> resp) {
    var res = resp["result"];
    if (res == null) {
      throw resp;
    }

    res = res["result"];
    if (res == null) {
      throw resp;
    }

    return jsonDecode(utf8.decode(res.cast<int>()));
  }

  static String _getTransactionSignature(Map<dynamic, dynamic> resp) {
    if (resp.containsKey("error") ||
        resp["result"]?["status"]?.containsKey("Failure")) {
      throw resp;
    }

    return resp["result"]?["transaction"]?["hash"] ?? (throw resp);
  }
}
