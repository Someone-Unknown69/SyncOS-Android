// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:syncos_android/theme/app_theme.dart';

Widget buildTile({
  Widget? leading,
  required String title,
  String? subtitle,
  VoidCallback? onTap,
  Color? backgroundColor, 
  Color? textColor,      
}) {
  return Card(
    elevation: 0,
    margin: const EdgeInsets.symmetric(vertical: 4),
    color: backgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      onTap: onTap,
      leading: leading,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor, 
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: textColor?.withValues(alpha: 0.8), 
              ),
            )
          : null,
      trailing: null,
    ),
  );
}