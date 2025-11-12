import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_icons.dart';

class SwipeActionButton extends StatefulWidget {
  final String text;
  final VoidCallback onSwipeComplete;
  final List<List<dynamic>> icon;

  const SwipeActionButton({
    super.key,
    required this.text,
    required this.onSwipeComplete,
    this.icon = AppIcons.arrowRight,
  });

  @override
  State<SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<SwipeActionButton> {
  double _dragOffset = 0.0;
  bool _isCompleted = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonPadding = 32.0;
    final circleSize = 56.0;
    final maxDrag = screenWidth - buttonPadding * 2 - circleSize;

    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        if (!_isCompleted) {
          setState(() {
            _dragOffset = (_dragOffset + details.delta.dx).clamp(0.0, maxDrag);
          });
        }
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset >= maxDrag * 0.85 && !_isCompleted) {
          setState(() {
            _isCompleted = true;
            _dragOffset = maxDrag;
          });
          widget.onSwipeComplete();
        } else if (!_isCompleted) {
          setState(() {
            _dragOffset = 0.0;
          });
        }
      },
      child: Container(
        height: 64,
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: buttonPadding),
        decoration: BoxDecoration(
          color: AppTheme.accentColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: AppTheme.accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Text that stays in place
            Center(
              child: Text(
                widget.text,
                style: TextStyle(
                  color: _isCompleted
                      ? Colors.white
                      : AppTheme.textPrimary.withValues(alpha: 0.7),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Sliding circle tracker
            AnimatedPositioned(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeOut,
              left: _dragOffset,
              top: 4,
              bottom: 4,
              child: GestureDetector(
                onTap: () {
                  if (!_isCompleted && _dragOffset == 0) {
                    // Allow tap to start dragging
                    setState(() {
                      _dragOffset = maxDrag * 0.1;
                    });
                  }
                },
                child: Container(
                  width: circleSize,
                  decoration: BoxDecoration(
                    color: _isCompleted || _dragOffset > maxDrag * 0.5
                        ? AppTheme.accentColor
                        : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _isCompleted || _dragOffset > maxDrag * 0.5
                            ? AppTheme.accentColor.withValues(alpha: 0.4)
                            : Colors.black.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isCompleted || _dragOffset > maxDrag * 0.5
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 28,
                          )
                        : HugeIcon(
                            icon: widget.icon,
                            color: AppTheme.accentColor,
                            size: 24,
                          ),
                  ),
                ),
              ),
            ),
            // Progress indicator overlay
            if (_dragOffset > 0 && !_isCompleted)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragOffset + circleSize / 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(
                      alpha: (_dragOffset / maxDrag * 0.8).clamp(0.0, 0.8),
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

