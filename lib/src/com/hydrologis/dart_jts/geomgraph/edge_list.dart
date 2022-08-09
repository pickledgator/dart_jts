import 'dart:collection';
import '../noding/noding.dart';
import 'edge.dart';

/**
 * A EdgeList is a list of Edges.  It supports locating edges
 * that are pointwise equals to a target edge.
 * @version 1.7
 */
class EdgeList {
  List edges = [];

  /**
   * An index of the edges, for fast lookup.
   *
   */
  Map ocaMap = new SplayTreeMap();

  EdgeList() {}

  /**
   * Insert an edge unless it is already in the list
   */
  void add(Edge e) {
    edges.add(e);
    OrientedCoordinateArray oca = new OrientedCoordinateArray(e.getCoordinates());
    ocaMap[oca] = e;
  }

  void addAll(List<Edge> edgeColl) {
    for (var e in edgeColl) {
      add(e);
    }
  }

  List getEdges() {
    return edges;
  }

  /**
   * If there is an edge equal to e already in the list, return it.
   * Otherwise return null.
   * @return  equal edge, if there is one already in the list
   *          null otherwise
   */
  Edge? findEqualEdge(Edge e) {
    OrientedCoordinateArray oca = new OrientedCoordinateArray(e.getCoordinates());
    // will return null if no edge matches
    Edge? matchEdge = ocaMap[oca];
    return matchEdge;
  }

  Iterator iterator() {
    return edges.iterator;
  }

  Edge get(int i) {
    return edges[i];
  }

  /**
   * If the edge e is already in the list, return its index.
   * @return  index, if e is already in the list
   *          -1 otherwise
   */
  int findEdgeIndex(Edge e) {
    return edges.indexOf(e);
  }

//   void print(PrintStream out)
//  {
//    out.print("MULTILINESTRING ( ");
//    for (int j = 0; j < edges.size(); j++) {
//      Edge e = (Edge) edges.get(j);
//      if (j > 0) out.print(",");
//      out.print("(");
//      Coordinate[] pts = e.getCoordinates();
//      for (int i = 0; i < pts.length; i++) {
//        if (i > 0) out.print(",");
//        out.print(pts[i].x + " " + pts[i].y);
//      }
//      out.println(")");
//    }
//    out.print(")  ");
//  }

}
