import "package:test/test.dart";
import 'package:dart_jts/dart_jts.dart';
import 'package:dart_jts/dart_jts_planar_graph.dart';
import 'testing_utilities.dart';

WKTReader rdr = WKTReader();

void main() {
  group("Line Sequencer Tests - ", () {
    test("Test Simple", () {
      List<String> wkt = ["LINESTRING ( 0 0, 0 10 )", "LINESTRING ( 0 20, 0 30 )", "LINESTRING ( 0 10, 0 20 )"];
      String result = "MULTILINESTRING ((0 0, 0 10), (0 10, 0 20), (0 20, 0 30))";
      runLineSequencer(wkt, result);
    });
    test("Test Simple Loop", () {
      List<String> wkt = ["LINESTRING ( 0 0, 0 10 )", "LINESTRING ( 0 10, 0 0 )"];
      String result = "MULTILINESTRING ((0 0, 0 10), (0 10, 0 0))";
      runLineSequencer(wkt, result);
    });
    test("Test Simple Big Loop", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 0 20, 0 30 )",
        "LINESTRING ( 0 30, 0 00 )",
        "LINESTRING ( 0 10, 0 20 )"
      ];
      String result = "MULTILINESTRING ((0 0, 0 10), (0 10, 0 20), (0 20, 0 30), (0 30, 0 0))";
      runLineSequencer(wkt, result);
    });
    test("Test 2 Simple Loops", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 0 10, 0 0 )",
        "LINESTRING ( 0 0, 0 20 )",
        "LINESTRING ( 0 20, 0 0 )"
      ];
      String result = "MULTILINESTRING ((0 10, 0 0), (0 0, 0 20), (0 20, 0 0), (0 0, 0 10))";
      runLineSequencer(wkt, result);
    });
    test("Test Wide B With Tail", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 10 0, 10 10 )",
        "LINESTRING ( 0 0, 10 0 )",
        "LINESTRING ( 0 10, 10 10 )",
        "LINESTRING ( 0 10, 0 20 )",
        "LINESTRING ( 10 10, 10 20 )",
        "LINESTRING ( 0 20, 10 20 )",
        "LINESTRING ( 10 20, 30 30 )",
      ];
      String? result;
      runLineSequencer(wkt, result);
    });
    test("Test Simple Loop With Tail", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 0 10, 10 10 )",
        "LINESTRING ( 10 10, 10 20, 0 10 )",
      ];
      String result = "MULTILINESTRING ((0 0, 0 10), (0 10, 10 10), (10 10, 10 20, 0 10))";
      runLineSequencer(wkt, result);
    });
    test("Line With Ring", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 0 10, 10 10, 10 20, 0 10 )",
        "LINESTRING ( 0 30, 0 20 )",
        "LINESTRING ( 0 20, 0 10 )",
      ];
      String result = "MULTILINESTRING ((0 0, 0 10), (0 10, 10 10, 10 20, 0 10), (0 10, 0 20), (0 20, 0 30))";
      runLineSequencer(wkt, result);
    });
    test("Multiple Graphs With Ring", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 0 10, 10 10, 10 20, 0 10 )",
        "LINESTRING ( 0 30, 0 20 )",
        "LINESTRING ( 0 20, 0 10 )",
        "LINESTRING ( 0 60, 0 50 )",
        "LINESTRING ( 0 40, 0 50 )",
      ];
      String result =
          "MULTILINESTRING ((0 0, 0 10), (0 10, 10 10, 10 20, 0 10), (0 10, 0 20), (0 20, 0 30), (0 40, 0 50), (0 50, 0 60))";
      runLineSequencer(wkt, result);
    });
    test("Multiple Graphs With Multiple Rings", () {
      List<String> wkt = [
        "LINESTRING ( 0 0, 0 10 )",
        "LINESTRING ( 0 10, 10 10, 10 20, 0 10 )",
        "LINESTRING ( 0 10, 40 40, 40 20, 0 10 )",
        "LINESTRING ( 0 30, 0 20 )",
        "LINESTRING ( 0 20, 0 10 )",
        "LINESTRING ( 0 60, 0 50 )",
        "LINESTRING ( 0 40, 0 50 )",
      ];
      String result =
          "MULTILINESTRING ((0 0, 0 10), (0 10, 40 40, 40 20, 0 10), (0 10, 10 10, 10 20, 0 10), (0 10, 0 20), (0 20, 0 30), (0 40, 0 50), (0 50, 0 60))";
      runLineSequencer(wkt, result);
    });

    // isSequenced Tests
    test("Line Sequence", () {
      String wkt = "LINESTRING ( 0 0, 0 10 )";
      runIsSequenced(wkt, true);
    });
    test("Split Line Sequence", () {
      String wkt = "MULTILINESTRING ((0 0, 0 1), (0 2, 0 3), (0 3, 0 4) )";
      runIsSequenced(wkt, true);
    });
    test("Bad Line Sequence", () {
      String wkt = "MULTILINESTRING ((0 0, 0 1), (0 2, 0 3), (0 1, 0 4) )";
      runIsSequenced(wkt, false);
    });
  });
}

void runLineSequencer(List<String> inputWKT, String? expectedWKT) {
  List<Geometry> inputGeoms = fromWKT(inputWKT);
  LineSequencer sequencer = LineSequencer();
  sequencer.add(inputGeoms);

  bool isCorrect = false;
  if (!sequencer.isSequenceable()) {
    assertTrue(expectedWKT == null);
  } else {
    Geometry? expected = rdr.read(expectedWKT!);
    Geometry? result = sequencer.getSequencedLineStrings();
    bool isOK = expected!.equalsNorm(result!);
    if (!isOK) {
      print("ERROR - Expected: " + expected.toString());
      print("          Actual: " + result.toString());
    }
    assertTrue(isOK);

    bool isSequenced = LineSequencer.isSequenced(result);
    assertTrue(isSequenced);
  }
}

void runIsSequenced(String inputWKT, bool expected) {
  Geometry? g = rdr.read(inputWKT);
  bool isSequenced = LineSequencer.isSequenced(g!);
  assertTrue(isSequenced == expected);
}

List<Geometry> fromWKT(List<String> wkts) {
  List<Geometry> geomList = [];
  for (int i = 0; i < wkts.length; i++) {
    try {
      geomList.add(rdr.read(wkts[i])!);
    } catch (e) {
      print(e.toString());
    }
  }
  return geomList;
}
