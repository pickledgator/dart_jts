import '../algorithm/algorithm.dart';
import '../algorithm/locate.dart';
import '../geom/coordinate.dart';
import '../geom/geom.dart';
import '../geom/geometry.dart';
import '../geom/geometry_collection.dart';
import '../geom/linestring.dart';
import '../geom/multilinestring.dart';
import '../geom/multipolygon.dart';
import '../geom/multipoint.dart';
import '../geom/point.dart';
import '../geom/polygon.dart';
import '../geom/position.dart';
import '../geom/util.dart';
import '../util/geom_impl.dart';
import 'edge.dart';
import 'edge_intersection.dart';
import 'index.dart';
import 'label.dart';
import 'node.dart';
import 'planargraph.dart';

/**
 * A GeometryGraph is a graph that models a given Geometry
 * @version 1.7
 */
class GeometryGraph extends PlanarGraph {
  /**
   * This method implements the Boundary Determination Rule
   * for determining whether
   * a component (node or edge) that appears multiple times in elements
   * of a MultiGeometry is in the boundary or the interior of the Geometry
   * <br>
   * The SFS uses the "Mod-2 Rule", which this function implements
   * <br>
   * An alternative (and possibly more intuitive) rule would be
   * the "At Most One Rule":
   *    isInBoundary = (componentCount == 1)
   */
/*
   static bool isInBoundary(int boundaryCount)
  {
    // the "Mod-2 Rule"
    return boundaryCount % 2 == 1;
  }
   static int determineBoundary(int boundaryCount)
  {
    return isInBoundary(boundaryCount) ? Location.BOUNDARY : Location.INTERIOR;
  }
*/

  static int determineBoundary(BoundaryNodeRule boundaryNodeRule, int boundaryCount) {
    return boundaryNodeRule.isInBoundary(boundaryCount) ? Location.BOUNDARY : Location.INTERIOR;
  }

  Geometry? parentGeom;

  /**
   * The lineEdgeMap is a map of the linestring components of the
   * parentGeometry to the edges which are derived from them.
   * This is used to efficiently perform findEdge queries
   */
  Map<LineString, Edge> lineEdgeMap = {};

  BoundaryNodeRule boundaryNodeRule;

  /**
   * If this flag is true, the Boundary Determination Rule will used when deciding
   * whether nodes are in the boundary or not
   */
  bool useBoundaryDeterminationRule = true;
  int argIndex = 0; // the index of this geometry as an argument to a spatial function (used for labelling)
  List? boundaryNodes;
  bool _hasTooFewPoints = false;
  Coordinate? invalidPoint;

  PointOnGeometryLocator? areaPtLocator;

  // for use if geometry is not Polygonal
  final PointLocator ptLocator = new PointLocator();

  EdgeSetIntersector createEdgeSetIntersector() {
    // various options for computing intersections, from slowest to fastest

    // EdgeSetIntersector esi = new SimpleEdgeSetIntersector();
    // EdgeSetIntersector esi = new MonotoneChainIntersector();
    // EdgeSetIntersector esi = new NonReversingChainIntersector();
    // EdgeSetIntersector esi = new SimpleSweepLineIntersector();
    // EdgeSetIntersector esi = new MCSweepLineIntersector();

    //return new SimpleEdgeSetIntersector();
    return new SimpleMCSweepLineIntersector();
  }

  GeometryGraph(int argIndex, Geometry parentGeom)
      : this.args3(argIndex, parentGeom, BoundaryNodeRule.OGC_SFS_BOUNDARY_RULE);

  GeometryGraph.args3(int argIndex, this.parentGeom, this.boundaryNodeRule) {
    this.argIndex = argIndex;
    if (parentGeom != null) {
//      precisionModel = parentGeom.getPrecisionModel();
//      SRID = parentGeom.getSRID();
      addGeometry(parentGeom!);
    }
  }

  /**
   * This constructor is used by clients that wish to add Edges explicitly,
   * rather than adding a Geometry.  (An example is BufferOp).
   */
  // no longer used
//   GeometryGraph(int argIndex, PrecisionModel precisionModel, int SRID) {
//    this(argIndex, null);
//    this.precisionModel = precisionModel;
//    this.SRID = SRID;
//  }
//   PrecisionModel getPrecisionModel()
//  {
//    return precisionModel;
//  }
//   int getSRID() { return SRID; }

  bool hasTooFewPoints() {
    return _hasTooFewPoints;
  }

  Coordinate? getInvalidPoint() {
    return invalidPoint;
  }

  Geometry? getGeometry() {
    return parentGeom;
  }

  BoundaryNodeRule getBoundaryNodeRule() {
    return boundaryNodeRule;
  }

  List getBoundaryNodes() {
    if (boundaryNodes == null) boundaryNodes = nodes.getBoundaryNodes(argIndex);
    return boundaryNodes!;
  }

  List<Coordinate> getBoundaryPoints() {
    List coll = getBoundaryNodes();
    List<Coordinate> pts = []; //..length = (coll.length);
    int i = 0;
    for (Iterator it = coll.iterator; it.moveNext();) {
      Node node = it.current as Node;
      pts.add(node.getCoordinate().copy());
      // pts[i++] = node.getCoordinate().copy();
    }
    return pts;
  }

  Edge? findEdgeFromLine(LineString line) {
    return lineEdgeMap[line];
  }

  void computeSplitEdges(List edgelist) {
    for (Iterator i = edges.iterator; i.moveNext();) {
      Edge e = i.current as Edge;
      e.eiList.addSplitEdges(edgelist);
    }
  }

  void addGeometry(Geometry g) {
    if (g.isEmpty()) return;

    // check if this Geometry should obey the Boundary Determination Rule
    // all collections except MultiPolygons obey the rule
    if (g is MultiPolygon) useBoundaryDeterminationRule = false;

    if (g is Polygon)
      addPolygon(g);
    // LineString also handles LinearRings
    else if (g is LineString)
      addLineString(g);
    else if (g is Point)
      addPoint(g);
    else if (g is MultiPoint)
      addCollection(g);
    else if (g is MultiLineString)
      addCollection(g);
    else if (g is MultiPolygon)
      addCollection(g);
    else if (g is GeometryCollection)
      addCollection(g);
    else
      throw new UnsupportedError(g.runtimeType.toString());
  }

  void addCollection(GeometryCollection gc) {
    for (int i = 0; i < gc.getNumGeometries(); i++) {
      Geometry g = gc.getGeometryN(i);
      addGeometry(g);
    }
  }

  /**
   * Add a Point to the graph.
   */
  void addPoint(Point p) {
    Coordinate coord = p.getCoordinate()!;
    insertPoint(argIndex, coord, Location.INTERIOR);
  }

  /**
   * Adds a polygon ring to the graph.
   * Empty rings are ignored.
   *
   * The left and right topological location arguments assume that the ring is oriented CW.
   * If the ring is in the opposite orientation,
   * the left and right locations must be interchanged.
   */
  void addPolygonRing(LinearRing lr, int cwLeft, int cwRight) {
    // don't bother adding empty holes
    if (lr.isEmpty()) return;

    List<Coordinate> coord = CoordinateArrays.removeRepeatedPoints(lr.getCoordinates());

    if (coord.length < 4) {
      _hasTooFewPoints = true;
      invalidPoint = coord[0];
      return;
    }

    int left = cwLeft;
    int right = cwRight;
    if (Orientation.isCCW(coord)) {
      left = cwRight;
      right = cwLeft;
    }
    Edge e = Edge(coord, Label.args4(argIndex, Location.BOUNDARY, left, right));
    lineEdgeMap[lr] = e;

    insertEdge(e);
    // insert the endpoint as a node, to mark that it is on the boundary
    insertPoint(argIndex, coord[0], Location.BOUNDARY);
  }

  void addPolygon(Polygon p) {
    addPolygonRing(p.getExteriorRing(), Location.EXTERIOR, Location.INTERIOR);

    for (int i = 0; i < p.getNumInteriorRing(); i++) {
      LinearRing hole = p.getInteriorRingN(i);

      // Holes are topologically labelled opposite to the shell, since
      // the interior of the polygon lies on their opposite side
      // (on the left, if the hole is oriented CW)
      addPolygonRing(hole, Location.INTERIOR, Location.EXTERIOR);
    }
  }

  void addLineString(LineString line) {
    List<Coordinate> coord = CoordinateArrays.removeRepeatedPoints(line.getCoordinates());

    if (coord.length < 2) {
      _hasTooFewPoints = true;
      invalidPoint = coord[0];
      return;
    }

    // add the edge for the LineString
    // line edges do not have locations for their left and right sides
    Edge e = new Edge(coord, new Label.args2(argIndex, Location.INTERIOR));
    lineEdgeMap[line] = e;
    insertEdge(e);
    /**
     * Add the boundary points of the LineString, if any.
     * Even if the LineString is closed, add both points as if they were endpoints.
     * This allows for the case that the node already exists and is a boundary point.
     */
    assert(coord.length >= 2, "found LineString with single point");
    insertBoundaryPoint(argIndex, coord[0]);
    insertBoundaryPoint(argIndex, coord[coord.length - 1]);
  }

  /**
   * Add an Edge computed externally.  The label on the Edge is assumed
   * to be correct.
   */
  void addEdge(Edge e) {
    insertEdge(e);
    List<Coordinate> coord = e.getCoordinates();
    // insert the endpoint as a node, to mark that it is on the boundary
    insertPoint(argIndex, coord[0], Location.BOUNDARY);
    insertPoint(argIndex, coord[coord.length - 1], Location.BOUNDARY);
  }

  /**
   * Add a point computed externally.  The point is assumed to be a
   * Point Geometry part, which has a location of INTERIOR.
   */
  void addPointFromCoordinate(Coordinate pt) {
    insertPoint(argIndex, pt, Location.INTERIOR);
  }

  /**
   * Compute self-nodes, taking advantage of the Geometry type to
   * minimize the number of intersection tests.  (E.g. rings are
   * not tested for self-intersection, since they are assumed to be valid).
   *
   * @param li the LineIntersector to use
   * @param computeRingSelfNodes if <code>false</code>, intersection checks are optimized to not test rings for self-intersection
   * @return the computed SegmentIntersector containing information about the intersections found
   */
  SegmentIntersector computeSelfNodes(LineIntersector li, bool computeRingSelfNodes) {
    return computeSelfNodes3(li, computeRingSelfNodes, false);
  }

  /**
   * Compute self-nodes, taking advantage of the Geometry type to
   * minimize the number of intersection tests.  (E.g. rings are
   * not tested for self-intersection, since they are assumed to be valid).
   *
   * @param li the LineIntersector to use
   * @param computeRingSelfNodes if <code>false</code>, intersection checks are optimized to not test rings for self-intersection
   * @param isDoneIfProperInt short-circuit the intersection computation if a proper intersection is found
   * @return the computed SegmentIntersector containing information about the intersections found
   */
  SegmentIntersector computeSelfNodes3(LineIntersector li, bool computeRingSelfNodes, bool isDoneIfProperInt) {
    SegmentIntersector si = new SegmentIntersector(li, true, false);
    si.setIsDoneIfProperInt(isDoneIfProperInt);
    EdgeSetIntersector esi = createEdgeSetIntersector();
    // optimize intersection search for valid Polygons and LinearRings
    bool isRings = parentGeom is LinearRing || parentGeom is Polygon || parentGeom is MultiPolygon;
    bool computeAllSegments = computeRingSelfNodes || !isRings;
    esi.computeIntersections(edges, si, computeAllSegments);

    //System.out.println("SegmentIntersector # tests = " + si.numTests);
    addSelfIntersectionNodes(argIndex);
    return si;
  }

  SegmentIntersector computeEdgeIntersections(GeometryGraph g, LineIntersector li, bool includeProper) {
    SegmentIntersector si = new SegmentIntersector(li, includeProper, true);
    si.setBoundaryNodes(this.getBoundaryNodes(), g.getBoundaryNodes());

    EdgeSetIntersector esi = createEdgeSetIntersector();
    esi.computeIntersections3(edges, g.edges, si);
    /*
    for (Iterator i = g.edges.iterator; i.moveNext();) {
    Edge e = (Edge) i.current
    Debug.print(e.getEdgeIntersectionList());
    }
    */
    return si;
  }

  void insertPoint(int argIndex, Coordinate coord, int onLocation) {
    Node n = nodes.addNodeFromCoordinate(coord);
    Label? lbl = n.getLabel();
    if (lbl == null) {
      n.label = new Label.args2(argIndex, onLocation);
    } else
      lbl.setLocationWithIndex(argIndex, onLocation);
  }

  /**
   * Adds candidate boundary points using the current {@link BoundaryNodeRule}.
   * This is used to add the boundary
   * points of dim-1 geometries (Curves/MultiCurves).
   */
  void insertBoundaryPoint(int argIndex, Coordinate coord) {
    Node n = nodes.addNodeFromCoordinate(coord);
    // nodes always have labels
    Label? lbl = n.getLabel();
    // the new point to insert is on a boundary
    int boundaryCount = 1;
    // determine the current location for the point (if any)
    int loc = Location.NONE;
    loc = lbl!.getLocationWithPosIndex(argIndex, Position.ON);
    if (loc == Location.BOUNDARY) boundaryCount++;

    // determine the boundary status of the point according to the Boundary Determination Rule
    int newLoc = determineBoundary(boundaryNodeRule, boundaryCount);
    lbl.setLocationWithIndex(argIndex, newLoc);
  }

  void addSelfIntersectionNodes(int argIndex) {
    for (Iterator i = edges.iterator; i.moveNext();) {
      Edge e = i.current;
      int eLoc = e.getLabel()!.getLocation(argIndex);
      for (Iterator eiIt = e.eiList.iterator(); eiIt.moveNext();) {
        EdgeIntersection ei = eiIt.current as EdgeIntersection;
        addSelfIntersectionNode(argIndex, ei.coord, eLoc);
      }
    }
  }

  /**
   * Add a node for a self-intersection.
   * If the node is a potential boundary node (e.g. came from an edge which
   * is a boundary) then insert it as a potential boundary node.
   * Otherwise, just add it as a regular node.
   */
  void addSelfIntersectionNode(int argIndex, Coordinate coord, int loc) {
    // if this node is already a boundary node, don't change it
    if (isBoundaryNode(argIndex, coord)) return;
    if (loc == Location.BOUNDARY && useBoundaryDeterminationRule)
      insertBoundaryPoint(argIndex, coord);
    else
      insertPoint(argIndex, coord, loc);
  }

  // MD - experimental for now
  /**
   * Determines the {@link Location} of the given {@link Coordinate}
   * in this geometry.
   *
   * @param pt the point to test
   * @return the location of the point in the geometry
   */
  int locate(Coordinate pt) {
    if (parentGeom is Polygonal && parentGeom!.getNumGeometries() > 50) {
      // lazily init point locator
      if (areaPtLocator == null) {
        areaPtLocator = new IndexedPointInAreaLocator(parentGeom!);
      }
      return areaPtLocator!.locate(pt);
    }
    return ptLocator.locate(pt, parentGeom!);
  }
}
