import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? data;
  const RequestDetailScreen({super.key, this.data});

  Map<String, dynamic> _resolve(BuildContext context) {
    return data ??
        (ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>?) ??
        {};
  }

  // =====================================================
  // ATTACHMENTS GRID
  // =====================================================
  Widget _buildAttachments(
    BuildContext context,
    String requestId,
    List attachments,
  ) {
    if (attachments.isEmpty) {
      return const Text('No attachments uploaded',
          style: TextStyle(color: Colors.white70));
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: attachments.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (_, i) {
        final att = Map<String, dynamic>.from(attachments[i]);
        return _AttachmentTile(
          requestId: requestId,
          attachment: att,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final req = _resolve(context);
    final attachments =
        req['attachments'] is List ? List.from(req['attachments']) : [];
    final requestId = req['requestId'];

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: const Color(0xFF1B1B1B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Attachments',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildAttachments(context, requestId, attachments),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// SINGLE ATTACHMENT TILE
// =====================================================
class _AttachmentTile extends StatelessWidget {
  final String requestId;
  final Map<String, dynamic> attachment;

  const _AttachmentTile({
    required this.requestId,
    required this.attachment,
  });

  bool get _isExpired {
    final ts = attachment['expiresAt'];
    if (ts == null) return false;
    return (ts as Timestamp).toDate().isBefore(DateTime.now());
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<void> _review(String status) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      'attachments': FieldValue.arrayRemove([attachment]),
    });

    final updated = Map<String, dynamic>.from(attachment)
      ..['status'] = status
      ..['reviewedAt'] = Timestamp.now()
      ..['reviewedBy'] = uid;

    await FirebaseFirestore.instance
        .collection('requests')
        .doc(requestId)
        .update({
      'attachments': FieldValue.arrayUnion([updated]),
    });
  }

  @override
  Widget build(BuildContext context) {
    final type = attachment['type'];
    final status = attachment['status'] ?? 'pending';
    final url = attachment['url'];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Expanded(
                child: type == 'image'
                    ? CachedNetworkImage(imageUrl: url, fit: BoxFit.cover)
                    : type == 'video'
                        ? _InlineVideo(url)
                        : Center(
                            child: Icon(Icons.insert_drive_file,
                                size: 40, color: Colors.white),
                          ),
              ),

              // ACTIONS
              if (!_isExpired)
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: status == 'approved'
                            ? null
                            : () => _review('approved'),
                        child: const Text('Approve',
                            style: TextStyle(color: Colors.green)),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: status == 'rejected'
                            ? null
                            : () => _review('rejected'),
                        child: const Text('Reject',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // STATUS BADGE
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _isExpired ? Colors.grey : _statusColor(status),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _isExpired ? 'EXPIRED' : status.toUpperCase(),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),

        // DOWNLOAD
        if (!_isExpired)
          Positioned(
            bottom: 6,
            right: 6,
            child: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () =>
                  launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
            ),
          ),
      ],
    );
  }
}

// =====================================================
// INLINE VIDEO PLAYER
// =====================================================
class _InlineVideo extends StatefulWidget {
  final String url;
  const _InlineVideo(this.url);

  @override
  State<_InlineVideo> createState() => _InlineVideoState();
}

class _InlineVideoState extends State<_InlineVideo> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          if (!_controller.value.isPlaying)
            const Icon(Icons.play_circle_fill, size: 60),
        ],
      ),
    );
  }
}
