import "package:test/test.dart";
import 'package:dart_jts/dart_jts.dart';
import 'package:dart_jts/dart_jts_planar_graph.dart';
import 'testing_utilities.dart';

WKTReader rdr = WKTReader();

void main() {
  group("Line Merger Tests - ", () {
    test("Test 1", () {
      doTest(["LINESTRING (120 120, 180 140)", "LINESTRING (200 180, 180 140)", "LINESTRING (200 180, 240 180)"],
          ["LINESTRING (120 120, 180 140, 200 180, 240 180)"]);
    });
    test("Test 2", () {
      doTest([
        "LINESTRING (120 300, 80 340)",
        "LINESTRING (120 300, 140 320, 160 320)",
        "LINESTRING (40 320, 20 340, 0 320)",
        "LINESTRING (0 320, 20 300, 40 320)",
        "LINESTRING (40 320, 60 320, 80 340)",
        "LINESTRING (160 320, 180 340, 200 320)",
        "LINESTRING (200 320, 180 300, 160 320)"
      ], [
        "LINESTRING (160 320, 180 340, 200 320, 180 300, 160 320)",
        "LINESTRING (40 320, 20 340, 0 320, 20 300, 40 320)",
        "LINESTRING (40 320, 60 320, 80 340, 120 300, 140 320, 160 320)"
      ]);
    });
    test("Test 3", () {
      doTest(["LINESTRING (0 0, 100 100)", "LINESTRING (0 100, 100 0)"],
          ["LINESTRING (0 0, 100 100)", "LINESTRING (0 100, 100 0)"]);
    });
    test("Test 4", () {
      doTest(["LINESTRING EMPTY", "LINESTRING EMPTY"], []);
    });
    test("Test 5", () {
      doTest([], []);
    });
    test("Test Single Unique Point", () {
      doTest(["LINESTRING (10642 31441, 10642 31441)", "LINESTRING EMPTY"], []);
    });
  });
}

void doTest(List<String> inputWKT, List<String> expectedOutputWKT) {
  doTestCompareDirections(inputWKT, expectedOutputWKT, true);
}

void doTestCompareDirections(List<String> inputWKT, List<String> expectedOutputWKT, bool compareDirections) {
  LineMerger lineMerger = new LineMerger();
  lineMerger.addGeometries(toGeometries(inputWKT));
  compare(toGeometries(expectedOutputWKT), lineMerger.getMergedLineStrings() as List<Geometry>, compareDirections);
}

void compare(List<Geometry> expectedGeometries, List<Geometry> actualGeometries, bool compareDirections) {
  assertEquals(expectedGeometries.length, actualGeometries.length);
  for (Iterator i = expectedGeometries.iterator; i.moveNext();) {
    Geometry expectedGeometry = i.current;
    assertTrue(containsGeometry(actualGeometries, expectedGeometry, compareDirections));
  }
}

bool containsGeometry(List<Geometry> geometries, Geometry g, bool exact) {
  for (Iterator i = geometries.iterator; i.moveNext();) {
    Geometry element = i.current;
    if (exact && element.equalsExactGeom(g)) {
      return true;
    }
    if (!exact && element.equalsTopo(g)) {
      return true;
    }
  }

  return false;
}

List<Geometry> toGeometries(List<String> inputWKT) {
  List<Geometry> geometries = [];
  for (int i = 0; i < inputWKT.length; i++) {
    try {
      geometries.add(rdr.read(inputWKT[i])!);
    } catch (e) {
      Assert.shouldNeverReachHere();
    }
  }

  return geometries;
}
