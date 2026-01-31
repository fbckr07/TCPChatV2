import 'package:flutter/material.dart';
import 'package:tcpchatv2_client/config/app_constants.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isConnected;

  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.isConnected,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  bool _isEmpty = true;
  final FocusNode _focusNode = FocusNode();

  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      setState(() {
        _isEmpty = _controller.text.trim().isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final message = _controller.text.trim();
    if (message.isNotEmpty && widget.isConnected) {
      widget.onSendMessage(message);
      _controller.clear();

      // Button press animation
      _scaleController.forward().then((_) {
        _scaleController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A1F), Color(0xFF0A0A0F)],
        ),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00BCD4).withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Input field
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF2D2D35).withOpacity(0.8),
                      const Color(0xFF1A1A1F).withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? const Color(0xFF00BCD4)
                        : const Color(0xFF2D2D35),
                    width: _focusNode.hasFocus ? 2 : 1,
                  ),
                  boxShadow: [
                    if (_focusNode.hasFocus)
                      BoxShadow(
                        color: const Color(0xFF00BCD4).withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Row(
                    children: [
                      // Chat icon
                      Container(
                        padding: const EdgeInsets.only(left: 16, right: 8),
                        child: Icon(
                          Icons.chat_bubble_outline,
                          color: widget.isConnected
                              ? const Color(0xFF00BCD4)
                              : const Color(0xFF4A4A4A),
                          size: 22,
                        ),
                      ),

                      // Text input
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.isConnected,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.isConnected
                                ? AppConstants.hintTextMessage
                                : "Nicht verbunden...",
                            hintStyle: TextStyle(
                              color: widget.isConnected
                                  ? const Color(0xFF6E6E6E)
                                  : const Color(0xFF4A4A4A),
                              fontSize: 16,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 16,
                            ),
                          ),
                          maxLines: null,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send button
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: _isEmpty || !widget.isConnected
                          ? LinearGradient(
                              colors: [
                                const Color(0xFF4A4A4A),
                                const Color(0xFF2D2D35),
                              ],
                            )
                          : const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF00BCD4), Color(0xFF1E88E5)],
                            ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        if (!_isEmpty && widget.isConnected) ...[
                          BoxShadow(
                            color: const Color(0xFF00BCD4).withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFF1E88E5).withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(28),
                        onTap: _isEmpty || !widget.isConnected
                            ? null
                            : _sendMessage,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 200),
                              tween: Tween(
                                begin: 0.0,
                                end: _isEmpty || !widget.isConnected
                                    ? 0.0
                                    : 1.0,
                              ),
                              builder: (context, value, child) {
                                return Transform.rotate(
                                  angle:
                                      value * 0.5, // Slight rotation animation
                                  child: Icon(
                                    Icons.send_rounded,
                                    color: _isEmpty || !widget.isConnected
                                        ? const Color(0xFF6E6E6E)
                                        : Colors.white,
                                    size: 24,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
