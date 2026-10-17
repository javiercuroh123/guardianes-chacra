part of 'simulation.dart';

/// Los comandos del jugador. Están aparte para que `simulation.dart` se
/// quede con las fases del tick; como es parte de la misma librería, puede
/// usar el estado privado de la [Simulation].
extension _Commands on Simulation {
  void _applyCommands() {
    final commands = List.of(_commands);
    _commands.clear();
    for (final command in commands) {
      switch (command) {
        case CallNextWave():
          _callNextWave(command);
        case BuildGuardian():
          _build(command);
        case UpgradeGuardian():
          _upgrade(command);
        case SpecializeGuardian():
          _specialize(command);
        case SellGuardian():
          _sell(command);
        case SetTargeting():
          _setTargeting(command);
        case SkipWave():
          _skipWave();
        case StressTest(:final count):
          _stressRemaining += count;
      }
    }
  }

  void _callNextWave(CallNextWave command) {
    final bonus = earlyCallBonus;
    final waveNumber = _spawner.startedWaves + 1;
    if (_spawner.callNextWave() == null) {
      return _reject(command, RejectionReason.noWaveWaiting);
    }
    events.publish(
      WaveStarted(_tick, waveNumber: waveNumber, calledEarly: true),
    );
    _earnCorn(bonus);
  }

  /// Truco de desarrollo: las plagas en pantalla desaparecen sin dar maíz,
  /// la oleada que aparecía termina y empieza la siguiente.
  void _skipWave() {
    for (final pest in _pests) {
      if (!pest.isAlive) continue;
      pest.removed = true;
      _aliveByWave[pest.wave]--;
      events.publish(
        PestDefeated(_tick, pestId: pest.id, pestType: pest.def.id, reward: 0),
      );
    }
    _pests.removeWhere((pest) => pest.removed);
    _spawner.finishActiveWave();
    final waveNumber = _spawner.startedWaves + 1;
    if (_spawner.callNextWave() != null) {
      events.publish(
        WaveStarted(_tick, waveNumber: waveNumber, calledEarly: true),
      );
    }
  }

  void _build(BuildGuardian command) {
    final slot = _slots[command.slotId];
    if (slot == null) return _reject(command, RejectionReason.unknownSlot);
    if (_guardians.any((other) => other.slotId == slot.id)) {
      return _reject(command, RejectionReason.slotOccupied);
    }
    final def = _guardianDefs[command.guardianType];
    if (def == null) {
      return _reject(command, RejectionReason.unknownGuardianType);
    }
    final level = def.levels.first;
    if (!canAfford(level.cost)) {
      return _reject(command, RejectionReason.notEnoughCorn);
    }

    final guardian = Guardian(
      id: _nextGuardianId++,
      def: def,
      slotId: slot.id,
      position: slot.position,
      targeting: _registry.targeting(def.defaultTargeting),
      targetingId: def.defaultTargeting,
      behaviors: _createBehaviors(level),
      totalSpent: level.cost,
    );
    _guardians.add(guardian);
    events.publish(
      GuardianBuilt(
        _tick,
        guardianId: guardian.id,
        guardianType: def.id,
        slotId: slot.id,
      ),
    );
    _spendCorn(level.cost);
  }

  void _upgrade(UpgradeGuardian command) {
    final guardian = _guardianById(command.guardianId);
    if (guardian == null) {
      return _reject(command, RejectionReason.guardianNotFound);
    }
    final def = guardian.def;
    final atLastLevel = guardian.levelIndex == def.levels.length - 1;
    if (guardian.branch != null || (atLastLevel && def.branches.isEmpty)) {
      return _reject(command, RejectionReason.maxLevel);
    }
    if (atLastLevel) return _reject(command, RejectionReason.chooseBranch);

    final next = def.levels[guardian.levelIndex + 1];
    if (!canAfford(next.cost)) {
      return _reject(command, RejectionReason.notEnoughCorn);
    }
    guardian
      ..levelIndex += 1
      ..behaviors = _createBehaviors(next)
      ..totalSpent += next.cost;
    events.publish(
      GuardianUpgraded(_tick, guardianId: guardian.id, level: guardian.level),
    );
    _spendCorn(next.cost);
  }

  void _specialize(SpecializeGuardian command) {
    final guardian = _guardianById(command.guardianId);
    if (guardian == null) {
      return _reject(command, RejectionReason.guardianNotFound);
    }
    final def = guardian.def;
    if (guardian.branch != null ||
        guardian.levelIndex != def.levels.length - 1) {
      return _reject(command, RejectionReason.cannotSpecialize);
    }
    final branch = def.branches
        .where((branch) => branch.id == command.branchId)
        .firstOrNull;
    if (branch == null) return _reject(command, RejectionReason.unknownBranch);
    if (!canAfford(branch.level.cost)) {
      return _reject(command, RejectionReason.notEnoughCorn);
    }

    guardian
      ..branch = branch
      ..behaviors = _createBehaviors(branch.level)
      ..totalSpent += branch.level.cost;
    events.publish(
      GuardianSpecialized(_tick, guardianId: guardian.id, branchId: branch.id),
    );
    _spendCorn(branch.level.cost);
  }

  /// Los proyectiles que ya lanzó siguen su vuelo.
  void _sell(SellGuardian command) {
    final guardian = _guardianById(command.guardianId);
    if (guardian == null) {
      return _reject(command, RejectionReason.guardianNotFound);
    }
    final refund = sellValueOf(guardian);
    _guardians.remove(guardian);
    events.publish(
      GuardianSold(_tick, guardianId: guardian.id, refund: refund),
    );
    _earnCorn(refund);
  }

  void _setTargeting(SetTargeting command) {
    final guardian = _guardianById(command.guardianId);
    if (guardian == null) {
      return _reject(command, RejectionReason.guardianNotFound);
    }
    if (!_registry.hasTargeting(command.strategy)) {
      return _reject(command, RejectionReason.unknownTargeting);
    }
    guardian
      ..targeting = _registry.targeting(command.strategy)
      ..targetingId = command.strategy;
    events.publish(
      TargetingChanged(
        _tick,
        guardianId: guardian.id,
        strategy: command.strategy,
      ),
    );
  }

  Guardian? _guardianById(int id) =>
      _guardians.where((guardian) => guardian.id == id).firstOrNull;

  void _reject(PlayerCommand command, RejectionReason reason) =>
      events.publish(CommandRejected(_tick, command: command, reason: reason));
}
