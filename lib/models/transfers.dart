
import 'package:flutter/material.dart';

// Enum to represent different file types for displaying icons
enum FileType { image, video, audio, document, archive, other }

class Transfer {
  final String id;
  final String fileName;
  final double fileSizeInMB;
  final DateTime transferDate;
  final String sourceDeviceName;
  final FileType fileType;

  Transfer({
    required this.id,
    required this.fileName,
    required this.fileSizeInMB,
    required this.transferDate,
    required this.sourceDeviceName,
    required this.fileType,
  });
}