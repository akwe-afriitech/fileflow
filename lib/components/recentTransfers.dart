import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fileflow/models/transfers.dart';

// Enum for sorting options
enum SortBy { date, size }

class RecentTransfers extends StatefulWidget {
  final bool isLoading;
  final List<Transfer> transfers;
  final Function(Transfer) onTap;
  final Function(Transfer) onDismissed;
  final Color primaryColor;
  final Color secondaryColor;

  const RecentTransfers({
    Key? key,
    required this.transfers,
    required this.onTap,
    required this.onDismissed,
    this.isLoading = false,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.grey,
  }) : super(key: key);

  @override
  State<RecentTransfers> createState() => _RecentTransfersState();
}

class _RecentTransfersState extends State<RecentTransfers> {
  SortBy _currentSort = SortBy.date;
  late List<Transfer> _sortedTransfers;

  @override
  void initState() {
    super.initState();
    _sortedTransfers = List.from(widget.transfers);
    _sortTransfers();
  }

  @override
  void didUpdateWidget(RecentTransfers oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sort the list if the input transfers change
    if (widget.transfers != oldWidget.transfers) {
      _sortedTransfers = List.from(widget.transfers);
      _sortTransfers();
    }
  }

  void _sortTransfers() {
    setState(() {
      if (_currentSort == SortBy.date) {
        _sortedTransfers.sort((a, b) => b.transferDate.compareTo(a.transferDate));
      } else {
        _sortedTransfers.sort((a, b) => b.fileSizeInMB.compareTo(a.fileSizeInMB));
      }
    });
  }

  IconData _getIconForFileType(FileType type) {
    switch (type) {
      case file_picker.FileType.image:
        return Icons.image_rounded;
      case file_picker.FileType.video:
        return Icons.videocam_rounded;
      case file_picker.FileType.audio:
        return Icons.audiotrack_rounded;
      case file_picker.FileType.custom: // file_picker does not have document/archive, so handle accordingly
        return Icons.article_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: _buildBody(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Recent Transfers",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          PopupMenuButton<SortBy>(
            onSelected: (sort) {
              _currentSort = sort;
              _sortTransfers();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: SortBy.date,
                child: Text("Sort by Date"),
              ),
              const PopupMenuItem(
                value: SortBy.size,
                child: Text("Sort by Size"),
              ),
            ],
            icon: Icon(Icons.sort, color: widget.secondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (widget.isLoading) {
      return Center(child: CircularProgressIndicator(color: widget.primaryColor));
    }

    if (_sortedTransfers.isEmpty) {
      return const Center(
        child: Text(
          "No recent transfers",
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _sortedTransfers.length,
      itemBuilder: (context, index) {
        final transfer = _sortedTransfers[index];
        return _buildTransferItem(transfer);
      },
    );
  }

  Widget _buildTransferItem(Transfer transfer) {
    return Dismissible(
      key: Key(transfer.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onDismissed(transfer),
      background: Container(
        color: Colors.redAccent,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          onTap: () => widget.onTap(transfer),
          leading: CircleAvatar(
            backgroundColor: widget.primaryColor.withOpacity(0.1),
            child: Icon(_getIconForFileType(transfer.fileType), color: widget.primaryColor),
          ),
          title: Text(
            transfer.fileName,
            style: const TextStyle(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "${transfer.fileSizeInMB.toStringAsFixed(2)} MB • From ${transfer.sourceDeviceName}",
            style: TextStyle(color: widget.secondaryColor, fontSize: 13),
          ),
          trailing: Text(
            DateFormat('MMM d').format(transfer.transferDate), // e.g., "Jul 6"
            style: TextStyle(fontSize: 12, color: widget.secondaryColor),
          ),
        ),
      ),
    );
  }
}