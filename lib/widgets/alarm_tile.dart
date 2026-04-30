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

  String _formatDistance(double metres) {
    if (metres < 1000) return '${metres.round()} m';
    final km = metres / 1000;
    return km < 10 ? '${km.toStringAsFixed(1)} km' : '${km.round()} km';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = alarm.isOn && isLocationEnabled;
    final primary = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;

    return Dismissible(
      key: Key(alarm.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 26),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: active ? 2 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: active
                ? primary.withOpacity(0.3)
                : theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        color: active
            ? Color.alphaBlend(primary.withOpacity(0.06), theme.colorScheme.surface)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 8, 18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alarm.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 22,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                        color: active ? onSurface : onSurface.withOpacity(0.4),
                      ),
                    ),
                    if (alarm.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        alarm.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: active
                              ? onSurface.withOpacity(0.6)
                              : onSurface.withOpacity(0.3),
                        ),
                      ),
                    ],
                    if (distanceMeters != null) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.near_me_outlined,
                            size: 13,
                            color: active ? primary : onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDistance(distanceMeters!),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: active ? primary : onSurface.withOpacity(0.3),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Switch(
                value: active,
                onChanged: isLocationEnabled ? onToggle : null,
                activeColor: primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
