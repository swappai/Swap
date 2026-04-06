import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/conversation.dart';
import '../pages/home_page.dart';

/// A bubble displaying a single message.
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  static const _whatsappBlue = Color(0xFF53BDEB);

  static bool _isImageUrl(String url) {
    final path = Uri.parse(url).path.toLowerCase();
    return path.endsWith('.jpg') || path.endsWith('.jpeg') ||
        path.endsWith('.png') || path.endsWith('.gif') ||
        path.endsWith('.webp');
  }

  bool get _hasImageAttachment =>
      message.attachmentUrl != null && _isImageUrl(message.attachmentUrl!);

  @override
  Widget build(BuildContext context) {
    // System messages have different styling
    if (message.type == MessageType.system) {
      return _buildSystemMessage();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: (_hasImageAttachment && message.content.trim().isEmpty) ? 4 : 14,
              vertical: (_hasImageAttachment && message.content.trim().isEmpty) ? 4 : 10,
            ),
            decoration: BoxDecoration(
              color: isMe ? HomePage.accent : HomePage.surface,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isMe ? 16 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 16),
              ),
              border: isMe ? null : Border.all(color: HomePage.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (message.attachmentUrl != null)
                  _isImageUrl(message.attachmentUrl!)
                      ? _buildAttachmentImage(context)
                      : _buildAttachmentFile(context),
                if (message.content.trim().isNotEmpty)
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isMe ? Colors.white : HomePage.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('HH:mm').format(message.sentAt),
                      style: TextStyle(
                        color: isMe ? Colors.white70 : HomePage.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      _buildStatusIcon(),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentImage(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: message.content.trim().isNotEmpty ? 8 : 0,
      ),
      child: GestureDetector(
        onTap: () => _showFullscreenImage(context, message.attachmentUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 200),
            child: Image.network(
              message.attachmentUrl!,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: 150,
                  color: isMe
                      ? Colors.white.withOpacity(0.1)
                      : HomePage.surfaceAlt,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: 100,
                  color: isMe
                      ? Colors.white.withOpacity(0.1)
                      : HomePage.surfaceAlt,
                  child: const Center(
                    child: Icon(Icons.broken_image, color: HomePage.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentFile(BuildContext context) {
    final filename = message.attachmentFilename ??
        Uri.parse(message.attachmentUrl!).pathSegments.lastOrNull ?? 'file';

    return Padding(
      padding: EdgeInsets.only(
        bottom: message.content.trim().isNotEmpty ? 8 : 0,
      ),
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(message.attachmentUrl!),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withOpacity(0.1)
                : HomePage.surfaceAlt,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _fileIcon(filename),
                color: isMe ? Colors.white70 : HomePage.accent,
                size: 32,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      style: TextStyle(
                        color: isMe ? Colors.white : HomePage.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Tap to open',
                      style: TextStyle(
                        color: isMe ? Colors.white54 : HomePage.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static IconData _fileIcon(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'zip':
        return Icons.folder_zip;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
  }

  static void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (message.readAt != null) {
      // Read — double blue ticks
      return const Icon(Icons.done_all, size: 14, color: _whatsappBlue);
    } else if (message.deliveredAt != null) {
      // Delivered — double grey ticks
      return const Icon(Icons.done_all, size: 14, color: Colors.white54);
    } else {
      // Sent — single grey tick
      return const Icon(Icons.done, size: 14, color: Colors.white54);
    }
  }

  Widget _buildSystemMessage() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: HomePage.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: HomePage.line),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: HomePage.textMuted,
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
