import '../algorithm/algorithm.dart';
import '../geom/coordinate.dart';
import '../geom/envelope.dart';
import '../geom/position.dart';
import '../geom/util.dart';
import 'depth.dart';
import 'edge_intersection.dart';
import 'edge_intersection_list.dart';
import 'graph_component.dart';
import 'index.dart';
import 'label.dart';

/**
 * @version 1.7
 */
class Edge extends GraphComponent {
  /**
   * Updates an IM from the label for an edge.
   * Handles edges from both L and A geometries.
   */
  static void updateIMStatic(Label label, IntersectionMatrix im) {
    im.setAtLeastIfValid(
        label.getLocationWithPosIndex(0, Position.ON), label.getLocationWithPosIndex(1, Position.ON), 1);
    if (label.isArea()) {
      im.setAtLeastIfValid(
          label.getLocationWithPosIndex(0, Position.LEFT), label.getLocationWithPosIndex(1, Position.LEFT), 2);
      im.setAtLeastIfValid(
          label.getLocationWithPosIndex(0, Position.RIGHT), label.getLocationWithPosIndex(1, Position.RIGHT), 2);
    }
  }

  List<Coordinate> pts;
  Envelope? env;
  late EdgeIntersectionList eiList;
  String? name;
  MonotoneChainEdge? mce;
  bool _isIsolated = true;
  Depth depth = new Depth();
  int depthDelta = 0; // the change in area depth from the R to L side of this edge

  Edge(this.pts, Label? label) {
    eiList = new EdgeIntersectionList(this);
    this.label = label;
  }

  Edge.fromList(List<Coordinate> pts) : this(pts, null);

  int getNumPoints() {
    return pts.length;
  }

  void setName(String name) {
    this.name = name;
  }

  List<Coordinate> getCoordinates() {
    return pts;
  }

  Coordinate getCoordinateWithIndex(int i) {
    return pts[i];
  }

  Coordinate? getCoordinate() {
    if (pts.length > 0) return pts[0];
    return null;
  }

  Envelope getEnvelope() {
    // compute envelope lazily
    if (env == null) {
      env = new Envelope.empty();
      for (int i = 0; i < pts.length; i++) {
        env!.expandToIncludeCoordinate(pts[i]);
      }
    }
    return env!;
  }

  Depth getDepth() {
    return depth;
  }

  /**
   * The depthDelta is the change in depth as an edge is crossed from R to L
   * @return the change in depth as the edge is crossed from R to L
   */
  int getDepthDelta() {
    return depthDelta;
  }

  void setDepthDelta(int depthDelta) {
    this.depthDelta = depthDelta;
  }

  int getMaximumSegmentIndex() {
    return pts.length - 1;
  }

  EdgeIntersectionList getEdgeIntersectionList() {
    return eiList;
  }

  MonotoneChainEdge getMonotoneChainEdge() {
    if (mce == null) mce = new MonotoneChainEdge(this);
    return mce!;
  }

  bool isClosed() {
    return pts[0].equals(pts[pts.length - 1]);
  }

  /**
   * An Edge is collapsed if it is an Area edge and it consists of
   * two segments which are equal and opposite (eg a zero-width V).
   */
  bool isCollapsed() {
    if (!label!.isArea()) return false;
    if (pts.length != 3) return false;
    if (pts[0].equals(pts[2])) return true;
    return false;
  }

  Edge getCollapsedEdge() {
    List<Coordinate> newPts = [];
    newPts[0] = pts[0];
    newPts[1] = pts[1];
    Edge newe = new Edge(newPts, Label.toLineLabel(label!));
    return newe;
  }

  void setIsolated(bool isIsolated) {
    this._isIsolated = isIsolated;
  }

  bool isIsolated() {
    return _isIsolated;
  }

  /**
   * Adds EdgeIntersections for one or both
   * intersections found for a segment of an edge to the edge intersection list.
   */
  void addIntersections(LineIntersector li, int segmentIndex, int geomIndex) {
    for (int i = 0; i < li.getIntersectionNum(); i++) {
      addIntersection(li, segmentIndex, geomIndex, i);
    }
  }

  /**
   * Add an EdgeIntersection for intersection intIndex.
   * An intersection that falls exactly on a vertex of the edge is normalized
   * to use the higher of the two possible segmentIndexes
   */
  void addIntersection(LineIntersector li, int segmentIndex, int geomIndex, int intIndex) {
    Coordinate intPt = new Coordinate.fromCoordinate(li.getIntersection(intIndex));
    int normalizedSegmentIndex = segmentIndex;
    double dist = li.getEdgeDistance(geomIndex, intIndex);
//Debug.println("edge intpt: " + intPt + " dist: " + dist);
    // normalize the intersection point location
    int nextSegIndex = normalizedSegmentIndex + 1;
    if (nextSegIndex < pts.length) {
      Coordinate nextPt = pts[nextSegIndex];
//Debug.println("next pt: " + nextPt);

      // Normalize segment index if intPt falls on vertex
      // The check for point equality is 2D only - Z values are ignored
      if (intPt.equals2D(nextPt)) {
//Debug.println("normalized distance");
        normalizedSegmentIndex = nextSegIndex;
        dist = 0.0;
      }
    }
    /**
     * Add the intersection point to edge intersection list.
     */
    EdgeIntersection ei = eiList.add(intPt, normalizedSegmentIndex, dist);
//ei.print(System.out);
  }

  /**
   * Update the IM with the contribution for this component.
   * A component only contributes if it has a labelling for both parent geometries
   */
  void computeIM(IntersectionMatrix im) {
    updateIMStatic(label!, im);
  }

  /**
   * equals is defined to be:
   * <p>
   * e1 equals e2
   * <b>iff</b>
   * the coordinates of e1 are the same or the reverse of the coordinates in e2
   */
  bool equals(Object o) {
    if (!(o is Edge)) return false;
    Edge e = o;

    if (pts.length != e.pts.length) return false;

    bool isEqualForward = true;
    bool isEqualReverse = true;
    int iRev = pts.length;
    for (int i = 0; i < pts.length; i++) {
      if (!pts[i].equals2D(e.pts[i])) {
        isEqualForward = false;
      }
      if (!pts[i].equals2D(e.pts[--iRev])) {
        isEqualReverse = false;
      }
      if (!isEqualForward && !isEqualReverse) return false;
    }
    return true;
  }

  /**
   * @return true if the coordinate sequences of the Edges are identical
   */
  bool isPointwiseEqual(Edge e) {
    if (pts.length != e.pts.length) return false;

    for (int i = 0; i < pts.length; i++) {
      if (!pts[i].equals2D(e.pts[i])) {
        return false;
      }
    }
    return true;
  }

  String toString() {
    StringBuffer builder = new StringBuffer();
    builder.write("edge " + (name != null ? name! : "") + ": ");
    builder.write("LINESTRING (");
    for (int i = 0; i < pts.length; i++) {
      if (i > 0) builder.write(",");
      builder.write(pts[i].x);
      builder.write(" ");
      builder.write(pts[i].y);
    }
    builder.write(")  $label $depthDelta");
    return builder.toString();
  }

//   void print(PrintStream out)
//  {
//    out.print("edge " + name + ": ");
//    out.print("LINESTRING (");
//    for (int i = 0; i < pts.length; i++) {
//      if (i > 0) out.print(",");
//      out.print(pts[i].x + " " + pts[i].y);
//    }
//    out.print(")  " + label + " " + depthDelta);
//  }
//   void printReverse(PrintStream out)
//  {
//    out.print("edge " + name + ": ");
//    for (int i = pts.length - 1; i >= 0; i--) {
//      out.print(pts[i] + " ");
//    }
//    out.println("");
//  }

}
