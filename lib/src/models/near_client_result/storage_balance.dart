import 'package:near_api_flutter/src/constants.dart';

class StorageBalance {
  final double total;
  final double available;

  bool get hasEnoughMinimum => total >= Constants.minStorageDeposit;

  const StorageBalance({
    required this.total,
    required this.available,
  });

  factory StorageBalance.fromJson(Map<String, dynamic> json) {
    return StorageBalance(
      total: double.parse(json['total']),
      available: double.parse(json['available']),
    );
  }

  factory StorageBalance.empty() {
    return const StorageBalance(
      total: 0.0,
      available: 0.0,
    );
  }
}
