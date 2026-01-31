import 'package:flutter/material.dart';
import 'package:tcpchatv2_client/services/tcp_service.dart';
import 'package:tcpchatv2_client/widgets/chat_bubble.dart';
import 'package:tcpchatv2_client/widgets/chat_input.dart';
import 'package:tcpchatv2_client/settings/server_settings.dart';
import 'package:tcpchatv2_client/config/app_constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final ChatClient chatClient = ChatClient();
  bool connectionStatus = false;
  bool isConnecting = false;
  final ScrollController _scrollController = ScrollController();

  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.elasticOut),
        );

    _slideController.forward();

    chatClient.onConnected = () {
      setState(() {
        connectionStatus = true;
        isConnecting = false;
      });
      _pulseController.stop();
    };

    chatClient.onDisconnected = () {
      setState(() {
        connectionStatus = false;
        isConnecting = false;
      });
      _pulseController.stop();
    };

    chatClient.onError = () {
      setState(() {
        connectionStatus = false;
        isConnecting = false;
      });
      _pulseController.stop();
      _showErrorSnackBar();
    };

    chatClient.onMessage = (message) {
      setState(() {});
      _scrollToBottom();
    };
  }

  @override
  void dispose() {
    chatClient.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _toggleConnection() {
    if (!connectionStatus && !isConnecting) {
      setState(() {
        isConnecting = true;
      });
      _pulseController.repeat(reverse: true);
      chatClient.connect(
        ServerSettings.host,
        ServerSettings.port,
        username: AppConstants.username,
      );
    } else if (connectionStatus) {
      chatClient.disconnect();
    }
  }

  void _sendMessage(String message) {
    chatClient.sendMessage(message);
    setState(() {});
    _scrollToBottom();
  }

  String _getConnectionStatusText() {
    if (isConnecting) return AppConstants.statusConnecting;
    return connectionStatus
        ? AppConstants.statusConnected
        : AppConstants.statusDisconnected;
  }

  Color _getConnectionStatusColor() {
    if (isConnecting) return const Color(0xFFFF9800);
    return connectionStatus ? const Color(0xFF4CAF50) : const Color(0xFFE53E3E);
  }

  void _showErrorSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFE53E3E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              AppConstants.errorConnection,
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A1F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE53E3E), width: 1),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildFuturisticAppBar(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A0F), Color(0xFF1A1A1F)],
          ),
        ),
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            children: [
              // Chat messages area
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF1A1A1F).withOpacity(0.3),
                        const Color(0xFF2D2D35).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF00BCD4).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: chatClient.chatMessages.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: chatClient.chatMessages.length,
                          itemBuilder: (context, index) {
                            final message = chatClient.chatMessages[index];
                            return TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 500),
                              tween: Tween(begin: 0.0, end: 1.0),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Opacity(
                                    opacity: value,
                                    child: ChatBubble(
                                      message: message.content,
                                      isOwnMessage: message.isOwnMessage,
                                      timestamp: message.timestamp,
                                      username: message.username,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
              ),

              // Input area
              ChatInput(
                onSendMessage: _sendMessage,
                isConnected: connectionStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildFuturisticAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1F),
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A1F), Color(0xFF2D2D35)],
          ),
          border: Border(
            bottom: BorderSide(color: Color(0xFF00BCD4), width: 1),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [Color(0xFF00BCD4), Color(0xFF1E88E5)],
        ).createShader(bounds),
        child: const Text(
          AppConstants.appTitle,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      leading: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getConnectionStatusColor().withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _getConnectionStatusColor(), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _getConnectionStatusColor().withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(scale: animation, child: child),
            );
          },
          child: Text(
            _getConnectionStatusText(),
            key: ValueKey(_getConnectionStatusText()),
            style: TextStyle(
              fontSize: 12,
              color: _getConnectionStatusColor(),
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00BCD4).withOpacity(0.8),
                const Color(0xFF1E88E5).withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00BCD4).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: isConnecting ? null : _toggleConnection,
              child: Container(
                padding: const EdgeInsets.all(12),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isConnecting ? _pulseAnimation.value : 1.0,
                      child: isConnecting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(
                              connectionStatus
                                  ? Icons.power_off
                                  : Icons.power_settings_new,
                              color: Colors.white,
                              size: 20,
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(seconds: 2),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Color(0xFF00BCD4).withOpacity(0.2 * value),
                        Colors.transparent,
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 80,
                    color: Color.lerp(
                      const Color(0xFF6E6E6E),
                      const Color(0xFF00BCD4),
                      value,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFF6E6E6E),
                const Color(0xFF00BCD4).withOpacity(0.8),
              ],
            ).createShader(bounds),
            child: const Text(
              'Noch keine Nachrichten...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Verbinde dich mit dem Server!',
            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16),
          ),
        ],
      ),
    );
  }
}
