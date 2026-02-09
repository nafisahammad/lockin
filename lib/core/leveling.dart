class Leveling {
  static const _levels = [
    _LevelTier(level: 1, title: 'Rookie', points: 0),
    _LevelTier(level: 5, title: 'Consistent', points: 250),
    _LevelTier(level: 10, title: 'Focused', points: 700),
    _LevelTier(level: 20, title: 'Unstoppable', points: 1500),
    _LevelTier(level: 50, title: 'Elite', points: 3500),
    _LevelTier(level: 100, title: 'Locked In Legend', points: 7000),
  ];

  static int levelForPoints(int points) {
    var current = _levels.first;
    for (final tier in _levels) {
      if (points >= tier.points) {
        current = tier;
      }
    }
    return current.level;
  }

  static String titleForLevel(int level) {
    var title = _levels.first.title;
    for (final tier in _levels) {
      if (level >= tier.level) {
        title = tier.title;
      }
    }
    return title;
  }
}

class _LevelTier {
  const _LevelTier({
    required this.level,
    required this.title,
    required this.points,
  });

  final int level;
  final String title;
  final int points;
}
