enum CreatureStage {
  egg,
  baby,
  adult,
  evolved;

  String get nameKo {
    switch (this) {
      case CreatureStage.egg:     return '알';
      case CreatureStage.baby:    return '유체';
      case CreatureStage.adult:   return '성체';
      case CreatureStage.evolved: return '진화';
    }
  }

  bool get isHatched => this != CreatureStage.egg;
}
