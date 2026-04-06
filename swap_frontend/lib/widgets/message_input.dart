import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../pages/home_page.dart';

/// Input widget for composing and sending messages.
class MessageInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool sending;
  final VoidCallback? onAttachment;
  final Uint8List? pendingFileBytes;
  final String? pendingFileName;
  final VoidCallback? onRemovePendingFile;
  final bool uploading;

  const MessageInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.sending = false,
    this.onAttachment,
    this.pendingFileBytes,
    this.pendingFileName,
    this.onRemovePendingFile,
    this.uploading = false,
  });

  bool get _isPendingImage {
    if (pendingFileName == null) return false;
    final ext = pendingFileName!.split('.').last.toLowerCase();
    return {'jpg', 'jpeg', 'png', 'gif', 'webp'}.contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HomePage.surface,
        border: Border(top: BorderSide(color: HomePage.line)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pending file preview
            if (pendingFileBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _isPendingImage
                      ? _buildImagePreview()
                      : _buildFilePreview(),
                ),
              ),
            Row(
              children: [
                if (onAttachment != null)
                  IconButton(
                    onPressed: (sending || uploading) ? null : onAttachment,
                    icon: Icon(
                      Icons.attach_file,
                      color: (sending || uploading)
                          ? HomePage.textMuted.withOpacity(0.5)
                          : HomePage.textMuted,
                    ),
                  ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => onSend(),
                    style: const TextStyle(color: HomePage.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: const TextStyle(color: HomePage.textMuted),
                      filled: true,
                      fillColor: HomePage.surfaceAlt,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: HomePage.line),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: HomePage.line),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: HomePage.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: HomePage.accent,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: (sending || uploading) ? null : onSend,
                    icon: (sending || uploading)
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.memory(
            pendingFileBytes!,
            width: 120,
            height: 120,
            fit: BoxFit.cover,
          ),
        ),
        _buildRemoveButton(),
        if (uploading) _buildUploadingOverlay(),
      ],
    );
  }

  Widget _buildFilePreview() {
    return Stack(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: HomePage.surfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: HomePage.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _fileIcon(pendingFileName ?? ''),
                color: HomePage.accent,
                size: 28,
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  pendingFileName ?? 'file',
                  style: const TextStyle(
                    color: HomePage.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemovePendingFile,
                child: const Icon(Icons.close, size: 18, color: HomePage.textMuted),
              ),
            ],
          ),
        ),
        if (uploading) _buildUploadingOverlay(),
      ],
    );
  }

  Widget _buildRemoveButton() {
    return Positioned(
      top: 4,
      right: 4,
      child: GestureDetector(
        onTap: onRemovePendingFile,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(4),
          child: const Icon(
            Icons.close,
            size: 16,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildUploadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
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
}
