import 'package:flutter/material.dart';
import '../../components/dashboard_item.dart';
import '../../../theme/app_theme.dart';

class DashboardGrid extends StatelessWidget {
  final List<DashboardItem> items;

  const DashboardGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
      
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 1 : 2,
            mainAxisExtent: isDesktop ? 65 : 100,
            // Increased the dividing gap spacing coefficients here
            crossAxisSpacing: AppTheme.spacing, 
            mainAxisSpacing: AppTheme.spacing,
          ),
          itemBuilder: (context, index) {
            return DashboardCard(item: items[index], isDesktop: isDesktop);
          },
        );
      },
    );
  }
}

class DashboardCard extends StatelessWidget {
  final DashboardItem item;
  final bool isDesktop;

  const DashboardCard({super.key, required this.item, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Ink(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),

      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        splashColor: colorScheme.primary.withValues(alpha: 0.1), 
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.padding),
          child: !isDesktop 
            // Mobile Grid Cell
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacing * 0.4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(item.icon, size: 22, color: colorScheme.primary),
                  ),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              )
            // Desktop List Row
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacing * 0.4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(item.icon, size: 20, color: colorScheme.primary),
                      ),
                      const SizedBox(width: AppTheme.spacing),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ]
                  ),
                  Icon(
                    Icons.chevron_right_rounded, 
                    size: 18, 
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ],
              )
        ),
      ),
    );
  }
}