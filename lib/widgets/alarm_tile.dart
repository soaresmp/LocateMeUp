import 'package:flutter/material.dart';

import '../models/alarm.dart';

class AlarmTile extends StatelessWidget {
  final Alarm alarm;
  final double? distanceMeters;
  final bool isLocationEnabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  const AlarmTile({
    super.key,
    required this.alarm,
    this.distanceMeters,
    required this.isLocationEnabled,
    required this.onToggle,
    required this.onDelete,
  });

  /// Formats metres as km with Swiss-style apostrophe thousands separator,
  /// matching the original iOS number formatter behaviour.
  String _formatDistance(double metres) {
    final km = metres / 1000;
    final formatted = km.toStringAsFixed(2);
    final parts = formatted.split('.');
    final intPart = parts[0];
    final fracPart = parts[1];
    final buf = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buf.write("'");
      buf.write(intPart[i]);
    }
    return "${buf.toString()}.$fracPart km";
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        title: Text(alarm.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          alarm.subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (distanceMeters != null)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _formatDistance(distanceMeters!),
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey),
                ),
              ),
            Switch(
              value: alarm.isOn && isLocationEnabled,
              onChanged: isLocationEnabled ? onToggle : null,
            ),
          ],
        ),
      ),
    );
  }
}
