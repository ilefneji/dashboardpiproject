import 'package:flutter/material.dart';

import '../../../../core/widgets/entity_card.dart';
import '../../domain/entities/lot.dart';

class LotListItem extends StatelessWidget {
  final Lot lot;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAffectTasks;

  const LotListItem({
    super.key,
    required this.lot,
    required this.onEdit,
    required this.onDelete,
    required this.onAffectTasks,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    if (lot.createdAt != null) {
      chips.add(
          Container()); // keep layout flexible (could add formatted date chip)
    }

    return EntityCard(
      title: lot.name,
      subtitle: null,
      description: lot.description,
      avatarText: lot.name.isNotEmpty ? lot.name[0].toUpperCase() : 'L',
      avatarColor: Colors.teal,
      chips: chips,
      actions: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              onPressed: onAffectTasks,
              icon: const Icon(Icons.assignment_add, color: Colors.green)),
          IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit, color: Colors.blue)),
          IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete, color: Colors.red)),
        ],
      ),
    );
  }
}
