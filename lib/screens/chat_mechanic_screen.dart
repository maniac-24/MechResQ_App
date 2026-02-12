// lib/screens/chat_mechanic_screen.dart
import 'package:flutter/material.dart';

class ChatMechanicScreen extends StatefulWidget {
  final String mechanicName;
  const ChatMechanicScreen({super.key, required this.mechanicName});

  @override
  State<ChatMechanicScreen> createState() => _ChatMechanicScreenState();
}

class _ChatMechanicScreenState extends State<ChatMechanicScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  // Demo seed messages — replace with Firestore stream
  final List<_Msg> _messages = [
    _Msg(text: "Hi, your request has been accepted.", fromMechanic: true, time: DateTime(2026, 2, 3, 14, 23)),
    _Msg(text: "Great! How long will it take?", fromMechanic: false, time: DateTime(2026, 2, 3, 14, 24)),
    _Msg(text: "About 12 minutes. I'm on my way now.", fromMechanic: true, time: DateTime(2026, 2, 3, 14, 24)),
    _Msg(text: "Okay, I'll be waiting.", fromMechanic: false, time: DateTime(2026, 2, 3, 14, 25)),
  ];

  // Quick-reply suggestions
  static const _quickReplies = [
    "Where are you?",
    "I'm at the gate",
    "Please hurry",
    "Thank you",
    "Can you call me?",
  ];

  @override
  void initState() {
    super.initState();
    // scroll to bottom after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    }
  }

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text: trimmed, fromMechanic: false, time: DateTime.now()));
      _controller.clear();
    });

    // scroll after rebuild
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // Simulate mechanic reply after 1.5 s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        _messages.add(_Msg(
          text: "Got it! I'll be there shortly.",
          fromMechanic: true,
          time: DateTime.now(),
        ));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    });
  }

  // -----------------------------------------------------------------------
  // BUILD
  // -----------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      // ── AppBar with mechanic info ──────────────────────────────────────
      appBar: AppBar(
        titleSpacing: 0,
        leading: const BackButton(),
        title: Row(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: scheme.primary,
                  child: Text(
                    widget.mechanicName.isNotEmpty ? widget.mechanicName[0] : 'M',
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: scheme.secondary,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.surface, width: 2),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.mechanicName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  "Online",
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.secondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      // ── Body ───────────────────────────────────────────────────────────
      body: Column(
        children: [
          // ── message list ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _MessageBubble(msg: _messages[i]),
            ),
          ),

          // ── Quick-reply chips ────────────────────────────────────────
          Container(
            color: scheme.surfaceContainerLowest,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickReplies.map((qr) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    backgroundColor: scheme.surfaceContainerHighest,
                    side: BorderSide(color: scheme.primary.withOpacity(0.4)),
                    label: Text(
                      qr,
                      style: TextStyle(
                        color: scheme.primary,
                        fontSize: 13,
                      ),
                    ),
                    onPressed: () => _send(qr),
                  ),
                )).toList(),
              ),
            ),
          ),

          // ── Input row ────────────────────────────────────────────────
          Container(
            color: scheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    style: TextStyle(color: scheme.onSurface),
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: "Type a message…",
                      hintStyle: TextStyle(
                        color: scheme.onSurface.withOpacity(0.6),
                      ),
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(22),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // send button
                Container(
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    color: scheme.onPrimary,
                    icon: const Icon(Icons.send),
                    onPressed: () => _send(_controller.text),
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

// ===========================================================================
// MESSAGE MODEL
// ===========================================================================
class _Msg {
  final String text;
  final bool fromMechanic;
  final DateTime time;
  const _Msg({required this.text, required this.fromMechanic, required this.time});
}

// ===========================================================================
// MESSAGE BUBBLE
// ===========================================================================
class _MessageBubble extends StatelessWidget {
  final _Msg msg;
  const _MessageBubble({required this.msg});

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $period";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fromMe = !msg.fromMechanic;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Column(
            crossAxisAlignment: fromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: fromMe
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(fromMe ? 16 : 4),
                    bottomRight: Radius.circular(fromMe ? 4 : 16),
                  ),
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    color: fromMe
                        ? scheme.onPrimary
                        : scheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _formatTime(msg.time),
                style: TextStyle(
                  fontSize: 10,
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}