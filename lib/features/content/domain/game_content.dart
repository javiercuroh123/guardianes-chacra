import 'package:guardianes_chacra/features/content/domain/ads_def.dart';
import 'package:guardianes_chacra/features/content/domain/audio_def.dart';
import 'package:guardianes_chacra/features/content/domain/battle_rules.dart';
import 'package:guardianes_chacra/features/content/domain/content_texts.dart';
import 'package:guardianes_chacra/features/content/domain/guardian_def.dart';
import 'package:guardianes_chacra/features/content/domain/level_def.dart';
import 'package:guardianes_chacra/features/content/domain/pest_def.dart';

/// El contenido completo del juego, ya validado. Los mapas conservan el orden
/// de `index.json` (es el orden del Bestiario y de los niveles).
class GameContent {
  new({
    required this.rules,
    required Map<String, PestDef> pests,
    required Map<String, GuardianDef> guardians,
    required List<LevelDef> levels,
    required this.texts,
    this.audio = const AudioDef(),
    this.ads = const AdsDef(),
  }) : pests = Map.unmodifiable(pests),
       guardians = Map.unmodifiable(guardians),
       levels = List.unmodifiable(levels);

  final BattleRules rules;
  final Map<String, PestDef> pests;
  final Map<String, GuardianDef> guardians;
  final List<LevelDef> levels;
  final ContentTexts texts;
  final AudioDef audio;
  final AdsDef ads;
}
