import 'package:flutter/material.dart';

class HorizontalColorPicker extends StatelessWidget {
  final Color selectedColor;
  final Function(Color) onColorSelected;

  const HorizontalColorPicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  static const List<Color> _swatches = [
    Colors.blue, Colors.red, Colors.green, Colors.orange,
    Colors.purple, Colors.teal, Colors.indigo, Colors.pink,
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. The Header with Icon
        Row(
          children: [
            Icon(Icons.palette_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Text("Accent Color", style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
        const SizedBox(height: 16),
        
        // 2. Single Horizontal Scrollable Line
        SizedBox(
          height: 50,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _swatches.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final color = _swatches[index];
              final isSelected = color.value == selectedColor.value;
              return GestureDetector(
                onTap: () => onColorSelected(color),
                child: Container(
                  width: 50,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: isSelected 
                      ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3)
                      : null,
                  ),
                ),
              );
            },
          ),
        ),
        
        const SizedBox(height: 24),
        
        // 3. Custom Color Option
        FilledButton.tonalIcon(
          onPressed: () {
            // Integrate your custom color picker dialog here
          },
          icon: const Icon(Icons.colorize_rounded),
          label: const Text("Custom Color Picker"),
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
        ),
      ],
    );
  }
}