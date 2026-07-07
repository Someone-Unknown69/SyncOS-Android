// Copyright (c) 2026 Kartik. Licensed under GPL-3.0. See LICENSE for details.

import 'package:flutter/material.dart';
import 'package:syncos_android/pages/components/base_page.dart';
import 'package:syncos_android/pages/components/setting_components.dart';
import 'package:syncos_android/pages/components/tile.dart';
import 'package:syncos_android/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BasePage(
      title: 'About', 
      children: [
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/app_icon.png',
                width: 72,
                height: 72,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 18),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sync OS',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      child: Text(
                        'Pre-Release',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimaryContainer,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        SectionHeader(title: 'Developer'),
        
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
              onTap: () => launchUrl(Uri.parse('https://github.com/Someone-Unknown69')),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    RotatingMask(
                      child: Image.network(
                        'https://github.com/Someone-Unknown69.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: colorScheme.primary,
                          child: Icon(Icons.person, size: 20, color: colorScheme.onPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Someone-Unknown69',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Lead Developer and Maintainer',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer.withValues(alpha: 0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.onPrimaryContainer, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),

        SectionHeader(title: 'App Info'),
        CustomTile(
          leading: const Icon(Icons.code_rounded),
          title: 'Github Repository',
          subtitle: 'View source Code',
          onTap: () => launchUrl(Uri.parse('https://github.com/Someone-Unknown69/SyncOS/tree/main/syncos_android')),
        ),

        CustomTile(
          leading: const Icon(Icons.numbers_rounded),
          title: 'Build Version',
          subtitle: '2026.0.0.2',
        ),

        CustomTile(
          leading: Icon(Icons.description_rounded), 
          title: 'General Public License v3.0',
          subtitle: 'GPL v3.0 - Free Open Source Software',
          onTap: () => launchUrl(Uri.parse('')),
        ),
        // gnu license, version code
      ]
    );
  }
}


// -----------------------------------------------------------------------------
//  Rotating Mask Widget
// -----------------------------------------------------------------------------
class RotatingMask extends StatefulWidget {
  final Widget child;

  const RotatingMask({
    super.key, 
    required this.child, 
  });

  @override
  State<RotatingMask> createState() => _RotatingMaskState();
}

class _RotatingMaskState extends State<RotatingMask> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this, 
    duration: const Duration(seconds: 10), 
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56,
      height: 56,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return ClipPath(
            clipper: BlobClipper(animationValue: _ctrl.value),
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Custom Clipper to draw the Blob / Scalloped Edge
// -----------------------------------------------------------------------------
class BlobClipper extends CustomClipper<Path> {
  final double animationValue;

  BlobClipper({required this.animationValue});

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Adjusted baseRadius and lowered amplitude for a smoother blob shape
    final baseRadius = size.width / 2.2; 
    final amplitude = size.width / 22; 
    final int petals = 6;

    final path = Path();
    for (int i = 0; i <= 360; i++) {
      final rad = i * math.pi / 180;
      // We use math.cos for the radius to create the lobes
      final r = baseRadius + amplitude * math.cos(petals * rad);
      
      // Rotate the coordinate by the animation value
      final rotatedRad = rad + (animationValue * 2 * math.pi);
      final x = center.dx + r * math.cos(rotatedRad);
      final y = center.dy + r * math.sin(rotatedRad);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant BlobClipper oldClipper) {
    return oldClipper.animationValue != animationValue;
  }
}
