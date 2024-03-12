import 'package:near_api_flutter/near_api_flutter.dart';
import 'package:near_api_flutter/src/constants.dart';
import 'package:near_api_flutter/src/models/action_types.dart';
import 'package:near_api_flutter/src/models/transaction_dto.dart';
import 'package:near_api_flutter/src/transaction_api/exponential_backoff.dart';
import 'package:near_api_flutter/src/transaction_api/transaction_manager.dart';

/// This class provides common account related RPC calls
/// including signing transactions with a KeyPair.
class Account {
  String accountId;
  KeyPair keyPair;

  String get publicKey => KeyStore.publicKeyToString(keyPair.publicKey);
  RPCProvider
      provider; //need for the account to call methods and create transactions
  Account(
      {required this.accountId, required this.keyPair, required this.provider});

  /// Transfer near from account to receiver
  Future<Map<dynamic, dynamic>> sendTokens(
    double nearAmount,
    String receiver,
  ) async {
    final accessKeyFuture = findAccessKey();
    final blockFuture = provider.getBlockDetails();
    await Future.wait([accessKeyFuture, blockFuture]);
    final accessKey = await accessKeyFuture;
    final block = await blockFuture;
    accessKey.blockHash = block.header.hash;

    // Create Transaction
    accessKey.nonce++;
    final publicKey = KeyStore.publicKeyToString(keyPair.publicKey);

    final transaction = Transaction(
      signer: accountId,
      publicKey: publicKey,
      nearAmount: nearAmount.toStringAsFixed(12),
      gasFees: Constants.defaultGas,
      receiver: receiver,
      methodName: '',
      methodArgs: '',
      accessKey: accessKey,
      actionType: ActionType.transfer,
    );

    // Serialize Transaction
    final serializedTransaction =
        TransactionManager.serializeTransferTransaction(transaction);
    final hashedSerializedTx =
        TransactionManager.toSHA256(serializedTransaction);

    // Sign Transaction
    final signature = TransactionManager.signTransaction(
      keyPair.privateKey,
      hashedSerializedTx,
    );

    // Serialize Signed Transaction
    final serializedSignedTransaction =
        TransactionManager.serializeSignedTransferTransaction(
      transaction,
      signature,
    );

    final encodedTransaction =
        TransactionManager.encodeSerialization(serializedSignedTransaction);

    // Broadcast Transaction
    return await exponentialBackoff(
      getResult: () => provider.broadcastTransaction(encodedTransaction),
    );
  }

  /// Gets user accessKey information
  Future<AccessKey> findAccessKey() async {
    return await provider.findAccessKey(
        accountId, KeyStore.publicKeyToString(keyPair.publicKey));
  }
}
