import 'dart:math' as math;
import '../algorithm/algorithm.dart';
import '../geom/coordinate.dart';
import '../geom/quadrant.dart';
import 'edge.dart';
import 'label.dart';
import 'node.dart';

/**
 * Models the end of an edge incident on a node.
 * EdgeEnds have a direction
 * determined by the direction of the ray from the initial
 * point to the next point.
 * EdgeEnds are comparable under the ordering
 * "a has a greater angle with the x-axis than b".
 * This ordering is used to sort EdgeEnds around a node.
 * @version 1.7
 */
class EdgeEnd implements Comparable {
  Edge edge; // the parent edge of this edge end
  Label? label;

  Node? node; // the node this edge end originates at
  Coordinate? p0, p1; // points of initial line segment
  double dx = 0, dy = 0; // the direction vector for this edge from its starting point
  int quadrant = 0;

  EdgeEnd(this.edge);

  EdgeEnd.withCoords(Edge edge, Coordinate p0, Coordinate p1) : this.withCoordsLabel(edge, p0, p1, null);

  EdgeEnd.withCoordsLabel(this.edge, Coordinate p0, Coordinate p1, Label? label) {
    init(p0, p1);
    this.label = label;
  }

  void init(Coordinate p0, Coordinate p1) {
    this.p0 = p0;
    this.p1 = p1;
    dx = p1.x - p0.x;
    dy = p1.y - p0.y;
    quadrant = Quadrant.quadrant(dx, dy);
    // TODO Assert.isTrue(! (dx == 0 && dy == 0), "EdgeEnd with identical endpoints found");
  }

  Edge getEdge() {
    return edge;
  }

  Label? getLabel() {
    return label;
  }

  Coordinate? getCoordinate() {
    return p0;
  }

  Coordinate? getDirectedCoordinate() {
    return p1;
  }

  int getQuadrant() {
    return quadrant;
  }

  double getDx() {
    return dx;
  }

  double getDy() {
    return dy;
  }

  void setNode(Node node) {
    this.node = node;
  }

  Node? getNode() {
    return node;
  }

  int compareTo(dynamic obj) {
    EdgeEnd e = obj;
    return compareDirection(e);
  }

  /**
   * Implements the total order relation:
   * <p>
   *    a has a greater angle with the positive x-axis than b
   * <p>
   * Using the obvious algorithm of simply computing the angle is not robust,
   * since the angle calculation is obviously susceptible to roundoff.
   * A robust algorithm is:
   * - first compare the quadrant.  If the quadrants
   * are different, it it trivial to determine which vector is "greater".
   * - if the vectors lie in the same quadrant, the computeOrientation function
   * can be used to decide the relative orientation of the vectors.
   */
  int compareDirection(EdgeEnd e) {
    if (dx == e.dx && dy == e.dy) return 0;
    // if the rays are in different quadrants, determining the ordering is trivial
    if (quadrant > e.quadrant) return 1;
    if (quadrant < e.quadrant) return -1;
    // vectors are in the same quadrant - check relative orientation of direction vectors
    // this is > e if it is CCW of e
    return Orientation.index(e.p0!, e.p1!, p1!);
  }

  void computeLabel(BoundaryNodeRule boundaryNodeRule) {
    // subclasses should override this if they are using labels
  }

//   void print(PrintStream out)
//  {
//    double angle = Math.atan2(dy, dx);
//    String className = getClass().getName();
//    int lastDotPos = className.lastIndexOf('.');
//    String name = className.substring(lastDotPos + 1);
//    out.print("  " + name + ": " + p0 + " - " + p1 + " " + quadrant + ":" + angle + "   " + label);
//  }
  String toString() {
    double angle = math.atan2(dy, dx);
    String className = runtimeType.toString();
    int lastDotPos = className.lastIndexOf('.');
    String name = className.substring(lastDotPos + 1);
    return "  $name: $p0  - $p1 $quadrant: $angle    $label";
  }
}
