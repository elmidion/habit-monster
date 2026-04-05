import 'dart:io';
import 'package:flutter/material.dart';

Widget? buildFileImage(String? path, double size) {
  if (path == null || !File(path).existsSync()) return null;
  return Image.file(
    File(path),
    width: size,
    height: size,
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
  );
}
