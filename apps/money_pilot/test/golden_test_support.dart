import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// Installs a narrowly tolerant comparator for cross-platform text rendering.
///
/// The same bundled font can rasterize a small number of edge pixels
/// differently on Windows and Linux. A 2.5% threshold keeps the visual tests
/// useful for layout regressions while avoiding operating-system-only noise.
void useCrossPlatformGoldenComparator(Uri testFile) {
  final previousComparator = goldenFileComparator;
  goldenFileComparator = _TolerantGoldenFileComparator(
    testFile,
    precisionTolerance: 0.025,
  );
  addTearDown(() => goldenFileComparator = previousComparator);
}

class _TolerantGoldenFileComparator extends LocalFileComparator {
  _TolerantGoldenFileComparator(
    super.testFile, {
    required double precisionTolerance,
  }) : assert(
         precisionTolerance >= 0 && precisionTolerance <= 1,
         'precisionTolerance must be between 0 and 1',
       ),
       _precisionTolerance = precisionTolerance;

  final double _precisionTolerance;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
      imageBytes,
      await getGoldenBytes(golden),
    );
    final passed = result.passed || result.diffPercent <= _precisionTolerance;
    if (passed) {
      result.dispose();
      return true;
    }

    final error = await generateFailureOutput(result, golden, basedir);
    result.dispose();
    throw FlutterError(error);
  }
}
