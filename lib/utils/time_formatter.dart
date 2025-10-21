// class TimeFormatter {
//   static String formatMessageTime(DateTime timestamp) {
//     final localTime = timestamp.toLocal();
//     return '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
//   }

//   static String formatRelativeTime(DateTime dateTime) {
//     final now = DateTime.now().toLocal();
//     final localDateTime = dateTime.toLocal();
//     final difference = now.difference(localDateTime);

//     if (difference.inDays > 7) {
//       return '${localDateTime.day}/${localDateTime.month}/${localDateTime.year}';
//     } else if (difference.inDays > 0) {
//       return '${difference.inDays}d';
//     } else if (difference.inHours > 0) {
//       return '${difference.inHours}h';
//     } else if (difference.inMinutes > 0) {
//       return '${difference.inMinutes}m';
//     } else {
//       return 'Now';
//     }
//   }

//   static String formatDateHeader(DateTime date) {
//     final now = DateTime.now().toLocal();
//     final today = DateTime(now.year, now.month, now.day);
//     final yesterday = today.subtract(const Duration(days: 1));
//     final messageDate = DateTime(date.year, date.month, date.day);

//     if (messageDate == today) {
//       return 'Today';
//     } else if (messageDate == yesterday) {
//       return 'Yesterday';
//     } else {
//       return '${date.day}/${date.month}/${date.year}';
//     }
//   }
// }
