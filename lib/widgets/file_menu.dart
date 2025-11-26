import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/document_provider.dart';

class FileMenu extends StatelessWidget {
  const FileMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final document = context.watch<DocumentProvider>();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuItem(
            context,
            'New',
            Icons.note_add_outlined,
            () => _newDocument(context),
            isDark,
          ),
          const SizedBox(width: 4),
          _buildMenuItem(
            context,
            'Open',
            Icons.folder_open,
            () => _openDocument(context),
            isDark,
          ),
          const SizedBox(width: 4),
          _buildMenuItem(
            context,
            'Save As',
            Icons.save_as,
            () => _saveAs(context),
            isDark,
          ),
          const SizedBox(width: 12),
          _buildFileInfo(context, document, isDark),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
    bool isDark,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInfo(BuildContext context, DocumentProvider document, bool isDark) {
    final fileName = document.filePath?.split('/').last ??
                    document.filePath?.split('\\').last ??
                    'Untitled';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.description,
          size: 14,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 4),
        Text(
          fileName,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
        if (document.hasUnsavedChanges) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.circle,
            size: 8,
            color: isDark ? Colors.blue : Colors.blue,
          ),
        ],
      ],
    );
  }

  Future<void> _newDocument(BuildContext context) async {
    final document = context.read<DocumentProvider>();

    // If there are unsaved changes, confirm
    if (document.hasUnsavedChanges) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unsaved Changes'),
          content: const Text(
            'You have unsaved changes. Do you want to create a new document?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('New Document'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    document.newDocument();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New document created'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openDocument(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['md', 'txt'],
      dialogTitle: 'Open Document',
    );

    if (result == null || result.files.isEmpty) return;

    final filePath = result.files.first.path;
    if (filePath == null) return;

    try {
      final document = context.read<DocumentProvider>();
      await document.loadFile(filePath);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opened: ${result.files.first.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveAs(BuildContext context) async {
    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Save Document As',
      fileName: 'untitled.md',
      type: FileType.custom,
      allowedExtensions: ['md'],
    );

    if (path == null) return;

    try {
      final document = context.read<DocumentProvider>();
      await document.saveAs(path);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved: ${path.split('/').last}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving file: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
