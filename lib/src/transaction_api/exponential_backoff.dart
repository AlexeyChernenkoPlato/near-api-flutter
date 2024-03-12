import 'package:flutter/foundation.dart';
import '../constants.dart';

const retryErrors = ['TIMEOUT_ERROR', 'UNKNOWN_TRANSACTION'];

Future<dynamic> exponentialBackoff({
  required Future<Map<String, dynamic>> Function() getResult,
  int waitTime = Constants.requestRetryWait,
  double waitBackoff = Constants.requestRetryWaitBackoff,
  int retryAttempts = 1,
  int retryNumber = Constants.requestRetryNumber,
}) async {
  final result = await getResult();

  if (result.containsKey('error') &&
      retryErrors.contains(result['error']['cause']?['name']) &&
      retryAttempts <= retryNumber) {
    final delay = Duration(milliseconds: waitTime.toInt());
    debugPrint(
      "Retrying request as it has timed out. Attempt [$retryAttempts/$retryNumber]. Delay=$delay. UnderlineError=${result['error']['cause']?['name']}",
    );
    await Future.delayed(delay);
    return await exponentialBackoff(
      getResult: getResult,
      waitTime: (waitTime * waitBackoff).toInt(),
      retryAttempts: retryAttempts + 1,
      retryNumber: retryNumber,
    );
  }

  return result;
}
