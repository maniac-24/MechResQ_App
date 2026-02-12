import 'package:flutter/material.dart';

/// Type-safe chat message model
class ChatMessage {
  final bool isUser;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.isUser,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class ResQAssistScreen extends StatefulWidget {
  const ResQAssistScreen({super.key});

  @override
  State<ResQAssistScreen> createState() => _ResQAssistScreenState();
}

class _ResQAssistScreenState extends State<ResQAssistScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      isUser: false,
      text:
          "Hi 👋 I'm ResQAssist.\nTell me your vehicle problem and I'll guide you.",
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  // ---------------- SEND MESSAGE ----------------
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(isUser: true, text: text));
    });

    _controller.clear();
    _scrollDown();

    // Simulate AI thinking delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;

      final reply = _smartReply(text);

      setState(() {
        _messages.add(ChatMessage(isUser: false, text: reply));
      });
      _scrollDown();
    });
  }

  // ---------------- SMART LOGIC ----------------
  String _smartReply(String userText) {
    final msg = userText.toLowerCase();

    if (msg.contains("flat") || msg.contains("puncture")) {
      return "🛞 It seems like a tyre puncture.\nI recommend calling a nearby tyre or mechanic service.";
    }

    if (msg.contains("engine") || msg.contains("overheat")) {
      return "🔥 Engine issues detected.\nPlease stop the vehicle safely and request a mechanic immediately.";
    }

    if (msg.contains("battery") || msg.contains("start")) {
      return "🔋 This may be a battery issue.\nTry checking connections or request a jump-start service.";
    }

    if (msg.contains("fuel") ||
        msg.contains("petrol") ||
        msg.contains("diesel")) {
      return "⛽ Looks like a fuel-related issue.\nYou can request fuel assistance from nearby services.";
    }

    if (msg.contains("accident") || msg.contains("emergency")) {
      return "🚨 This sounds serious.\nPlease use the SOS Call option immediately for quick help.";
    }

    if (msg.contains("location")) {
      return "📍 Your live location will be shared automatically when you request a mechanic or SOS.";
    }

    return "🤖 Thanks for the info.\nI'll help you find the best mechanic nearby based on your issue.";
  }

  // ---------------- AUTO SCROLL ----------------
  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted || !_scroll.hasClients) return;
      
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("ResQAssist 🤖"),
      ),
      body: Column(
        children: [
          // CHAT AREA
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final message = _messages[i];
                return ChatBubble(
                  message: message,
                  scheme: scheme,
                );
              },
            ),
          ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: scheme.outlineVariant),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    style: TextStyle(color: scheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Describe your issue...",
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHigh,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: scheme.primary, width: 2),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.send, color: scheme.onPrimary),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable chat bubble widget with Material 3 design
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme scheme;

  const ChatBubble({
    super.key,
    required this.message,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment:
          message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: message.isUser
              ? scheme.primaryContainer
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser
                ? scheme.onPrimaryContainer
                : scheme.onSurface.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}