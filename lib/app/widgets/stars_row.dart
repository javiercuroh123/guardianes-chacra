import 'package:flutter/material.dart';
import 'package:guardianes_chacra/app/app_theme.dart';
import 'package:guardianes_chacra/l10n/app_localizations.dart';

/// Tres estrellas, [stars] de ellas llenas.
class StarsRow extends StatelessWidget {
  const new({required this.stars, this.size = 20, super.key});

  final int stars;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = GameColors.of(context);
    return Semantics(
      label: AppLocalizations.of(context).starsSemantics(stars),
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Icon(
              i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < stars ? colors.star : colors.starEmpty,
            ),
        ],
      ),
    );
  }
}
