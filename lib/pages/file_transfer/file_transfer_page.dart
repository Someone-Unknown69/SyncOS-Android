// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncos_android/features/file_transfer/domain/models/file_transfer_state.dart';
import 'package:syncos_android/features/file_transfer/provider/file_transfer_notifier.dart';
import 'package:syncos_android/features/file_transfer/provider/file_transfer_provider.dart';
import 'package:syncos_android/theme/app_theme.dart';
import 'package:syncos_android/core/network/provider/connection_provider.dart';
import 'package:syncos_android/core/network/domain/i_connection_manager.dart';

String _formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB'];
  int i = 0;
  double v = bytes.toDouble();
  while (v >= 1024 && i < suffixes.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(i == 0 ? 0 : 1)} ${suffixes[i]}';
}

String _formatTime(DateTime dt) {
  final hour = dt.hour.toString().padLeft(2, '0');
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

IconData _mimeIcon(String mime) {
  if (mime.startsWith('image/')) return Icons.image_rounded;
  if (mime.startsWith('video/')) return Icons.videocam_rounded;
  if (mime.startsWith('audio/')) return Icons.audiotrack_rounded;
  if (mime.contains('pdf')) return Icons.picture_as_pdf_rounded;
  if (mime.contains('zip') || mime.contains('tar') || mime.contains('gz')) {
    return Icons.folder_zip_rounded;
  }
  return Icons.insert_drive_file_rounded;
}

Color _mimeColor(String mime, ColorScheme cs) {
  if (mime.startsWith('image/')) return Colors.orange;
  if (mime.startsWith('video/')) return Colors.green;
  if (mime.startsWith('audio/')) return Colors.purple;
  if (mime.contains('pdf')) return Colors.red;
  if (mime.contains('zip') || mime.contains('tar') || mime.contains('gz')) {
    return Colors.amber;
  }
  return cs.primary;
}

// ─── page ────────────────────────────────────────────────────────────────────

class FileTransferPage extends ConsumerStatefulWidget {
  const FileTransferPage({super.key});

  @override
  ConsumerState<FileTransferPage> createState() => _FileTransferPageState();
}

class _FileTransferPageState extends ConsumerState<FileTransferPage> {
  TransferDirection? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(fileTransferState);
    final service = ref.read(fileTransferServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isActive = state.status != TransferStatus.idle;

    final connectionStatus = ref.watch(connectionStatusProvider).value ?? ConnectionStatus.disconnected;
    final isConnected = connectionStatus == ConnectionStatus.connected;

    // Filter history based on selected filter
    final filteredHistory = state.history.where((record) {
      if (_selectedFilter == null) return true;
      return record.direction == _selectedFilter;
    }).toList();

    final totalCount = filteredHistory.length;
    final totalBytes = filteredHistory.fold<int>(0, (sum, item) => sum + item.fileSize);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'File Transfer',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (state.history.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded,
                  color: colorScheme.onSurfaceVariant),
              tooltip: 'Clear history',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear History'),
                    content: const Text('Are you sure you want to clear your file transfer history?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(fileTransferState.notifier).clearHistory();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Send button ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.padding,
                vertical: AppTheme.spacing * 0.5,
              ),
              child: _SendButton(isActive: isActive, isConnected: isConnected, service: service),
            ),
          ),

          // ── Active transfer card ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: isActive
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.padding,
                        vertical: AppTheme.spacing * 0.5,
                      ),
                      child: _ActiveTransferCard(
                        state: state,
                        service: service,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ),

          // ── Filter segment + Stats ─────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.padding,
                AppTheme.spacing * 1.5,
                AppTheme.padding,
                AppTheme.spacing * 0.5,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'History',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      if (filteredHistory.isNotEmpty)
                        Text(
                          '$totalCount ${totalCount == 1 ? "file" : "files"} • ${_formatBytes(totalBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacing),
                  SegmentedButton<TransferDirection?>(
                    segments: const [
                      ButtonSegment(
                        value: null,
                        label: Text('All'),
                        icon: Icon(Icons.all_inclusive_rounded, size: 15),
                      ),
                      ButtonSegment(
                        value: TransferDirection.sent,
                        label: Text('Sent'),
                        icon: Icon(Icons.arrow_upward_rounded, size: 15),
                      ),
                      ButtonSegment(
                        value: TransferDirection.received,
                        label: Text('Received'),
                        icon: Icon(Icons.arrow_downward_rounded, size: 15),
                      ),
                    ],
                    selected: {_selectedFilter},
                    onSelectionChanged: (Set<TransferDirection?> newSelection) {
                      setState(() {
                        _selectedFilter = newSelection.first;
                      });
                    },
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: colorScheme.primaryContainer,
                      selectedForegroundColor: colorScheme.onPrimaryContainer,
                      iconSize: 15,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── History list ─────────────────────────────────────────────────
          filteredHistory.isEmpty
              ? const SliverToBoxAdapter(
                  child: _EmptyHistoryPlaceholder(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.padding,
                    vertical: AppTheme.spacing * 0.5,
                  ),
                  sliver: SliverList.separated(
                    itemCount: filteredHistory.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: AppTheme.spacing * 0.75),
                    itemBuilder: (context, index) {
                      final record = filteredHistory[index];
                      // Find original index in state.history for deletion
                      final originalIndex = state.history.indexOf(record);
                      return _HistoryTile(
                        record: record,
                        onDelete: originalIndex != -1
                            ? () => ref.read(fileTransferState.notifier).removeHistoryRecord(originalIndex)
                            : null,
                      );
                    },
                  ),
                ),
        ],
      ),
    );
  }
}

// ─── Send button ─────────────────────────────────────────────────────────────

class _SendButton extends StatelessWidget {
  final bool isActive;
  final bool isConnected;
  final dynamic service;

  const _SendButton({
    required this.isActive,
    required this.isConnected,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final enabled = isConnected && !isActive;

    return Ink(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: InkWell(
        onTap: enabled ? () => service.initSend() : null,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: enabled
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : colorScheme.onSurface.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.upload_file_rounded,
                  size: 28,
                  color: enabled ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: AppTheme.padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Send Files',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      !isConnected
                          ? 'Connect to desktop first'
                          : isActive
                              ? 'Transfer in progress…'
                              : 'Select and transfer files to your desktop',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: enabled
                    ? colorScheme.onSurfaceVariant
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Active transfer card ─────────────────────────────────────────────────────

class _ActiveTransferCard extends ConsumerStatefulWidget {
  final FileTransferState state;
  final dynamic service;

  const _ActiveTransferCard({required this.state, required this.service});

  @override
  ConsumerState<_ActiveTransferCard> createState() => _ActiveTransferCardState();
}

class _ActiveTransferCardState extends ConsumerState<_ActiveTransferCard> {
  int _prevBytes = 0;
  DateTime? _prevTime;
  double _smoothSpeed = 0.0;
  String _speedText = '';
  String _etaText = '';
  String? _lastFileId;

  @override
  void didUpdateWidget(covariant _ActiveTransferCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final currentFile = widget.state.currentFile;
    if (currentFile == null) {
      _reset();
      return;
    }

    final now = DateTime.now();

    // Reset speed/ETA calculation if file changed
    if (_lastFileId != currentFile.fileId) {
      _lastFileId = currentFile.fileId;
      _prevBytes = widget.state.bytesTransferred;
      _prevTime = now;
      _smoothSpeed = 0.0;
      _speedText = '';
      _etaText = '';
      return;
    }

    final bytes = widget.state.bytesTransferred;
    if (bytes != _prevBytes) {
      final prevTime = _prevTime;
      if (prevTime != null) {
        final elapsedMs = now.difference(prevTime).inMilliseconds;
        if (elapsedMs >= 200) {
          final deltaBytes = bytes - _prevBytes;
          final currentSpeed = (deltaBytes * 1000.0) / elapsedMs; // bytes per second
          
          if (_smoothSpeed == 0.0) {
            _smoothSpeed = currentSpeed;
          } else {
            _smoothSpeed = _smoothSpeed * 0.7 + currentSpeed * 0.3;
          }

          // Format speed
          _speedText = _formatSpeed(_smoothSpeed);

          // Calculate ETA
          final remainingBytes = currentFile.fileSize - bytes;
          if (_smoothSpeed > 0 && remainingBytes > 0) {
            final etaSecs = remainingBytes / _smoothSpeed;
            _etaText = _formatEta(etaSecs);
          } else {
            _etaText = '';
          }

          _prevBytes = bytes;
          _prevTime = now;
        }
      } else {
        _prevBytes = bytes;
        _prevTime = now;
      }
    }
  }

  void _reset() {
    _prevBytes = 0;
    _prevTime = null;
    _smoothSpeed = 0.0;
    _speedText = '';
    _etaText = '';
    _lastFileId = null;
  }

  String _formatSpeed(double bytesPerSec) {
    if (bytesPerSec <= 0) return '';
    if (bytesPerSec < 1024) return '${bytesPerSec.toStringAsFixed(0)} B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  String _formatEta(double seconds) {
    if (seconds <= 0) return '';
    if (seconds < 1) return 'Finishing...';
    if (seconds < 60) return '${seconds.round()}s remaining';
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).round();
    if (secs == 0) return '${mins}m remaining';
    return '${mins}m ${secs}s remaining';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final file = widget.state.currentFile;
    final fileSize = file?.fileSize ?? 0;
    final progress = (fileSize > 0 && widget.state.bytesTransferred > 0)
        ? (widget.state.bytesTransferred / fileSize).clamp(0.0, 1.0)
        : null; // null = indeterminate

    final hasSpeedOrEta = _speedText.isNotEmpty || _etaText.isNotEmpty;
    final speedEtaString = [
      if (_speedText.isNotEmpty) _speedText,
      if (_etaText.isNotEmpty) _etaText,
    ].join(' • ');

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status chip + file name row
            Row(
              children: [
                _StatusChip(status: widget.state.status),
                const SizedBox(width: AppTheme.spacing),
                Expanded(
                  child: Text(
                    file?.fileName ?? 'Waiting…',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing),

            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor:
                    colorScheme.onSurface.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _statusColor(widget.state.status, colorScheme),
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spacing * 0.75),

            // Bytes / Speed & ETA / file counter row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileSize > 0
                            ? '${_formatBytes(widget.state.bytesTransferred)} / ${_formatBytes(fileSize)}'
                            : '—',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hasSpeedOrEta) ...[
                        const SizedBox(height: 2),
                        Text(
                          speedEtaString,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.state.totalFiles > 0)
                  Text(
                    'File ${widget.state.currentFileIndex} of ${widget.state.totalFiles}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppTheme.spacing * 1.5),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => widget.service.cancelCurrentFileTransfer(),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('Cancel File'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer,
                      foregroundColor: colorScheme.onErrorContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 0.6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.service.cancelAllFileTransfer(),
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Cancel All'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(
                          color: colorScheme.error.withValues(alpha: 0.5)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 0.6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Status chip ──────────────────────────────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final TransferStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = _statusColor(status, colorScheme);
    final label = _statusLabel(status);
    final icon = _statusIcon(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── History tile ─────────────────────────────────────────────────────────────

class _HistoryTile extends StatelessWidget {
  final TransferRecord record;
  final VoidCallback? onDelete;

  const _HistoryTile({
    required this.record,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isSuccess = record.status == TransferStatus.successful;
    final isSent = record.direction == TransferDirection.sent;
    final typeColor = _mimeColor(record.mimeType, colorScheme);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius * 0.75),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.padding * 0.75,
          vertical: AppTheme.padding * 0.5,
        ),
        child: Row(
          children: [
            // File-type icon with direction badge layered
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _mimeIcon(record.mimeType),
                    size: 22,
                    color: typeColor,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isSent
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 10,
                      color: isSent
                          ? colorScheme.primary
                          : colorScheme.tertiary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppTheme.spacing),

            // Name + size + status message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.fileName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        _formatBytes(record.fileSize),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _formatTime(record.timestamp),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!isSuccess) ...[
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Failed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppTheme.spacing),

            // Individual delete action
            if (onDelete != null)
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                onPressed: onDelete,
                tooltip: 'Delete from history',
                splashRadius: 20,
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyHistoryPlaceholder extends StatelessWidget {
  const _EmptyHistoryPlaceholder();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_rounded,
                size: 32,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No transfers yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Send files or wait for incoming files from your computer. Your transfer history will appear here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

Color _statusColor(TransferStatus status, ColorScheme cs) {
  return switch (status) {
    TransferStatus.idle => cs.onSurfaceVariant,
    TransferStatus.initializing => cs.tertiary,
    TransferStatus.sending => cs.primary,
    TransferStatus.receiving => cs.secondary,
    TransferStatus.calculatingChecksum => cs.tertiary,
    TransferStatus.verifying => cs.secondary,
    TransferStatus.cancelling => cs.error,
    TransferStatus.failed => cs.error,
    TransferStatus.successful => cs.primary,
  };
}

String _statusLabel(TransferStatus status) {
  return switch (status) {
    TransferStatus.idle => 'Idle',
    TransferStatus.initializing => 'Initializing',
    TransferStatus.sending => 'Sending',
    TransferStatus.receiving => 'Receiving',
    TransferStatus.calculatingChecksum => 'Hashing',
    TransferStatus.verifying => 'Verifying',
    TransferStatus.cancelling => 'Cancelling',
    TransferStatus.failed => 'Failed',
    TransferStatus.successful => 'Done',
  };
}

IconData _statusIcon(TransferStatus status) {
  return switch (status) {
    TransferStatus.idle => Icons.circle_outlined,
    TransferStatus.initializing => Icons.hourglass_top_rounded,
    TransferStatus.sending => Icons.upload_rounded,
    TransferStatus.receiving => Icons.download_rounded,
    TransferStatus.calculatingChecksum => Icons.tag_rounded,
    TransferStatus.verifying => Icons.verified_rounded,
    TransferStatus.cancelling => Icons.cancel_outlined,
    TransferStatus.failed => Icons.error_rounded,
    TransferStatus.successful => Icons.check_circle_rounded,
  };
}
