import 'package:flutter/material.dart';
import 'package:nes_ui/nes_ui.dart';

class DeletionDialogs {
  static Future<bool?> showDeleteMessageDialog(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final baseFontSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          constraints: BoxConstraints.tight(screenSize),
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(),
          child: NesDialog(
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with icon
                  Row(
                    children: [
                      NesContainer(
                        // width: isSmallScreen ? 32 : 36,
                        // height: isSmallScreen ? 32 : 36,
                        backgroundColor: Colors.red,
                        child: Center(
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.white,
                            size: isSmallScreen ? 16 : 18,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 12 : 16),
                      Expanded(
                        child: Text(
                          'DELETE MESSAGE',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Message content
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Are you sure you want to delete this message?',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'This action cannot be undone.',
                          style: TextStyle(
                            fontSize: baseFontSize,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: NesButton(
                          type: NesButtonType.normal,
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          child: Text(
                            'CANCEL',
                            style: TextStyle(
                              fontSize: baseFontSize,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      Flexible(
                        child: NesButton(
                          type: NesButtonType.error,
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          child: Text(
                            'DELETE',
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showDeleteChatDialog(
      BuildContext context, String chatName, bool isGroup) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final baseFontSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isGroupChat = isGroup;
        final title = isGroupChat ? 'DELETE GROUP' : 'DELETE CHAT';
        final actionText = isGroupChat ? 'DELETE GROUP' : 'DELETE CHAT';

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16.0 : 24.0,
            vertical: 16.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 450,
              minWidth: isSmallScreen ? 300 : 350,
            ),
            child: NesDialog(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        NesContainer(
                          width: isSmallScreen ? 32 : 36,
                          height: isSmallScreen ? 32 : 36,
                          backgroundColor: Colors.red,
                          child: Center(
                            child: NesBlinker(
                              child: Icon(
                                isGroupChat
                                    ? Icons.group_remove
                                    : Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Message content
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isGroupChat) ...[
                            Text(
                              'You are about to delete:',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 8),
                            NesContainer(
                              padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                              backgroundColor: Colors.grey[100],
                              child: Center(
                                child: Text(
                                  '"$chatName"',
                                  style: TextStyle(
                                    fontSize: baseFontSize,
                                    color: Colors.red,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'This will permanently delete the group and all messages for all participants.',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ] else ...[
                            Text(
                              'Are you sure you want to delete this conversation?',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'All messages will be permanently removed.',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Warning note
                    NesContainer(
                      padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                      backgroundColor: Colors.orange[50],
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_outlined,
                            color: Colors.orange[800],
                            size: isSmallScreen ? 16 : 18,
                          ),
                          SizedBox(width: isSmallScreen ? 8 : 12),
                          Expanded(
                            child: Text(
                              'This action cannot be undone!',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: NesButton(
                            type: NesButtonType.normal,
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text(
                              'CANCEL',
                              style: TextStyle(
                                fontSize: baseFontSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Flexible(
                          child: NesButton(
                            type: NesButtonType.error,
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text(
                              actionText,
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<bool?> showLeaveGroupDialog(
      BuildContext context, String groupName) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final baseFontSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16.0 : 24.0,
            vertical: 16.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              minWidth: isSmallScreen ? 280 : 320,
            ),
            child: NesDialog(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with icon
                    Row(
                      children: [
                        NesContainer(
                          width: isSmallScreen ? 32 : 36,
                          height: isSmallScreen ? 32 : 36,
                          backgroundColor: Colors.orange,
                          child: Center(
                            child: Icon(
                              Icons.exit_to_app,
                              color: Colors.white,
                              size: isSmallScreen ? 16 : 18,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Text(
                            'LEAVE GROUP',
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Message content
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You are about to leave:',
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 8),
                          NesContainer(
                            padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
                            backgroundColor: Colors.grey[100],
                            child: Center(
                              child: Text(
                                '"$groupName"',
                                style: TextStyle(
                                  fontSize: baseFontSize,
                                  color: Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'You will need to be invited again to rejoin this group.',
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.orange[700],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: NesButton(
                            type: NesButtonType.normal,
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text(
                              'STAY',
                              style: TextStyle(
                                fontSize: baseFontSize,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 8 : 12),
                        Flexible(
                          child: NesButton(
                            type: NesButtonType.warning,
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            child: Text(
                              'LEAVE',
                              style: TextStyle(
                                fontSize: baseFontSize,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
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
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20.0),
          child: NesDialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with success icon
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          title.toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Success message
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),

                  // OK button
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 80,
                      child: NesButton(
                        type: NesButtonType.success,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'OK',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showErrorDialog(
      BuildContext context, String title, String message) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final baseFontSize = isSmallScreen ? 10.0 : 12.0;
    final padding = isSmallScreen ? 16.0 : 20.0;

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16.0 : 24.0,
            vertical: 16.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 400,
              minWidth: isSmallScreen ? 280 : 320,
            ),
            child: NesDialog(
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with error icon
                    Row(
                      children: [
                        NesContainer(
                          width: isSmallScreen ? 32 : 36,
                          height: isSmallScreen ? 32 : 36,
                          backgroundColor: Colors.red,
                          child: Center(
                            child: NesBlinker(
                              child: Icon(
                                Icons.error_outline,
                                color: Colors.white,
                                size: isSmallScreen ? 16 : 18,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 12 : 16),
                        Expanded(
                          child: Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isSmallScreen ? 16 : 20),

                    // Error message
                    Flexible(
                      child: Text(
                        message,
                        style: TextStyle(
                          fontSize: baseFontSize,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 20 : 24),

                    // OK button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Flexible(
                        child: NesButton(
                          type: NesButtonType.error,
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: Text(
                            'OK',
                            style: TextStyle(
                              fontSize: baseFontSize,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
