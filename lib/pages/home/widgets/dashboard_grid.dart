import 'package:flutter/material.dart';
import '../../../models/dashboard_item.dart';
import '../../../theme/app_theme.dart';

class DashboardGrid extends StatelessWidget {
  final List<DashboardItem> items;

  const DashboardGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
      
        // Using a Grid for both, but changing column count makes it look like a list on desktop
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 1 : 2, // 1 column for list look, 2 for grid
            mainAxisExtent: isDesktop ? 65 : 100, // Height of the item
            crossAxisSpacing: AppTheme.spacing / 2,
            mainAxisSpacing: AppTheme.spacing / 2,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: !isDesktop 
            // For grid 
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(item.icon, size: 24, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              )
            // For list
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(item.icon, color: colorScheme.primary, size: 22),
                      const SizedBox(width: 12),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ]
                  ),
                  Icon(
                    Icons.chevron_right_rounded, 
                    size: 18, 
                    color: colorScheme.outline,
                  ),
                ],
              )
        ),
      ),
    );
  }
}
