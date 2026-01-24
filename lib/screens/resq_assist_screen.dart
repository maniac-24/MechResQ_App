import 'package:flutter/material.dart';

class ResQAssistScreen extends StatefulWidget {
  const ResQAssistScreen({super.key});

  @override
  State<ResQAssistScreen> createState() => _ResQAssistScreenState();
}

class _ResQAssistScreenState extends State<ResQAssistScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      "from": "bot",
      "text":
          "Hi 👋 I’m ResQAssist.\nTell me your vehicle problem and I’ll guide you."
    }
  ];

  // ---------------- SEND MESSAGE ----------------
  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"from": "user", "text": text});
    });

    _controller.clear();
    _scrollDown();

    // Simulate AI thinking delay
    Future.delayed(const Duration(milliseconds: 600), () {
      final reply = _smartReply(text);

      setState(() {
        _messages.add({"from": "bot", "text": reply});
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

    if (msg.contains("fuel") || msg.contains("petrol") || msg.contains("diesel")) {
      return "⛽ Looks like a fuel-related issue.\nYou can request fuel assistance from nearby services.";
    }

    if (msg.contains("accident") || msg.contains("emergency")) {
      return "🚨 This sounds serious.\nPlease use the SOS Call option immediately for quick help.";
    }

    if (msg.contains("location")) {
      return "📍 Your live location will be shared automatically when you request a mechanic or SOS.";
    }

    return "🤖 Thanks for the info.\nI’ll help you find the best mechanic nearby based on your issue.";
  }

  // ---------------- AUTO SCROLL ----------------
  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------- CHAT BUBBLE ----------------
  Widget _bubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 280),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : const Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
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
                final m = _messages[i];
                final isUser = m["from"] == "user";
                return _bubble(m["text"]!, isUser);
              },
            ),
          ),

          // INPUT AREA
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: "Describe your issue...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
