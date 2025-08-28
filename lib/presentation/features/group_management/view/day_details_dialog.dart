import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';

class DayDetailsDialog extends StatelessWidget {
  final Map<String, dynamic> dayDetails;
  final String? userName;
  final bool isCurrentUser;

  const DayDetailsDialog({
    Key? key,
    required this.dayDetails,
    this.userName,
    this.isCurrentUser = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final date = dayDetails['date'] as String;
    final timeSlots = dayDetails['time_slots'] as List<dynamic>;
    final notes = dayDetails['notes'] as String? ?? '';
    final availabilityId = dayDetails['availability_id'];
    final userId = dayDetails['user_id'];
    final message = dayDetails['message'] as String?;

    // Parse and format the date
    DateTime parsedDate;
    try {
      parsedDate = DateTime.parse(date);
    } catch (e) {
      parsedDate = DateTime.now();
    }

    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(parsedDate);

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCurrentUser
                ? 'Your Availability'
                : '${userName ?? "User"}\'s Availability',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Show message if no availability data
              if (message != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    message,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Show time slots if available
              if (timeSlots.isNotEmpty) ...[
                const Text(
                  'Time Slots:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...timeSlots.map<Widget>((slot) => _buildTimeSlotCard(slot)),
              ],

              // Show notes if available
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Text(
                    notes,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],

              if (availabilityId != null || userId != null) ...[
                const SizedBox(height: 16),
                // Container(
                //   padding: const EdgeInsets.all(8),
                //   decoration: BoxDecoration(
                //     color: Colors.grey[50],
                //     borderRadius: BorderRadius.circular(6),
                //   ),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       if (userId != null)
                //         Text(
                //           'User ID: $userId',
                //           style: TextStyle(
                //             fontSize: 12,
                //             color: Colors.grey[600],
                //           ),
                //         ),
                //       if (availabilityId != null)
                //         Text(
                //           'Availability ID: $availabilityId',
                //           style: TextStyle(
                //             fontSize: 12,
                //             color: Colors.grey[600],
                //           ),
                //         ),
                //     ],
                //   ),
                // ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildTimeSlotCard(dynamic slot) {
    final name = slot['name'] as String? ?? 'Unknown';
    final time = slot['time'] as String? ?? 'No time specified';
    final type = slot['type'] as String? ?? '';
    final status = slot['status'] as String? ?? 'unknown';
    final statusDisplay = slot['status_display'] as String? ?? status;

    // Determine colors based on status
    Color statusColor;
    Color statusBackgroundColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'available':
        statusColor = AppColors.availableGreen;
        statusBackgroundColor = AppColors.availableGreen.withOpacity(0.1);
        statusIcon = Icons.check_circle;
        break;
      case 'busy':
        statusColor = AppColors.unavailableRed;
        statusBackgroundColor = AppColors.unavailableRed.withOpacity(0.1);
        statusIcon = Icons.cancel;
        break;
      case 'maybe':
        statusColor = Colors.orange;
        statusBackgroundColor = Colors.orange.withOpacity(0.1);
        statusIcon = Icons.help;
        break;
      default:
        statusColor = Colors.grey;
        statusBackgroundColor = Colors.grey.withOpacity(0.1);
        statusIcon = Icons.info;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statusDisplay,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}