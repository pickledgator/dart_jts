import 'dart:collection';
import 'package:kt_dart/kt.dart';

import '../geom/coordinate.dart';
import '../geom/geom.dart';
import '../geom/geometry.dart';
import '../geom/linestring.dart';
import '../geom/multilinestring.dart';
import '../geom/util.dart';
import '../planargraph/algorithm/connected_subgraph_finder.dart';
import '../planargraph/directed_edge.dart';
import '../planargraph/edge.dart';
import '../planargraph/graph_component.dart';
import '../planargraph/node.dart';
import '../planargraph/planar_graph.dart';
import '../planargraph/subgraph.dart';
import '../util/geom_impl.dart';

// Dart doesn't have Int.max, so we implement a work around
final int maxInt = (double.infinity is int) ? double.infinity as int : ~minInt;
final int minInt = (double.infinity is int) ? -double.infinity as int : (-1 << 63);

/**
 * A sequence of {@link LineMergeDirectedEdge}s forming one of the lines that will
 * be output by the line-merging process.
 *
 * @version 1.7
 */
class EdgeString {
  GeometryFactory factory;
  List<DirectedEdge> directedEdges = [];
  List<Coordinate>? coordinates;

  /**
   * Constructs an EdgeString with the given factory used to convert this EdgeString
   * to a LineString
   */
  EdgeString(this.factory) {}

  /**
   * Adds a directed edge which is known to form part of this line.
   */
  void add(LineMergeDirectedEdge directedEdge) {
    directedEdges.add(directedEdge);
  }

  /**
   * Returns the coordinates of the edge string
   */
  List<Coordinate>? getCoordinates() {
    if (coordinates == null) {
      int forwardDirectedEdges = 0;
      int reverseDirectedEdges = 0;
      CoordinateList coordinateList = new CoordinateList();
      for (Iterator i = directedEdges.iterator; i.moveNext();) {
        LineMergeDirectedEdge directedEdge = i.current as LineMergeDirectedEdge;
        if (directedEdge.getEdgeDirection()) {
          forwardDirectedEdges++;
        } else {
          reverseDirectedEdges++;
        }
        List<Coordinate> coordinates = (directedEdge.getEdge() as LineMergeEdge).getLine().getCoordinates();
        // API change here to support multiple types of add
        coordinateList.add3(coordinates, false, directedEdge.getEdgeDirection());
      }
      coordinates = coordinateList.toCoordinateArray();
      if (reverseDirectedEdges > forwardDirectedEdges) {
        CoordinateArrays.reverse(coordinates!);
      }
    }

    return coordinates;
  }

  /**
   * Converts this EdgeString into a LineString.
   */
  LineString toLineString() {
    return factory.createLineString(getCoordinates());
  }
}

/**
 * A {@link org.locationtech.jts.planargraph.DirectedEdge} of a 
 * {@link LineMergeGraph}. 
 *
 * @version 1.7
 */
class LineMergeDirectedEdge extends DirectedEdge {
  /**
   * Constructs a LineMergeDirectedEdge connecting the <code>from</code> node to the
   * <code>to</code> node.
   *
   * @param directionPt
   *                  specifies this DirectedEdge's direction (given by an imaginary
   *                  line from the <code>from</code> node to <code>directionPt</code>)
   * @param edgeDirection
   *                  whether this DirectedEdge's direction is the same as or
   *                  opposite to that of the parent Edge (if any)
   */
  LineMergeDirectedEdge(Node from, Node to, Coordinate directionPt, bool edgeDirection)
      : super(from, to, directionPt, edgeDirection) {}

  /**
   * Returns the directed edge that starts at this directed edge's end point, or null
   * if there are zero or multiple directed edges starting there.  
   * @return the directed edge
   */
  LineMergeDirectedEdge? getNext() {
    if (getToNode().getDegree() != 2) {
      return null;
    }
    if (getToNode().getOutEdges()!.getEdges()[0] == getSym()) {
      return getToNode().getOutEdges()!.getEdges()[1] as LineMergeDirectedEdge;
    }
    assert(getToNode().getOutEdges()!.getEdges()[1] == getSym());

    return getToNode().getOutEdges()!.getEdges()[0] as LineMergeDirectedEdge;
  }
}

/**
 * An edge of a {@link LineMergeGraph}. The <code>marked</code> field indicates
 * whether this Edge has been logically deleted from the graph.
 *
 * @version 1.7
 */
class LineMergeEdge extends Edge {
  LineString line;

  /**
   * Constructs a LineMergeEdge with vertices given by the specified LineString.
   */
  LineMergeEdge(this.line) {}

  /**
   * Returns the LineString specifying the vertices of this edge.
   */
  LineString getLine() {
    return line;
  }
}

/**
 * A planar graph of edges that is analyzed to sew the edges together. The 
 * <code>marked</code> flag on {@link org.locationtech.jts.planargraph.Edge}s
 * and {@link org.locationtech.jts.planargraph.Node}s indicates whether they have been
 * logically deleted from the graph.
 *
 * @version 1.7
 */
class LineMergeGraph extends PlanarGraph {
  /**
   * Adds an Edge, DirectedEdges, and Nodes for the given LineString representation
   * of an edge. 
   * Empty lines or lines with all coordinates equal are not added.
   * Note API difference here to avoid overriding super method
   * 
   * @param lineString the linestring to add to the graph
   */
  void addEdgefromLineString(LineString lineString) {
    if (lineString.isEmpty()) {
      return;
    }

    List<Coordinate> coordinates = CoordinateArrays.removeRepeatedPoints(lineString.getCoordinates());

    // don't add lines with all coordinates equal
    if (coordinates.length <= 1) return;

    Coordinate startCoordinate = coordinates[0];
    Coordinate endCoordinate = coordinates[coordinates.length - 1];
    Node startNode = getNode(startCoordinate);
    Node endNode = getNode(endCoordinate);
    DirectedEdge directedEdge0 = new LineMergeDirectedEdge(startNode, endNode, coordinates[1], true);
    DirectedEdge directedEdge1 =
        new LineMergeDirectedEdge(endNode, startNode, coordinates[coordinates.length - 2], false);
    Edge edge = LineMergeEdge(lineString);
    edge.setDirectedEdges(directedEdge0, directedEdge1);
    super.addEdge(edge);
  }

  Node getNode(Coordinate coordinate) {
    Node? node = findNode(coordinate);
    if (node == null) {
      node = Node(coordinate, null);
      super.addNode(node);
    }

    return node;
  }
}

/**
 * Builds a sequence from a set of LineStrings so that
 * they are ordered end to end.
 * A sequence is a complete non-repeating list of the linear
 * components of the input.  Each linestring is oriented
 * so that identical endpoints are adjacent in the list.
 * <p>
 * A typical use case is to convert a set of 
 * unoriented geometric links 
 * from a linear network
 * (e.g. such as block faces on a bus route)
 * into a continuous oriented path through the network. 
 * <p>
 * The input linestrings may form one or more connected sets.
 * The input linestrings should be correctly noded, or the results may
 * not be what is expected.
 * The computed output is a single {@link MultiLineString} containing the ordered
 * linestrings in the sequence.
 * <p>
 * The sequencing employs the classic <b>Eulerian path</b> graph algorithm.
 * Since Eulerian paths are not uniquely determined,
 * further rules are used to
 * make the computed sequence preserve as much as possible of the input
 * ordering.
 * Within a connected subset of lines, the ordering rules are:
 * <ul>
 * <li>If there is degree-1 node which is the start
 * node of an linestring, use that node as the start of the sequence
 * <li>If there is a degree-1 node which is the end
 * node of an linestring, use that node as the end of the sequence
 * <li>If the sequence has no degree-1 nodes, use any node as the start
 * </ul>
 *
 * Note that not all arrangements of lines can be sequenced.
 * For a connected set of edges in a graph,
 * <i>Euler's Theorem</i> states that there is a sequence containing each edge once
 * <b>if and only if</b> there are no more than 2 nodes of odd degree.
 * If it is not possible to find a sequence, the {@link #isSequenceable()} method
 * will return <code>false</code>.
 *
 * @version 1.7
 */
class LineSequencer {
  LineMergeGraph graph = new LineMergeGraph();
  // initialize with default, in case no lines are input
  GeometryFactory factory = GeometryFactory.defaultPrecision();
  int lineCount = 0;
  bool isRun = false;
  Geometry? _sequencedGeometry;
  bool _isSequenceable = false;

  Geometry? sequence(Geometry geom) {
    return getSequencedLineStrings();
  }

  /**
   * Tests whether a {@link Geometry} is sequenced correctly.
   * {@link LineString}s are trivially sequenced.
   * {@link MultiLineString}s are checked for correct sequencing.
   * Otherwise, <code>isSequenced</code> is defined
   * to be <code>true</code> for geometries that are not lineal.
   *
   * @param geom the geometry to test
   * @return <code>true</code> if the geometry is sequenced or is not lineal
   */
  bool isSequenced(Geometry geom) {
    if (!(geom is MultiLineString)) {
      return true;
    }

    // the nodes in all subgraphs which have been completely scanned
    Set prevSubgraphNodes = SplayTreeSet();
    Coordinate? lastNode = null;
    List<Coordinate> currNodes = [];
    for (int i = 0; i < geom.getNumGeometries(); i++) {
      LineString line = geom.getGeometryN(i) as LineString;
      Coordinate startNode = line.getCoordinateN(0);
      Coordinate endNode = line.getCoordinateN(line.getNumPoints() - 1);

      /**
       * If this linestring is connected to a previous subgraph, geom is not sequenced
       */
      if (prevSubgraphNodes.contains(startNode)) return false;
      if (prevSubgraphNodes.contains(endNode)) return false;

      if (lastNode != null) {
        if (!startNode.equals(lastNode)) {
          // start new connected sequence
          prevSubgraphNodes.addAll(currNodes);
          currNodes.clear();
        }
      }
      currNodes.add(startNode);
      currNodes.add(endNode);
      lastNode = endNode;
    }
    return true;
  }

  /**
   * Adds a list of {@link Geometry}s to be sequenced.
   * May be called multiple times.
   * Any dimension of Geometry may be added; the constituent linework will be
   * extracted.
   *
   * @param geometries a Collection of geometries to add
   */
  void add(List<Geometry> geometries) {
    for (Iterator i = geometries.iterator; i.moveNext();) {
      Geometry geometry = i.current as Geometry;
      addGeometry(geometry);
    }
  }

  /**
   * Adds a {@link Geometry} to be sequenced.
   * May be called multiple times.
   * Any dimension of Geometry may be added; the constituent linework will be
   * extracted.
   *
   * @param geometry the geometry to add
   */
  void addGeometry(Geometry geometry) {
    List<LineString> lines = [];
    LinearComponentExtracter.getLinesGL(geometry, lines);
    for (LineString line in lines) {
      addLine(line);
    }
  }

  void addLine(LineString lineString) {
    factory = lineString.getFactory();
    // Note API difference here
    graph.addEdgefromLineString(lineString);
    lineCount++;
  }

  /**
   * Tests whether the arrangement of linestrings has a valid
   * sequence.
   *
   * @return <code>true</code> if a valid sequence exists.
   */
  bool isSequenceable() {
    computeSequence();
    return _isSequenceable;
  }

  /**
   * Returns the {@link LineString} or {@link MultiLineString}
   * built by the sequencing process, if one exists.
   *
   * @return the sequenced linestrings,
   * or <code>null</code> if a valid sequence does not exist
   */
  Geometry? getSequencedLineStrings() {
    computeSequence();
    return _sequencedGeometry;
  }

  void computeSequence() {
    if (isRun) {
      return;
    }
    isRun = true;

    List? sequences = findSequences();
    if (sequences == null) return;

    _sequencedGeometry = buildSequencedGeometry(sequences);
    _isSequenceable = true;

    int finalLineCount = _sequencedGeometry!.getNumGeometries();
    assert(lineCount == finalLineCount, "Lines were missing from result");
    assert((_sequencedGeometry is LineString) || (_sequencedGeometry is MultiLineString), "Result is not lineal");
  }

  List? findSequences() {
    List sequences = [];
    ConnectedSubgraphFinder csFinder = ConnectedSubgraphFinder(graph);
    List subgraphs = csFinder.getConnectedSubgraphs();
    for (Iterator i = subgraphs.iterator; i.moveNext();) {
      Subgraph subgraph = i.current() as Subgraph;
      if (hasSequence(subgraph)) {
        List seq = findSequence(subgraph);
        sequences.add(seq);
      } else {
        // if any subgraph cannot be sequenced, abort
        return null;
      }
    }
    return sequences;
  }

  /**
   * Tests whether a complete unique path exists in a graph
   * using Euler's Theorem.
   *
   * @param graph the subgraph containing the edges
   * @return <code>true</code> if a sequence exists
   */
  bool hasSequence(Subgraph graph) {
    int oddDegreeCount = 0;
    for (Iterator i = graph.nodeIterator(); i.moveNext();) {
      Node node = i.current() as Node;
      if (node.getDegree() % 2 == 1) oddDegreeCount++;
    }
    return oddDegreeCount <= 2;
  }

  List<DirectedEdge> findSequence(Subgraph graph) {
    GraphComponent.setVisitedIter(graph.edgeIterator(), false);

    Node? startNode = findLowestDegreeNode(graph);
    Iterator iter = startNode!.getOutEdges()!.iterator();
    iter.moveNext();
    DirectedEdge startDE = iter.current;
    DirectedEdge startDESym = startDE.getSym()!; // Force non-null

    // We use a special kotlin container here to get access to a list iterator
    KtList<DirectedEdge> seq = KtList.from([]);
    KtMutableListIterator lit = seq.listIterator() as KtMutableListIterator;
    addReverseSubpath(startDESym, lit, false);
    while (lit.hasPrevious()) {
      DirectedEdge prev = lit.previous();
      DirectedEdge? unvisitedOutDE = findUnvisitedBestOrientedDE(prev.getFromNode());
      if (unvisitedOutDE != null) {
        addReverseSubpath(unvisitedOutDE.getSym()!, lit, true); // Force non-null
      }
    }

    /**
     * At this point, we have a valid sequence of graph DirectedEdges, but it
     * is not necessarily appropriately oriented relative to the underlying
     * geometry.
     */
    List<DirectedEdge> orientedSeq = orient(seq.asList());
    return orientedSeq;
  }

  /**
   * Finds an {@link DirectedEdge} for an unvisited edge (if any),
   * choosing the dirEdge which preserves orientation, if possible.
   *
   * @param node the node to examine
   * @return the dirEdge found, or <code>null</code> if none were unvisited
   */
  static DirectedEdge? findUnvisitedBestOrientedDE(Node node) {
    DirectedEdge? wellOrientedDE;
    DirectedEdge? unvisitedDE;
    for (Iterator i = node.getOutEdges()!.iterator as Iterator; i.moveNext();) {
      DirectedEdge de = i.current as DirectedEdge;
      if (!de.getEdge()!.isVisited()) {
        unvisitedDE = de;
        if (de.getEdgeDirection()) wellOrientedDE = de;
      }
    }
    if (wellOrientedDE != null) return wellOrientedDE;
    return unvisitedDE;
  }

  void addReverseSubpath(DirectedEdge de, KtMutableListIterator lit, bool expectedClosed) {
    // trace an unvisited path *backwards* from this de
    Node endNode = de.getToNode();

    Node? fromNode;
    while (true) {
      lit.add(de.getSym());
      de.getEdge()!.setVisited(true);
      fromNode = de.getFromNode();
      DirectedEdge? unvisitedOutDE = findUnvisitedBestOrientedDE(fromNode);
      // this must terminate, since we are continually marking edges as visited
      if (unvisitedOutDE == null) break;
      de = unvisitedOutDE.getSym()!;
    }
    if (expectedClosed) {
      // the path should end at the toNode of this de, otherwise we have an error
      assert(fromNode == endNode, "path not contiguous");
    }
  }

  static Node? findLowestDegreeNode(Subgraph graph) {
    // TODO: Use max value when https://github.com/dart-lang/sdk/issues/41717
    // is resolved
    int minDegree = maxInt;
    Node? minDegreeNode;
    for (Iterator i = graph.nodeIterator(); i.moveNext();) {
      Node node = i.current as Node;
      if (minDegreeNode == null || node.getDegree() < minDegree) {
        minDegree = node.getDegree();
        minDegreeNode = node;
      }
    }
    return minDegreeNode;
  }

  /**
   * Computes a version of the sequence which is optimally
   * oriented relative to the underlying geometry.
   * <p>
   * Heuristics used are:
   * <ul>
   * <li>If the path has a degree-1 node which is the start
   * node of an linestring, use that node as the start of the sequence
   * <li>If the path has a degree-1 node which is the end
   * node of an linestring, use that node as the end of the sequence
   * <li>If the sequence has no degree-1 nodes, use any node as the start
   * (NOTE: in this case could orient the sequence according to the majority of the
   * linestring orientations)
   * </ul>
   *
   * @param seq a List of DirectedEdges
   * @return a List of DirectedEdges oriented appropriately
   */
  List<DirectedEdge> orient(List<DirectedEdge> seq) {
    DirectedEdge startEdge = seq[0];
    DirectedEdge endEdge = seq[seq.length - 1];
    Node startNode = startEdge.getFromNode();
    Node endNode = endEdge.getToNode();

    bool flipSeq = false;
    bool hasDegree1Node = startNode.getDegree() == 1 || endNode.getDegree() == 1;

    if (hasDegree1Node) {
      bool hasObviousStartNode = false;

      // test end edge before start edge, to make result stable
      // (ie. if both are good starts, pick the actual start
      if (endEdge.getToNode().getDegree() == 1 && !endEdge.getEdgeDirection()) {
        hasObviousStartNode = true;
        flipSeq = true;
      }
      if (startEdge.getFromNode().getDegree() == 1 && startEdge.getEdgeDirection()) {
        hasObviousStartNode = true;
        flipSeq = false;
      }

      // since there is no obvious start node, use any node of degree 1
      if (!hasObviousStartNode) {
        // check if the start node should actually be the end node
        if (startEdge.getFromNode().getDegree() == 1) flipSeq = true;
        // if the end node is of degree 1, it is properly the end node
      }
    }

    // if there is no degree 1 node, just use the sequence as is
    // (Could insert heuristic of taking direction of majority of lines as overall direction)

    if (flipSeq) return seq.reversed.toList();
    return seq;
  }

  /**
   * Reverse the sequence.
   * This requires reversing the order of the dirEdges, and flipping
   * each dirEdge as well
   *
   * @param seq a List of DirectedEdges, in sequential order
   * @return the reversed sequence
   */
  List<DirectedEdge> reverse(List<DirectedEdge> seq) {
    return seq.reversed.toList();
  }

  /**
   * Builds a geometry ({@link LineString} or {@link MultiLineString} )
   * representing the sequence.
   *
   * @param sequences a List of Lists of DirectedEdges with
   *   LineMergeEdges as their parent edges.
   * @return the sequenced geometry, or <code>null</code> if no sequence exists
   */
  Geometry buildSequencedGeometry(List sequences) {
    List lines = [];

    for (Iterator i1 = sequences.iterator; i1.moveNext();) {
      List seq = i1.current as List;
      for (Iterator i2 = seq.iterator; i2.moveNext();) {
        DirectedEdge de = i2.current as DirectedEdge;
        LineMergeEdge e = de.getEdge() as LineMergeEdge;
        LineString line = e.getLine();

        LineString lineToAdd = line;
        if (!de.getEdgeDirection() && !line.isClosed()) lineToAdd = reverseLineString(line);

        lines.add(lineToAdd);
      }
    }
    if (lines.length == 0) return factory.createMultiLineString([]);
    return factory.buildGeometry(lines as List<Geometry>);
  }

  /**
   * Reverses a LineString by re-ordering its coordinates
   */
  static LineString reverseLineString(LineString line) {
    List<Coordinate> pts = line.getCoordinates();
    List<Coordinate> revPts = pts.reversed.toList();
    return line.getFactory().createLineString(revPts);
  }
}

/**
 * Helper class for linked list in LineSequencer.findSequence
 */
class DirectedEdgeEntryItem extends LinkedListEntry<DirectedEdgeEntryItem> {
  final DirectedEdge edge;
  DirectedEdgeEntryItem(this.edge);
  @override
  String toString() {
    return '$edge';
  }
}












// /**
//  * Merges a collection of linear components to form maximal-length linestrings. 
//  * <p> 
//  * Merging stops at nodes of degree 1 or degree 3 or more.
//  * In other words, all nodes of degree 2 are merged together. 
//  * The exception is in the case of an isolated loop, which only has degree-2 nodes.
//  * In this case one of the nodes is chosen as a starting point.
//  * <p> 
//  * The direction of each
//  * merged LineString will be that of the majority of the LineStrings from which it
//  * was derived.
//  * <p>
//  * Any dimension of Geometry is handled - the constituent linework is extracted to 
//  * form the edges. The edges must be correctly noded; that is, they must only meet
//  * at their endpoints.  The LineMerger will accept non-noded input
//  * but will not merge non-noded edges.
//  * <p>
//  * Input lines which are empty or contain only a single unique coordinate are not included
//  * in the merging.
//  *
//  * @version 1.7
//  */

// class LineMerger {
//   LineMergeGraph graph = LineMergeGraph();
// }

// /**
//  * A planar graph of edges that is analyzed to sew the edges together. The 
//  * <code>marked</code> flag on {@link org.locationtech.jts.planargraph.Edge}s
//  * and {@link org.locationtech.jts.planargraph.Node}s indicates whether they have been
//  * logically deleted from the graph.
//  *
//  * @version 1.7
//  */
// class LineMergeGraph extends PlanarGraph {
//   /**
//    * Adds an Edge, DirectedEdges, and Nodes for the given LineString representation
//    * of an edge. 
//    * Empty lines or lines with all coordinates equal are not added.
//    * 
//    * @param lineString the linestring to add to the graph
//    */
//   void addEdge(LineString lineString) {
//     if (lineString.isEmpty()) {
//       return;
//     }

//     List<Coordinate> coordinates = CoordinateArrays.removeRepeatedPoints(lineString.getCoordinates());

//     // don't add lines with all coordinates equal
//     if (coordinates.length <= 1) {
//       return;
//     }

//     Coordinate startCoordinate = coordinates[0];
//     Coordinate endCoordinate = coordinates[coordinates.length - 1];
//     Node startNode = getNode(startCoordinate);
//     Node endNode = getNode(endCoordinate);
//     DirectedEdge directedEdge0 = LineMergeDirectedEdge(startNode, endNode, coordinates[1], true);
//     DirectedEdge directedEdge1 = LineMergeDirectedEdge(endNode, startNode, coordinates[coordinates.length - 2], false);
//     Edge edge = LineMergeEdge(lineString);
//     edge.setDirectedEdges(directedEdge0, directedEdge1);
//     super.add(edge);
//   }

//   Node getNode(Coordinate coordinate) {
//     // Note that PlanarGraph implements find instead of findNode here
//     Node? node = super.find(coordinate);
//     if (node == null) {
//       node = Node(coordinate, null);
//       // Note PlanarGraph uses addNode instead of add(Node) here
//       super.addNode(node);
//     }
//     return node;
//   }
// }

// /**
//  * An edge of a {@link LineMergeGraph}. The <code>marked</code> field indicates
//  * whether this Edge has been logically deleted from the graph.
//  *
//  * @version 1.7
//  */
// class LineMergeEdge extends Edge {
//   LineString line;

//   /**
//    * Constructs a LineMergeEdge with vertices given by the specified LineString.
//    */
//   LineMergeEdge(LineString line)
//       : this.line = line,
//         super(line.getCoordinates(), /* label = */ null) {}

//   /**
//    * Returns the LineString specifying the vertices of this edge.
//    */
//   LineString getLine() {
//     return this.line;
//   }
// }

// /**
//  * A {@link org.locationtech.jts.planargraph.DirectedEdge} of a 
//  * {@link LineMergeGraph}. 
//  *
//  * @version 1.7
//  */
// class LineMergeDirectedEdge extends DirectedEdge {
//   /**
//    * Constructs a LineMergeDirectedEdge connecting the <code>from</code> node to the
//    * <code>to</code> node.
//    *
//    * @param directionPt
//    *                  specifies this DirectedEdge's direction (given by an imaginary
//    *                  line from the <code>from</code> node to <code>directionPt</code>)
//    * @param edgeDirection
//    *                  whether this DirectedEdge's direction is the same as or
//    *                  opposite to that of the parent Edge (if any)
//    */
//   LineMergeDirectedEdge(Node from, Node to, Coordinate directionPt, bool edgeDirection)
//       : super(from, to, directionPt, edgeDirection) {}
// }
