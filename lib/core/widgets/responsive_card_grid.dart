import 'package:flutter/material.dart';

/// Grille de cartes responsive qui s'adapte automatiquement à la largeur
/// disponible et au nombre d'éléments.
///
/// - ≥ 1200 px : 3 colonnes
/// - 800–1200 px : 2 colonnes
/// - < 800 px : 1 colonne (liste)
///
/// Quand il y a très peu d'éléments (< 4), la grille évite les espaces vides
/// en utilisant un childAspectRatio plus compact.
class ResponsiveCardGrid<T> extends StatelessWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final EdgeInsetsGeometry padding;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double maxItemWidth;
  final double compactItemWidth;
  final Widget? emptyWidget;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const ResponsiveCardGrid({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.padding = const EdgeInsets.all(16),
    this.crossAxisSpacing = 14,
    this.mainAxisSpacing = 14,
    this.maxItemWidth = 420,
    this.compactItemWidth = 340,
    this.emptyWidget,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return emptyWidget ?? const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int columnCount;
        final double itemWidth;

        if (width >= 1200) {
          columnCount = 3;
          itemWidth = (width - (columnCount - 1) * crossAxisSpacing) / columnCount;
        } else if (width >= 800) {
          columnCount = 2;
          itemWidth = (width - (columnCount - 1) * crossAxisSpacing) / columnCount;
        } else {
          columnCount = 1;
          itemWidth = width;
        }

        // Quand peu d'éléments, on limite la largeur pour éviter le vide.
        final effectiveWidth = items.length < 4 && columnCount > 1
            ? itemWidth.clamp(0.0, compactItemWidth)
            : itemWidth.clamp(0.0, maxItemWidth);

        // Si la largeur effective est inférieure à la largeur disponible,
        // on centre la grille avec un Wrap.
        final useCenteredWrap =
            items.length < 4 && columnCount > 1 && effectiveWidth < width * 0.85;

        if (useCenteredWrap) {
          return SingleChildScrollView(
            physics: physics,
            padding: padding,
            child: Wrap(
              spacing: crossAxisSpacing,
              runSpacing: mainAxisSpacing,
              alignment: WrapAlignment.start,
              children: [
                for (var i = 0; i < items.length; i++)
                  SizedBox(
                    width: effectiveWidth,
                    child: itemBuilder(context, items[i], i),
                  ),
              ],
            ),
          );
        }

        return GridView.builder(
          physics: physics,
          shrinkWrap: shrinkWrap,
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columnCount,
            crossAxisSpacing: crossAxisSpacing,
            mainAxisSpacing: mainAxisSpacing,
            childAspectRatio: _computeAspectRatio(columnCount),
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return itemBuilder(context, items[index], index);
          },
        );
      },
    );
  }

  /// Ratio hauteur/largeur ajusté selon le nombre de colonnes pour éviter
  /// les cartes trop étirées en hauteur sur grand écran.
  double _computeAspectRatio(int columnCount) {
    switch (columnCount) {
      case 1:
        return 3.4;
      case 2:
        return 2.8;
      case 3:
        return 2.6;
      default:
        return 2.8;
    }
  }
}
