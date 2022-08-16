import "package:test/test.dart";
import 'package:dart_jts/dart_jts.dart';
import 'package:dart_jts/dart_jts_planar_graph.dart';

// Based on the test case from:
// https://github.com/locationtech/jts/blob/master/modules/core/src/test/java/org/locationtech/jts/planargraph/DirectedEdgeTest.java

void main() {
  group("DirectedEdge - ", () {
    test('Comparitor', () {
      DirectedEdge d1 =
          DirectedEdge(Node(Coordinate(0, 0), null), Node(Coordinate(10, 10), null), Coordinate(10, 10), true);
      DirectedEdge d2 =
          DirectedEdge(Node(Coordinate(0, 0), null), Node(Coordinate(20, 20), null), Coordinate(20, 20), false);
      expect(0, d2.compareTo(d1));
    });
    test('ToEdges', () {
      DirectedEdge d1 =
          DirectedEdge(Node(Coordinate(0, 0), null), Node(Coordinate(10, 10), null), Coordinate(10, 10), true);
      DirectedEdge d2 =
          DirectedEdge(Node(Coordinate(20, 0), null), Node(Coordinate(20, 10), null), Coordinate(20, 10), false);
      List<Edge?> edges = DirectedEdge.toEdges([d1, d2]);
      expect(2, edges.length);
      expect(edges[0], null);
      expect(edges[1], null);
    });
  });
}
