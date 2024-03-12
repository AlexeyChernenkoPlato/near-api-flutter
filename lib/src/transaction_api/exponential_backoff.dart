import 'package:flutter/foundation.dart';
import '../constants.dart';

Future<dynamic> exponentialBackoff({
  required Future<Map<String, dynamic>> Function() getResult,
  int waitTime = Constants.requestRetryWait,
  double waitBackoff = Constants.requestRetryWaitBackoff,
  int retryAttempts = 1,
  int retryNumber = Constants.requestRetryNumber,
}) async {
  final result = await getResult();

  if (result.containsKey('error') &&
      result['error']['cause']?['name'] == 'TIMEOUT_ERROR' &&
      retryAttempts <= retryNumber) {
    final delay = Duration(milliseconds: waitTime.toInt());
    debugPrint(
      "Retrying request as it has timed out. Attempt [$retryAttempts/$retryNumber]. Delay=$delay",
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
