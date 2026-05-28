import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Modern Chat Input Widget with Smart Suggestions and Enhanced UX
class AIChatInputWidget extends StatefulWidget {
  final Function(String message) onSendMessage;
  final Function(String message, File file, String fileType, String fileName)? onSendWithFile;
  final bool isLoading;

  const AIChatInputWidget({
    super.key,
    required this.onSendMessage,
    this.onSendWithFile,
    this.isLoading = false,
  });

  @override
  State<AIChatInputWidget> createState() => _AIChatInputWidgetState();
}

class _AIChatInputWidgetState extends State<AIChatInputWidget>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  late AnimationController _sendButtonController;
  late Animation<double> _sendButtonScale;
  late AnimationController _inputFieldController;
  late Animation<double> _inputFieldElevation;
  bool _isFocused = false;
  File? _pendingFile;
  String? _pendingFileType;
  String? _pendingFileName;

  // Smart suggestions for learning context
  final List<String> _smartSuggestions = [
    "Explain this concept",
    "Give me examples",
    "Help with practice questions",
    "Summarize the key points",
    "What should I focus on?",
  ];

  @override
  void initState() {
    super.initState();
    _sendButtonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _sendButtonScale = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _sendButtonController,
      curve: Curves.easeInOut,
    ));

    _inputFieldController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _inputFieldElevation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _inputFieldController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _textController.dispose();
    _sendButtonController.dispose();
    _inputFieldController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _textController.text.trim();
    if (widget.isLoading) return;
    if (_pendingFile != null) {
      if (widget.onSendWithFile != null) {
        widget.onSendWithFile!(message, _pendingFile!, _pendingFileType!, _pendingFileName!);
      }
      setState(() {
        _pendingFile = null;
        _pendingFileType = null;
        _pendingFileName = null;
      });
      _textController.clear();
      _sendButtonController.forward().then((_) => _sendButtonController.reverse());
    } else if (message.isNotEmpty) {
      _textController.clear();
      widget.onSendMessage(message);
      _sendButtonController.forward().then((_) => _sendButtonController.reverse());
    }
  }

  Future<void> _pickAttachment(BuildContext context) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? AppTheme.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.image_rounded, color: AppTheme.primary),
                ),
                title: Text('Upload Image',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppTheme.blackColor)),
                subtitle: Text('JPG, PNG, WEBP',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C4DFF).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_rounded, color: Color(0xFF7C4DFF)),
                ),
                title: Text('Upload Document',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : AppTheme.blackColor)),
                subtitle: Text('PDF, DOCX, TXT',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickDocument();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked != null) {
        setState(() {
          _pendingFile = File(picked.path);
          _pendingFileType = 'image';
          _pendingFileName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
        withData: false,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _pendingFile = File(result.files.single.path!);
          _pendingFileType = 'document';
          _pendingFileName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint('Document pick error: $e');
    }
  }

  void _insertSuggestion(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasPending = _pendingFile != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? AppTheme.darkCard : AppTheme.surface,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(28),
        ),
        border: Border(
          top: BorderSide(
            color: isDarkMode
              ? AppTheme.darkTextSecondary.withOpacity(0.3)
              : AppTheme.borderGrey.withOpacity(0.5),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
              ? Colors.black.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pending attachment preview
          if (hasPending) ...[  
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: (_pendingFileType == 'image'
                        ? AppTheme.primary
                        : const Color(0xFF7C4DFF))
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (_pendingFileType == 'image'
                          ? AppTheme.primary
                          : const Color(0xFF7C4DFF))
                      .withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _pendingFileType == 'image'
                        ? Icons.image_rounded
                        : Icons.description_rounded,
                    size: 18,
                    color: _pendingFileType == 'image'
                        ? AppTheme.primary
                        : const Color(0xFF7C4DFF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _pendingFileName ?? 'Attachment',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : AppTheme.blackColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() {
                      _pendingFile = null;
                      _pendingFileType = null;
                      _pendingFileName = null;
                    }),
                    child: Icon(Icons.close_rounded,
                        size: 16, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],

          // Smart Suggestions Bar (hidden when attachment pending)
          if (!hasPending && !_isFocused && _textController.text.isEmpty)
            SizedBox(
              height: 32,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _smartSuggestions.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? AppTheme.primary.withOpacity(0.2)
                          : AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _insertSuggestion(_smartSuggestions[index]),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              _smartSuggestions[index],
                              style: TextStyle(
                                color: AppTheme.primary,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          if (!hasPending) const SizedBox(height: 8),

          // Modern Input Field with Animations
          Row(
            children: [
              // Attachment button
              GestureDetector(
                onTap: () => _pickAttachment(context),
                child: Container(
                  width: 44,
                  height: 44,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: hasPending
                        ? (_pendingFileType == 'image'
                                ? AppTheme.primary
                                : const Color(0xFF7C4DFF))
                            .withOpacity(0.15)
                        : (isDarkMode
                            ? Colors.white.withOpacity(0.07)
                            : Colors.grey.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: hasPending
                          ? (_pendingFileType == 'image'
                                  ? AppTheme.primary
                                  : const Color(0xFF7C4DFF))
                              .withOpacity(0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Icon(
                    Icons.attach_file_rounded,
                    size: 20,
                    color: hasPending
                        ? (_pendingFileType == 'image'
                            ? AppTheme.primary
                            : const Color(0xFF7C4DFF))
                        : (isDarkMode ? Colors.white54 : Colors.grey[600]),
                  ),
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _inputFieldElevation,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.1),
                            blurRadius: _inputFieldElevation.value * 2,
                            offset: Offset(0, _inputFieldElevation.value),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _textController,
                        onSubmitted: (_) => _sendMessage(),
                        enabled: !widget.isLoading,
                        onTap: () {
                          setState(() {
                            _isFocused = true;
                          });
                          _inputFieldController.forward();
                        },
                        onTapOutside: (_) {
                          setState(() {
                            _isFocused = false;
                          });
                          _inputFieldController.reverse();
                        },
                        onChanged: (text) {
                          if (text.isNotEmpty && !_isFocused) {
                            setState(() {
                              _isFocused = true;
                            });
                            _inputFieldController.forward();
                          }
                        },
                        style: TextStyle(
                          color: isDarkMode ? AppTheme.darkTextPrimary : AppTheme.blackColor,
                          fontSize: 15,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ask me about your learning...',
                          hintStyle: TextStyle(
                            fontSize: 15,
                            color: isDarkMode 
                              ? AppTheme.darkTextSecondary 
                              : Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                          filled: true,
                          fillColor: isDarkMode ? AppTheme.darkSurface : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: isDarkMode
                                ? AppTheme.darkTextSecondary.withOpacity(0.3)
                                : AppTheme.borderGrey,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: isDarkMode
                                ? AppTheme.darkTextSecondary.withOpacity(0.3)
                                : AppTheme.borderGrey,
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: const BorderSide(
                              color: AppTheme.primary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 18,
                          ),
                          suffixIcon: widget.isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppTheme.primary,
                                      ),
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Animated Send Button
              ScaleTransition(
                scale: _sendButtonScale,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primary,
                        AppTheme.primaryDark,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: widget.isLoading ? null : _sendMessage,
                    icon: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(minWidth: 50, minHeight: 50),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
