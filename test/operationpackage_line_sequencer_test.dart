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
