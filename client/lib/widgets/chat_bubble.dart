import 'package:flutter/material.dart';

class ChatBubble extends StatefulWidget {
  final String message;
  final bool isOwnMessage;
  final DateTime timestamp;
  final String username;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isOwnMessage,
    required this.timestamp,
    required this.username,
  });

  @override
  State<ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<ChatBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Align(
              alignment: widget.isOwnMessage
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.8,
                ),
                child: Column(
                  crossAxisAlignment: widget.isOwnMessage
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    // Username
                    if (!widget.isOwnMessage) ...[
                      Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Text(
                          widget.username,
                          style: TextStyle(
                            fontSize: 12,
                            color: const Color(0xFF00BCD4),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],

                    // Message bubble
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: widget.isOwnMessage
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF00BCD4), Color(0xFF1E88E5)],
                              )
                            : LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF2D2D35),
                                  const Color(0xFF1A1A1F),
                                ],
                              ),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: widget.isOwnMessage
                              ? const Radius.circular(20)
                              : const Radius.circular(4),
                          bottomRight: widget.isOwnMessage
                              ? const Radius.circular(4)
                              : const Radius.circular(20),
                        ),
                        border: Border.all(
                          color: widget.isOwnMessage
                              ? const Color(0xFF00BCD4).withOpacity(0.3)
                              : const Color(0xFF2D2D35),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: widget.isOwnMessage
                                ? const Color(0xFF00BCD4).withOpacity(0.2)
                                : Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                          if (widget.isOwnMessage)
                            BoxShadow(
                              color: const Color(0xFF00BCD4).withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Message text
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.isOwnMessage
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Timestamp and username for own messages
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.isOwnMessage) ...[
                                Text(
                                  widget.username,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black.withOpacity(0.7),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  width: 3,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                _formatTime(widget.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isOwnMessage
                                      ? Colors.black.withOpacity(0.6)
                                      : const Color(0xFF9E9E9E),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ],
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

  String _formatTime(DateTime time) {
    return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
  }
}
