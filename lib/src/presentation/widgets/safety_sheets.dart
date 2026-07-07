import 'package:flutter/material.dart';

import '../../app.dart';
import '../../core/app_theme.dart';
import '../../domain/models.dart';
import 'app_widgets.dart';

Future<bool> showBlockDialog({
  required BuildContext context,
  required String targetUserId,
  required String targetName,
}) async {
  final controller = OceanMatchScope.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Bloquer $targetName ?'),
        content: const Text(
          'Cette personne ne pourra plus vous voir, vous liker, matcher ou vous envoyer de message.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bloquer'),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return false;
  await controller.blockUser(targetUserId);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$targetName est bloque.')),
    );
  }
  return true;
}

Future<void> showReportSheet({
  required BuildContext context,
  required String targetUserId,
  required String targetName,
  String? conversationId,
  String? messageId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return _ReportSheet(
        targetUserId: targetUserId,
        targetName: targetName,
        conversationId: conversationId,
        messageId: messageId,
      );
    },
  );
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({
    required this.targetUserId,
    required this.targetName,
    this.conversationId,
    this.messageId,
  });

  final String targetUserId;
  final String targetName;
  final String? conversationId;
  final String? messageId;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  ReportReason _reason = ReportReason.suspiciousBehavior;
  final _commentController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GoldText(
            'Signaler ${widget.targetName}',
            style: OceanTypography.title(context, fontSize: 30),
          ),
          const SizedBox(height: 8),
          const Text(
            'Le signalement est conserve pour la securite de la communaute. Vous pourrez aussi bloquer ce profil.',
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<ReportReason>(
            initialValue: _reason,
            decoration: const InputDecoration(labelText: 'Motif'),
            items: [
              for (final reason in ReportReason.values)
                DropdownMenuItem(value: reason, child: Text(reason.label)),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _reason = value);
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Commentaire facultatif',
              hintText: 'Ajoutez un detail utile si besoin',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _submitting ? null : () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: Text(_submitting ? 'Envoi...' : 'Signaler'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _submitting ? null : _submitAndBlock,
            icon: const Icon(Icons.block),
            label: const Text('Signaler puis bloquer'),
          ),
          const SizedBox(height: 8),
          const PrivacyNote(),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final controller = OceanMatchScope.of(context);
    await controller.reportUser(
      reportedId: widget.targetUserId,
      reason: _reason,
      conversationId: widget.conversationId,
      messageId: widget.messageId,
      comment: _commentController.text,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Signalement enregistre.')),
    );
  }

  Future<void> _submitAndBlock() async {
    setState(() => _submitting = true);
    final controller = OceanMatchScope.of(context);
    await controller.reportUser(
      reportedId: widget.targetUserId,
      reason: _reason,
      conversationId: widget.conversationId,
      messageId: widget.messageId,
      comment: _commentController.text,
    );
    await controller.blockUser(widget.targetUserId);
    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.targetName} est signale et bloque.')),
    );
  }
}
