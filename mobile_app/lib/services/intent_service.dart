enum FarmIntent { crop, livestock, machinery, residue, services, fhi, unknown }

class IntentSvc {
  static FarmIntent classify(String text) {
    final t = text.toLowerCase();
    if (_has(t, [
      'leaf',
      'crop',
      'plant',
      'disease',
      'fungus',
      'blight',
      'rust',
      'wilt',
      'spot',
      'pest'
    ])) return FarmIntent.crop;
    if (_has(t, [
      'cow',
      'cattle',
      'buffalo',
      'goat',
      'sheep',
      'pig',
      'chicken',
      'animal',
      'vet',
      'sick',
      'symptom'
    ])) return FarmIntent.livestock;
    if (_has(t, [
      'tractor',
      'machine',
      'engine',
      'repair',
      'break',
      'fix',
      'part',
      'pump',
      'harvester'
    ])) return FarmIntent.machinery;
    if (_has(t, [
      'stubble',
      'residue',
      'straw',
      'compost',
      'fodder',
      'burn',
      'waste',
      'bio'
    ])) return FarmIntent.residue;
    if (_has(
        t, ['nearby', 'find', 'dealer', 'shop', 'service', 'contact', 'buy']))
      return FarmIntent.services;
    if (_has(t, ['health', 'score', 'index', 'farm', 'status', 'fhi']))
      return FarmIntent.fhi;
    return FarmIntent.unknown;
  }

  static bool _has(String t, List<String> kw) => kw.any(t.contains);
}
