import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class DeletionDialogs {
  static Future<bool?> showDeleteMessageDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return NesDialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Row(
                  children: [
                    NesContainer(
                      width: 32,
                      height: 32,
                      backgroundColor: Colors.red,
                      child: Center(
                        child: Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'DELETE MESSAGE',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message content
                Text(
                  'Are you sure you want to delete this message?',
                  style: TextStyle(
                    ////fontFamily: 'VT323',
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NesButton(
                      type: NesButtonType.normal,
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NesButton(
                      type: NesButtonType.error,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        'DELETE',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showDeleteChatDialog(
      BuildContext context, String chatName, bool isGroup) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isGroupChat = isGroup;
        final title = isGroupChat ? 'DELETE GROUP' : 'DELETE CHAT';
        final actionText = isGroupChat ? 'DELETE GROUP' : 'DELETE CHAT';

        return NesDialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Row(
                  children: [
                    NesContainer(
                      width: 32,
                      height: 32,
                      backgroundColor: Colors.red,
                      child: Center(
                        child: NesBlinker(
                          child: Icon(
                            isGroupChat
                                ? Icons.group_remove
                                : Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message content
                if (isGroupChat) ...[
                  Text(
                    'You are about to delete:',
                    style: TextStyle(
                      // ////fontFamily: 'VT323',
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  NesContainer(
                    padding: const EdgeInsets.all(8),
                    backgroundColor: Colors.grey[100],
                    child: Center(
                      child: Text(
                        '"$chatName"',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This will permanently delete the group and\nall messages for all participants.',
                    style: TextStyle(
                      ////fontFamily: 'VT323',
                      fontSize: 10,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ] else ...[
                  Text(
                    'Are you sure you want to delete\nthis conversation?',
                    style: TextStyle(
                      ////fontFamily: 'VT323',
                      fontSize: 10,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All messages will be permanently removed.',
                    style: TextStyle(
                      ////fontFamily: 'VT323',
                      fontSize: 10,
                      color: Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),

                // Warning note
                NesContainer(
                  padding: const EdgeInsets.all(8),
                  backgroundColor: Colors.orange[50],
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_outlined,
                        color: Colors.orange[800],
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This action cannot be undone!',
                          style: TextStyle(
                            ////fontFamily: 'VT323',
                            fontSize: 10,
                            color: Colors.orange[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NesButton(
                      type: NesButtonType.normal,
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NesButton(
                      type: NesButtonType.error,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        actionText,
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showLeaveGroupDialog(
      BuildContext context, String groupName) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return NesDialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with icon
                Row(
                  children: const [
                    NesContainer(
                      width: 32,
                      height: 32,
                      backgroundColor: Colors.orange,
                      child: Center(
                        child: Icon(
                          Icons.exit_to_app,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'LEAVE GROUP',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Message content
                Text(
                  'You are about to leave:',
                  style: TextStyle(
                    ////fontFamily: 'VT323',
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                NesContainer(
                  padding: const EdgeInsets.all(8),
                  backgroundColor: Colors.grey[100],
                  child: Center(
                    child: Text(
                      '"$groupName"',
                      style: TextStyle(
                        ////fontFamily: 'PressStart2P',
                        fontSize: 10,
                        color: Colors.orange,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'You will need to be invited again\nto rejoin this group.',
                  style: TextStyle(
                    ////fontFamily: 'VT323',
                    fontSize: 10,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    NesButton(
                      type: NesButtonType.normal,
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(
                        'STAY',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    NesButton(
                      type: NesButtonType.warning,
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(
                        'LEAVE',
                        style: TextStyle(
                          ////fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showSuccessDialog(
      BuildContext context, String title, String message) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return NesDialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with success icon
                Row(
                  children: [
                    NesContainer(
                      width: 32,
                      height: 32,
                      backgroundColor: Colors.green,
                      child: const Center(
                        child: Icon(
                          Icons.check_circle_outline,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          //fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Success message
                Text(
                  message,
                  style: TextStyle(
                    //fontFamily: 'VT323',
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // OK button
                Align(
                  alignment: Alignment.centerRight,
                  child: NesButton(
                    type: NesButtonType.success,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        //fontFamily: 'PressStart2P',
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> showErrorDialog(
      BuildContext context, String title, String message) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return NesDialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with error icon
                Row(
                  children: [
                    NesContainer(
                      width: 32,
                      height: 32,
                      backgroundColor: Colors.red,
                      child: Center(
                        child: NesBlinker(
                          child: Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title.toUpperCase(),
                        style: TextStyle(
                          //fontFamily: 'PressStart2P',
                          fontSize: 10,
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Error message
                Text(
                  message,
                  style: TextStyle(
                    // //fontFamily: 'VT323',
                    fontSize: 10,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // OK button
                Align(
                  alignment: Alignment.centerRight,
                  child: NesButton(
                    type: NesButtonType.error,
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(
                      'OK',
                      style: TextStyle(
                        // //fontFamily: 'PressStart2P',
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
