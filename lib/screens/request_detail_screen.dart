import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/snackbar_helper.dart';
import '../widgets/request_status_chip.dart';

/// Attachment status enum (aligned with RequestStatus pattern)
enum AttachmentStatus {
  pending,
  approved,
  rejected,
}

extension AttachmentStatusExtension on AttachmentStatus {
  String get label {
    switch (this) {
      case AttachmentStatus.pending:
        return 'PENDING';
      case AttachmentStatus.approved:
        return 'APPROVED';
      case AttachmentStatus.rejected:
        return 'REJECTED';
    }
  }

  Color getColor(ColorScheme scheme) {
    switch (this) {
      case AttachmentStatus.approved:
        return scheme.secondary;
      case AttachmentStatus.rejected:
        return scheme.error;
      case AttachmentStatus.pending:
        return scheme.tertiary;
    }
  }
}

AttachmentStatus parseAttachmentStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'approved':
      return AttachmentStatus.approved;
    case 'rejected':
      return AttachmentStatus.rejected;
    default:
      return AttachmentStatus.pending;
  }
}

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
    final scheme = Theme.of(context).colorScheme;
    
    if (attachments.isEmpty) {
      return Text(
        'No attachments uploaded',
        style: TextStyle(
          color: scheme.onSurface.withOpacity(0.7),
        ),
      );
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
    final scheme = Theme.of(context).colorScheme;
    final req = _resolve(context);
    final attachments =
        req['attachments'] is List ? List.from(req['attachments']) : [];
    final requestId = req['requestId'];

    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: scheme.surfaceContainerHighest,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attachments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
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
class _AttachmentTile extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> attachment;

  const _AttachmentTile({
    required this.requestId,
    required this.attachment,
  });

  @override
  State<_AttachmentTile> createState() => _AttachmentTileState();
}

class _AttachmentTileState extends State<_AttachmentTile> {
  bool _isProcessing = false;

  bool get _isExpired {
    final ts = widget.attachment['expiresAt'];
    if (ts == null) return false;
    return (ts as Timestamp).toDate().isBefore(DateTime.now());
  }

  Future<void> _review(String status) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'attachments': FieldValue.arrayRemove([widget.attachment]),
      });

      final updated = Map<String, dynamic>.from(widget.attachment)
        ..['status'] = status
        ..['reviewedAt'] = Timestamp.now()
        ..['reviewedBy'] = uid;

      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.requestId)
          .update({
        'attachments': FieldValue.arrayUnion([updated]),
      });

      if (!mounted) return;

      SnackBarHelper.showSuccess(
        context,
        status == 'approved'
            ? 'Attachment approved ✓'
            : 'Attachment rejected',
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'Failed to update attachment: ${e.toString()}',
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _download() async {
    final url = widget.attachment['url'];
    final uri = Uri.tryParse(url);

    if (uri == null) {
      SnackBarHelper.showError(context, 'Invalid URL');
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (!canLaunch) {
        if (!mounted) return;
        SnackBarHelper.showError(context, 'Cannot open this file');
        return;
      }

      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(
        context,
        'Failed to download: ${e.toString()}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final type = widget.attachment['type'];
    final statusString = widget.attachment['status'] ?? 'pending';
    final status = parseAttachmentStatus(statusString);
    final url = widget.attachment['url'];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(10)),
                  child: type == 'image'
                      ? CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Center(
                            child: CircularProgressIndicator(
                              color: scheme.primary,
                            ),
                          ),
                          errorWidget: (context, url, error) => Center(
                            child: Icon(
                              Icons.error_outline,
                              color: scheme.error,
                            ),
                          ),
                        )
                      : type == 'video'
                          ? _InlineVideo(url)
                          : Center(
                              child: Icon(
                                Icons.insert_drive_file,
                                size: 40,
                                color: scheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                ),
              ),

              // ACTIONS
              if (!_isExpired && !_isProcessing)
                Container(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: status == AttachmentStatus.approved
                              ? null
                              : () => _review('approved'),
                          child: Text(
                            'Approve',
                            style: TextStyle(color: scheme.secondary),
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextButton(
                          onPressed: status == AttachmentStatus.rejected
                              ? null
                              : () => _review('rejected'),
                          child: Text(
                            'Reject',
                            style: TextStyle(color: scheme.error),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // LOADING STATE
              if (_isProcessing)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // STATUS BADGE
        Positioned(
          top: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isExpired
                  ? scheme.surfaceContainerHigh
                  : status.getColor(scheme),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _isExpired ? 'EXPIRED' : status.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _isExpired
                    ? scheme.onSurface.withOpacity(0.6)
                    : scheme.onPrimary,
              ),
            ),
          ),
        ),

        // DOWNLOAD
        if (!_isExpired)
          Positioned(
            bottom: 6,
            right: 6,
            child: Material(
              color: scheme.primaryContainer,
              shape: const CircleBorder(),
              child: IconButton(
                icon: Icon(
                  Icons.download,
                  color: scheme.onPrimaryContainer,
                ),
                onPressed: _download,
              ),
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
      ..initialize().then((_) {
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (!_controller.value.isInitialized) {
      return Center(
        child: CircularProgressIndicator(
          color: scheme.primary,
        ),
      );
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
            Icon(
              Icons.play_circle_fill,
              size: 60,
              color: scheme.primary,
            ),
        ],
      ),
    );
  }
}