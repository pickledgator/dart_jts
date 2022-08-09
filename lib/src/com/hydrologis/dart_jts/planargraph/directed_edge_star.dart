import '../geom/coordinate.dart';
import 'directed_edge.dart';
import 'edge.dart';

/**
 * A sorted collection of {@link DirectedEdge}s which leave a {@link Node}
 * in a {@link PlanarGraph}.
 *
 * @version 1.7
 */
class DirectedEdgeStar {
  /**
   * The underlying list of outgoing DirectedEdges
   */
  List<DirectedEdge> outEdges = [];
  bool sorted = false;

  /**
   * Constructs a DirectedEdgeStar with no edges.
   */
  DirectedEdgeStar() {}

  /**
   * Adds a new member to this DirectedEdgeStar.
   */
  void add(DirectedEdge de) {
    outEdges.add(de);
    sorted = false;
  }

  /**
   * Drops a member of this DirectedEdgeStar.
   */
  void remove(DirectedEdge de) {
    outEdges.remove(de);
  }

  /**
   * Returns an Iterator over the DirectedEdges, in ascending order by angle with the positive x-axis.
   */
  Iterator<DirectedEdge> iterator() {
    sortEdges();
    return outEdges.iterator;
  }

  /**
   * Returns the number of edges around the Node associated with this DirectedEdgeStar.
   */
  int getDegree() {
    return outEdges.length;
  }

  /**
   * Returns the coordinate for the node at which this star is based
   */
  Coordinate? getCoordinate() {
    Iterator<DirectedEdge> it = iterator();
    if (!it.moveNext()) return null;
    DirectedEdge e = it.current;
    return e.getCoordinate();
  }

  /**
   * Returns the DirectedEdges, in ascending order by angle with the positive x-axis.
   */
  List<DirectedEdge> getEdges() {
    sortEdges();
    return outEdges;
  }

  void sortEdges() {
    if (!sorted) {
      outEdges.sort();
      sorted = true;
    }
  }

  /**
   * Returns the zero-based index of the given Edge, after sorting in ascending order
   * by angle with the positive x-axis.
   */
  int getIndexOfEdge(Edge edge) {
    sortEdges();
    for (int i = 0; i < outEdges.length; i++) {
      DirectedEdge de = outEdges[i];
      if (de.getEdge() == edge) return i;
    }
    return -1;
  }

  /**
   * Returns the zero-based index of the given DirectedEdge, after sorting in ascending order
   * by angle with the positive x-axis.
   */
  int getIndexOfDirectedEdge(DirectedEdge dirEdge) {
    sortEdges();
    for (int i = 0; i < outEdges.length; i++) {
      DirectedEdge de = outEdges[i];
      if (de == dirEdge) return i;
    }
    return -1;
  }

  /**
   * Returns value of i modulo the number of edges in this DirectedEdgeStar
   * (i.e. the remainder when i is divided by the number of edges)
   * 
   * @param i an integer (positive, negative or zero)
   */
  int getIndex(int i) {
    int modi = i % outEdges.length;
    //I don't think modi can be 0 (assuming i is positive) [Jon Aquino 10/28/2003]
    if (modi < 0) modi += outEdges.length;
    return modi;
  }

  /**
   * Returns the {@link DirectedEdge} on the left-hand (CCW) 
   * side of the given {@link DirectedEdge} 
   * (which must be a member of this DirectedEdgeStar). 
   */
  DirectedEdge getNextEdge(DirectedEdge dirEdge) {
    int i = getIndexOfDirectedEdge(dirEdge);
    return outEdges[getIndex(i + 1)];
  }

  /**
   * Returns the {@link DirectedEdge} on the right-hand (CW) 
   * side of the given {@link DirectedEdge} 
   * (which must be a member of this DirectedEdgeStar). 
   */
  DirectedEdge getNextCWEdge(DirectedEdge dirEdge) {
    int i = getIndexOfDirectedEdge(dirEdge);
    return outEdges[getIndex(i - 1)];
  }
}
