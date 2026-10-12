import 'package:flutter/material.dart';

class MusicErrorBanner extends StatelessWidget {
  const MusicErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onDismiss,
  });
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context)
                      .colorScheme
                      .onErrorContainer,
                ),
                onPressed: onRetry,
                child: const Text('Thử lại'),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Đóng thông báo',
          onPressed: onDismiss,
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ],
    ),
  );
}

class LibraryErrorNotice extends StatelessWidget {
  const LibraryErrorNotice({
    super.key,
    required this.message,
    required this.onDismiss,
  });
  final String message;
  final VoidCallback onDismiss;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 16),
    padding: const EdgeInsets.fromLTRB(16, 10, 6, 10),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.errorContainer,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            message,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
        ),
        IconButton(
          tooltip: 'Đóng thông báo thư viện',
          onPressed: onDismiss,
          icon: Icon(
            Icons.close_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
        ),
      ],
    ),
  );
}
