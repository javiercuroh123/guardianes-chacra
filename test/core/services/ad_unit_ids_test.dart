import 'package:flutter_test/flutter_test.dart';
import 'package:guardianes_chacra/core/services/ad_unit_ids.dart';

void main() {
  test('fuera de release se usan siempre los IDs de prueba de Google', () {
    // Los tests corren en modo debug.
    expect(AdUnitIds.forThisBuild(), same(AdUnitIds.test));
    expect(AdUnitIds.test.rewarded, startsWith('ca-app-pub-3940256099942544/'));
    expect(
      AdUnitIds.test.interstitial,
      startsWith('ca-app-pub-3940256099942544/'),
    );
  });
}
