import 'dart:async';
import 'package:syntax_highlight/syntax_highlight.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CodePreviewPane extends StatefulWidget {
  final String code;
  final Highlighter highlighter;

  const CodePreviewPane({
    super.key,
    required this.code,
    required this.highlighter,
  });

  @override
  State<CodePreviewPane> createState() => _CodePreviewPaneState();
}

class _CodePreviewPaneState extends State<CodePreviewPane> {
  bool _copied = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _onCopy() {
    Clipboard.setData(ClipboardData(text: widget.code));
    setState(() => _copied = true);

    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final highlighted = widget.highlighter.highlight(widget.code);

    return Stack(
      children: [
        SingleChildScrollView(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 300),
              child: RichText(text: highlighted),
            ),
          ),
        ),

        Positioned(
          right: 8,
          top: 8,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: _copied ? _buildSuccessChip() : _buildCopyChip(),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyChip() {
    return Material(
      key: const ValueKey('copy'),
      color: Colors.white,
      elevation: 1,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _onCopy,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.copy, size: 16, color: Colors.black87),
              SizedBox(width: 8),
              Text('Copy', style: TextStyle(color: Colors.black87)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessChip() {
    return Material(
      key: const ValueKey('copied'),
      color: Colors.green,
      elevation: 1,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check, size: 16, color: Colors.white),
            SizedBox(width: 8),
            Text('Copied!', style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
