import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Dialog for uploading CSV with title and source input
class UploadDialog extends StatefulWidget {
  final PlatformFile? preSelectedFile;
  final Function(PlatformFile file, String title, String source) onUpload;

  const UploadDialog({
    super.key,
    this.preSelectedFile,
    required this.onUpload,
  });

  @override
  State<UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<UploadDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _sourceController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedFile = widget.preSelectedFile;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sourceController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      setState(() => _isLoading = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      if (_selectedFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a CSV file'),
            backgroundColor: AppColors.errorRed,
          ),
        );
        return;
      }

      widget.onUpload(
        _selectedFile!,
        _titleController.text.trim(),
        _sourceController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Dialog(
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 420,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPurple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.upload_file_rounded,
                          color: AppColors.primaryPurple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload CSV',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Add new leads from a CSV file',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.mediumGrey,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(context),
                        color: AppColors.mediumGrey,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // File picker
                  InkWell(
                    onTap: _isLoading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedFile != null
                              ? AppColors.primaryPurple
                              : AppColors.borderGrey,
                          width: _selectedFile != null ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _selectedFile != null
                            ? AppColors.primaryPurple.withValues(alpha: 0.05)
                            : AppColors.softLavender,
                      ),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                Icon(
                                  _selectedFile != null
                                      ? Icons.check_circle_rounded
                                      : Icons.cloud_upload_rounded,
                                  size: 36,
                                  color: _selectedFile != null
                                      ? AppColors.primaryPurple
                                      : AppColors.mediumGrey,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _selectedFile != null
                                      ? _selectedFile!.name
                                      : 'Tap to select CSV file',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _selectedFile != null
                                            ? AppColors.primaryPurple
                                            : AppColors.mediumGrey,
                                        fontWeight: _selectedFile != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (_selectedFile != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(_selectedFile!.size / 1024).toStringAsFixed(1)} KB',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: AppColors.mediumGrey,
                                        ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g., Organic Produce Near Me',
                      prefixIcon: const Icon(Icons.title_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Source field
                  TextFormField(
                    controller: _sourceController,
                    decoration: InputDecoration(
                      labelText: 'Source / Platform',
                      hintText: 'e.g., Google Maps, Bing Maps',
                      prefixIcon: const Icon(Icons.source_rounded, size: 20),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a source';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Upload'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
