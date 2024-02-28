import 'dart:typed_data';
import 'package:convert/convert.dart';
import 'package:ed25519_hd_key/ed25519_hd_key.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:ed25519_edwards/ed25519_edwards.dart' as ed;

import '../near_api_flutter.dart';

class NearWallet {
  final String accountId;
  final KeyPair keyPair;

  NearWallet(this.accountId, this.keyPair);

  static Future<NearWallet> fromSeedPhrase({
    required String mnemonic,
    String? namedAccountId,
  }) async {
    final seed = bip39.mnemonicToSeed(mnemonic);
    final data = await ED25519_HD_KEY.derivePath("m/44'/397'/0'", seed);

    const privateKeySize = 64;
    final privateKeyBytes = ed.newKeyFromSeed(Uint8List.fromList(data.key));
    final publicKeyBytes = privateKeyBytes.bytes.sublist(32, privateKeySize);

    return NearWallet(
      namedAccountId ?? hex.encode(publicKeyBytes),
      KeyPair(
        PrivateKey(privateKeyBytes.bytes),
        PublicKey(publicKeyBytes),
      ),
    );
  }
}
