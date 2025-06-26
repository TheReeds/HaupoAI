// lib/presentation/widgets/wellness/priority_alert_card.dart
import 'package:flutter/material.dart';

class PriorityAlertCard extends StatelessWidget {
  final Map<String, dynamic> alert;

  const PriorityAlertCard({
    super.key,
    required this.alert,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alertType = alert['type'] as String;

    Color alertColor;
    IconData alertIcon;

    switch (alertType) {
      case 'warning':
        alertColor = Colors.orange;
        alertIcon = Icons.warning_rounded;
        break;
      case 'error':
        alertColor = Colors.red;
        alertIcon = Icons.error_rounded;
        break;
      case 'info':
        alertColor = Colors.blue;
        alertIcon = Icons.info_rounded;
        break;
      default:
        alertColor = Colors.grey;
        alertIcon = Icons.info_rounded;
    }

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: alertColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    alertIcon,
                    color: alertColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert['title'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: alertColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                alert['message'] as String,
                style: theme.textTheme.bodyMedium,
              ),
              if (alert['recommendations'] != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Recomendaciones:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                ...(alert['recommendations'] as List<String>).map(
                      (recommendation) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: alertColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            recommendation,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}