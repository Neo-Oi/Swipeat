import 'package:flutter/material.dart';

import '../services/location_service.dart';

Future<bool> showLocationPermissionDisclosure(BuildContext context) async {
  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('現在地の利用について'),
        content: const Text(
          '周辺の営業中のお店を探すため、検索時に現在地を使用します。\n\n'
          '現在地は店舗検索と距離計算にのみ利用し、バックグラウンドでは取得しません。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('あとで'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('許可して続ける'),
          ),
        ],
      );
    },
  );

  return accepted ?? false;
}

String locationFailureMessage(LocationAccessFailure failure) {
  switch (failure) {
    case LocationAccessFailure.serviceDisabled:
      return '端末の位置情報サービスがオフです。設定からオンにしてください。';
    case LocationAccessFailure.permissionDenied:
      return '位置情報が許可されませんでした。許可すると周辺のお店を検索できます。';
    case LocationAccessFailure.permissionDeniedForever:
      return '位置情報が拒否されています。端末の設定から許可してください。';
    case LocationAccessFailure.unavailable:
      return '現在地を取得できませんでした。しばらくしてから再度お試しください。';
    case LocationAccessFailure.disclosureDeclined:
      return '位置情報を許可すると周辺のお店を検索できます。';
  }
}
