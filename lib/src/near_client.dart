import 'dart:convert';
import 'package:flutter/foundation.dart';

import 'package:near_api_flutter/src/models/transaction_result/final_execution_outcome.dart';

import 'constants.dart';
import 'models/action_types.dart';
import 'models/near_client_result/storage_balance.dart';
import '../near_api_flutter.dart';
import 'models/transaction_dto.dart';

class NearClient {
  final NEARNetRPCProvider _rpcProvider;

  NearClient(this._rpcProvider);

  NearClient.testnet() : this(NEARNetRPCProvider.testnet());

  NearClient.mainnet() : this(NEARNetRPCProvider.mainnet());

  Future<String> createSignedTransaction({
    required NearWallet payer,
    required String receiverId,
    required double nearAmount,
  }) {
    final payerAccount = Account(
      accountId: payer.accountId,
      keyPair: payer.keyPair,
      provider: _rpcProvider,
    );

    return payerAccount.createSignedTxn(nearAmount, receiverId);
  }

  Future<String> createSignedFtTransaction({
    required NearWallet payer,
    required String receiverId,
    required String contractId,
    required double amount,
  }) async {
    List<Transaction> transactions = [];
    final contract = Contract(contractId);
    final payerAccount = Account(
      accountId: payer.accountId,
      keyPair: payer.keyPair,
      provider: _rpcProvider,
    );
    final receiverStorageBalance = await storageBalanceOf(
      accountId: receiverId,
      contractId: contractId,
    );

    if (!receiverStorageBalance.hasEnoughMinimum) {
      final optInContract = Transaction(
        actionType: ActionType.functionCall,
        signer: payerAccount.accountId,
        nearAmount: Constants.minStorageDepositYoctoNearAmount,
        gasFees: Constants.defaultGas,
        receiver: contractId,
        methodName: "storage_deposit",
        methodArgs: jsonEncode({"account_id": receiverId}),
      );
      transactions.add(optInContract);
    }

    final ftTransferTxn = Transaction(
      actionType: ActionType.functionCall,
      signer: payerAccount.accountId,
      nearAmount: "1",
      gasFees: Constants.defaultGas,
      receiver: contractId,
      methodName: "ft_transfer",
      methodArgs: jsonEncode({
        "receiver_id": receiverId,
        "amount": amount.toStringAsFixed(0),
      }),
    );
    transactions.add(ftTransferTxn);

    return contract.signCallFunctionWithActions(
      payerAccount,
      transactions,
    );
  }

  Future<FinalExecutionOutcome> transferNearAsyncAndWait({
    required NearWallet payer,
    required String receiverId,
    required double nearAmount,
    delayBeforeCheckingTxnStatus = const Duration(seconds: 10),
  }) async {
    final signedTxn = await createSignedTransaction(
      payer: payer,
      receiverId: receiverId,
      nearAmount: nearAmount,
    );

    final txnHash = await _rpcProvider.broadcastTransactionAsync(signedTxn);
    debugPrint("txnHash=$txnHash");

    await Future.delayed(delayBeforeCheckingTxnStatus);
    final txn = await _rpcProvider.checkTxnStatus(
      txnHash: txnHash,
      senderAccountId: payer.accountId,
    );

    return txn;
  }

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
      callerAccount: payerAccount,
      functionName: "storage_deposit",
      functionArgs: methodArgs,
      yoctoNearAmount: minStorageDepositYoctoNearAmount,
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
      callerAccount: payerAccount,
      functionName: "ft_transfer",
      functionArgs: methodArgs,
      yoctoNearAmount: "1",
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
