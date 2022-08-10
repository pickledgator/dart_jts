import 'dart:math' as math;
import '../algorithm/algorithm.dart';
import '../geom/coordinate.dart';
import '../geom/quadrant.dart';
import 'edge.dart';
import 'graph_component.dart';
import 'node.dart';

class DirectedEdge extends GraphComponent implements Comparable {
  Edge? _parentEdge;
  Node _from;
  Node _to;
  late Coordinate _p0;
  late Coordinate _p1;
  DirectedEdge? _sym = null;
  bool _edgeDirection;
  late int _quadrant;
  late double _angle;

  /**
   * Returns a List containing the parent Edge (possibly null) for each of the given
   * DirectedEdges
   */
  static List<Edge> toEdges(List dirEdges) {
    List<Edge> edges = [];
    for (Iterator i = dirEdges.iterator; i.moveNext();) {
      edges.add((i.current as DirectedEdge).getEdge()!);
    }
    return edges;
  }

  /**
   * Constructs a DirectedEdge connecting the <code>from</code> node to the
   * <code>to</code> node.
   *
   * @param directionPt
   *   specifies this DirectedEdge's direction vector
   *   (determined by the vector from the <code>from</code> node
   *   to <code>directionPt</code>)
   * @param edgeDirection
   *   whether this DirectedEdge's direction is the same as or
   *   opposite to that of the parent Edge (if any)
   */
  DirectedEdge(Node from, Node to, Coordinate directionPt, bool edgeDirection)
      : _from = from,
        _to = to,
        _edgeDirection = edgeDirection {
    _p0 = from.getCoordinate()!;
    _p1 = directionPt;
    double dx = _p1.x - _p0.x;
    double dy = _p1.y - _p0.y;
    _quadrant = Quadrant.quadrant(dx, dy);
    _angle = math.atan2(dy, dx);
  }

  /**
   * Returns this DirectedEdge's parent Edge, or null if it has none.
   */
  Edge? getEdge() {
    return _parentEdge;
  }

  /**
   * Associates this DirectedEdge with an Edge (possibly null, indicating no associated
   * Edge).
   */
  void setEdge(Edge parentEdge) {
    _parentEdge = parentEdge;
  }

  /**
   * Returns 0, 1, 2, or 3, indicating the quadrant in which this DirectedEdge's
   * orientation lies.
   */
  int getQuadrant() {
    return _quadrant;
  }

  /**
   * Returns a point to which an imaginary line is drawn from the from-node to
   * specify this DirectedEdge's orientation.
   */
  Coordinate getDirectionPt() {
    return _p1;
  }

  /**
   * Returns whether the direction of the parent Edge (if any) is the same as that
   * of this Directed Edge.
   */
  bool getEdgeDirection() {
    return _edgeDirection;
  }

  /**
   * Returns the node from which this DirectedEdge leaves.
   */
  Node getFromNode() {
    return _from;
  }

  /**
   * Returns the node to which this DirectedEdge goes.
   */
  Node getToNode() {
    return _to;
  }

  /**
   * Returns the coordinate of the from-node.
   */
  Coordinate getCoordinate() {
    return _from.getCoordinate()!;
  }

  /**
   * Returns the angle that the start of this DirectedEdge makes with the
   * positive x-axis, in radians.
   */
  double getAngle() {
    return _angle;
  }

  /**
   * Returns the symmetric DirectedEdge -- the other DirectedEdge associated with
   * this DirectedEdge's parent Edge.
   */
  DirectedEdge? getSym() {
    return _sym;
  }

  /**
   * Sets this DirectedEdge's symmetric DirectedEdge, which runs in the opposite
   * direction.
   */
  void setSym(DirectedEdge? sym) {
    _sym = sym;
  }

  /**
   * Removes this directed edge from its containing graph.
   */
  void remove() {
    _sym = null;
    _parentEdge = null;
  }

  /**
   * Tests whether this directed edge has been removed from its containing graph
   *
   * @return <code>true</code> if this directed edge is removed
   */
  bool isRemoved() {
    return _parentEdge == null;
  }

  /**
   * Returns 1 if this DirectedEdge has a greater angle with the
   * positive x-axis than b", 0 if the DirectedEdges are collinear, and -1 otherwise.
   * <p>
   * Using the obvious algorithm of simply computing the angle is not robust,
   * since the angle calculation is susceptible to roundoff. A robust algorithm
   * is:
   * <ul>
   * <li>first compare the quadrants. If the quadrants are different, it it
   * trivial to determine which vector is "greater".
   * <li>if the vectors lie in the same quadrant, the robust
   * {@link Orientation#index(Coordinate, Coordinate, Coordinate)}
   * function can be used to decide the relative orientation of the vectors.
   * </ul>
   */
  @override
  int compareTo(dynamic obj) {
    DirectedEdge de = obj as DirectedEdge;
    return compareDirection(de);
  }

  /**
   * Returns 1 if this DirectedEdge has a greater angle with the
   * positive x-axis than b", 0 if the DirectedEdges are collinear, and -1 otherwise.
   * <p>
   * Using the obvious algorithm of simply computing the angle is not robust,
   * since the angle calculation is susceptible to roundoff. A robust algorithm
   * is:
   * <ul>
   * <li>first compare the quadrants. If the quadrants are different, it it
   * trivial to determine which vector is "greater".
   * <li>if the vectors lie in the same quadrant, the robust
   * {@link Orientation#index(Coordinate, Coordinate, Coordinate)}
   * function can be used to decide the relative orientation of the vectors.
   * </ul>
   */
  int compareDirection(DirectedEdge e) {
    // if the rays are in different quadrants, determining the ordering is trivial
    if (_quadrant > e.getQuadrant()) return 1;
    if (_quadrant < e.getQuadrant()) return -1;
    // vectors are in the same quadrant - check relative orientation of direction vectors
    // this is > e if it is CCW of e
    return Orientation.index(e._p0, e._p1, _p1);
  }

  /**
   * Prints a detailed string representation of this DirectedEdge to the given PrintStream.
   */
  String toString() {
    String className = runtimeType.toString();
    int lastDotPos = className.lastIndexOf('.');
    String name = className.substring(lastDotPos + 1);
    return "  $name: $_p0  - $_p1 $_quadrant: $_angle";
  }
}
