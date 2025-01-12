import 'package:flutter/material.dart';
import '../models/export_format.dart';

class ExportFormatDialog extends StatelessWidget {
  const ExportFormatDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Format'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('XML'),
            onTap: () => Navigator.pop(context, ExportFormat.xml),
          ),
          ListTile(
            title: const Text('PDF'),
            onTap: () => Navigator.pop(context, ExportFormat.pdf),
          ),
        ],
      ),
    );
  }
}
