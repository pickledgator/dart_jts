import '../algorithm/algorithm.dart';
import '../geom/coordinate.dart';
import '../geom/envelope.dart';
import '../geom/geom.dart';
import '../geom/geometry.dart';
import '../geom/linestring.dart';
import '../geom/polygon.dart';
import '../geom/position.dart';
import '../geom/util.dart';
import 'directed_edge.dart';
import 'directed_edge_star.dart';
import 'edge.dart';
import 'label.dart';
import 'node.dart';

/**
 * @version 1.7
 */
abstract class EdgeRing {
  DirectedEdge? startDe; // the directed edge which starts the list of edges for this EdgeRing
  int maxNodeDegree = -1;
  List edges = []; // the DirectedEdges making up this EdgeRing
  List pts = [];
  Label label =
      new Label(Location.NONE); // label stores the locations of each geometry on the face surrounded by this ring
  LinearRing? ring; // the ring created for this EdgeRing
  bool _isHole = false;
  EdgeRing? shell; // if non-null, the ring is a hole and this EdgeRing is its containing shell
  List holes = []; // a list of EdgeRings which are holes in this EdgeRing

  GeometryFactory geometryFactory;

  EdgeRing(DirectedEdge start, this.geometryFactory) {
    computePoints(start);
    computeRing();
  }

  bool isIsolated() {
    return (label.getGeometryCount() == 1);
  }

  bool isHole() {
    //computePoints();
    return _isHole;
  }

  Coordinate getCoordinate(int i) {
    return pts[i];
  }

  LinearRing? getLinearRing() {
    return ring;
  }

  Label getLabel() {
    return label;
  }

  bool isShell() {
    return shell == null;
  }

  EdgeRing? getShell() {
    return shell;
  }

  void setShell(EdgeRing? shell) {
    this.shell = shell;
    if (shell != null) shell.addHole(this);
  }

  void addHole(EdgeRing ring) {
    holes.add(ring);
  }

  Polygon toPolygon(GeometryFactory geometryFactory) {
    List<LinearRing> holeLR = []; //..length = (holes.length);
    for (int i = 0; i < holes.length; i++) {
      holeLR.add((holes[i] as EdgeRing).getLinearRing()!);
      // holeLR[i] = (holes[i] as EdgeRing).getLinearRing()!;
    }
    Polygon poly = geometryFactory.createPolygon(getLinearRing(), holeLR);
    return poly;
  }

  /**
   * Compute a LinearRing from the point list previously collected.
   * Test if the ring is a hole (i.e. if it is CCW) and set the hole flag
   * accordingly.
   */
  void computeRing() {
    if (ring != null) return; // don't compute more than once
    List<Coordinate> coord = []; //..length = (pts.length);
    for (int i = 0; i < pts.length; i++) {
      coord.add(pts[i]);
      // coord[i] = pts[i];
    }
    ring = geometryFactory.createLinearRing(coord);
    _isHole = Orientation.isCCW(ring!.getCoordinates());
//Debug.println( (isHole ? "hole - " : "shell - ") + WKTWriter.toLineString(new CoordinateArraySequence(ring.getCoordinates())));
  }

  DirectedEdge getNext(DirectedEdge de);

  void setEdgeRing(DirectedEdge de, EdgeRing er);

  /**
   * Returns the list of DirectedEdges that make up this EdgeRing
   */
  List getEdges() {
    return edges;
  }

  /**
   * Collect all the points from the DirectedEdges of this ring into a contiguous list
   */
  void computePoints(DirectedEdge start) {
//System.out.println("buildRing");
    startDe = start;
    DirectedEdge de = start;
    bool isFirstEdge = true;
    do {
//      Assert.isTrue(de != null, "found null Directed Edge");
      if (de == null) throw new TopologyException("Found null DirectedEdge");
      if (de.getEdgeRing() == this)
        throw new TopologyException("Directed Edge visited twice during ring-building at ${de.getCoordinate()}");

      edges.add(de);
//Debug.println(de);
//Debug.println(de.getEdge());
      Label label = de.getLabel()!;
      assert(label.isArea());
      mergeLabel(label);
      addPoints(de.getEdge(), de.isForward(), isFirstEdge);
      isFirstEdge = false;
      setEdgeRing(de, this);
      de = getNext(de);
    } while (de != startDe);
  }

  int getMaxNodeDegree() {
    if (maxNodeDegree < 0) computeMaxNodeDegree();
    return maxNodeDegree;
  }

  void computeMaxNodeDegree() {
    maxNodeDegree = 0;
    DirectedEdge de = startDe!;
    do {
      Node node = de.getNode()!;
      int degree = (node.getEdges() as DirectedEdgeStar).getOutgoingDegreeWithRing(this);
      if (degree > maxNodeDegree) maxNodeDegree = degree;
      de = getNext(de);
    } while (de != startDe);
    maxNodeDegree *= 2;
  }

  void setInResult() {
    DirectedEdge de = startDe!;
    do {
      de.getEdge().setInResult(true);
      de = de.getNext();
    } while (de != startDe);
  }

  void mergeLabel(Label deLabel) {
    mergeLabelWithIndex(deLabel, 0);
    mergeLabelWithIndex(deLabel, 1);
  }

  /**
   * Merge the RHS label from a DirectedEdge into the label for this EdgeRing.
   * The DirectedEdge label may be null.  This is acceptable - it results
   * from a node which is NOT an intersection node between the Geometries
   * (e.g. the end node of a LinearRing).  In this case the DirectedEdge label
   * does not contribute any information to the overall labelling, and is simply skipped.
   */
  void mergeLabelWithIndex(Label deLabel, int geomIndex) {
    int loc = deLabel.getLocationWithPosIndex(geomIndex, Position.RIGHT);
    // no information to be had from this label
    if (loc == Location.NONE) return;
    // if there is no current RHS value, set it
    if (label.getLocation(geomIndex) == Location.NONE) {
      label.setLocationWithIndex(geomIndex, loc);
      return;
    }
  }

  void addPoints(Edge edge, bool isForward, bool isFirstEdge) {
    List<Coordinate> edgePts = edge.getCoordinates();
    if (isForward) {
      int startIndex = 1;
      if (isFirstEdge) startIndex = 0;
      for (int i = startIndex; i < edgePts.length; i++) {
        pts.add(edgePts[i]);
      }
    } else {
      // is backward
      int startIndex = edgePts.length - 2;
      if (isFirstEdge) startIndex = edgePts.length - 1;
      for (int i = startIndex; i >= 0; i--) {
        pts.add(edgePts[i]);
      }
    }
  }

  /**
   * This method will cause the ring to be computed.
   * It will also check any holes, if they have been assigned.
   */
  bool containsPoint(Coordinate p) {
    LinearRing shell = getLinearRing()!;
    Envelope env = shell.getEnvelopeInternal();
    if (!env.containsCoordinate(p)) return false;
    if (!PointLocation.isInRing(p, shell.getCoordinates())) return false;

    for (Iterator i = holes.iterator; i.moveNext();) {
      EdgeRing hole = i.current as EdgeRing;
      if (hole.containsPoint(p)) return false;
    }
    return true;
  }
}
