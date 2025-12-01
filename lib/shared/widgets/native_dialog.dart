import 'package:flutter/cupertino.dart';

Future<void> showNativeErrorDialog(BuildContext context, String message) {
  return showCupertinoDialog(
    context: context,
    builder:
        (context) => CupertinoAlertDialog(
          title: const Text('エラー'),
          content: Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
  );
}
