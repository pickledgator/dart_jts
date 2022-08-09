import '../geom/coordinate.dart';
import '../geom/util.dart';
import 'directed_edge.dart';
import 'edge_end.dart';
import 'edge_end_star.dart';
import 'graph_component.dart';
import 'label.dart';

/**
 * @version 1.7
 */
class Node extends GraphComponent {
  Coordinate coord; // only non-null if this node is precise
  EdgeEndStar? edges;

  Node(this.coord, EdgeEndStar? edges) {
    this.edges = edges;
    label = new Label.args2(0, Location.NONE);
  }

  Coordinate getCoordinate() {
    return coord;
  }

  EdgeEndStar? getEdges() {
    return edges;
  }

  /**
   * Tests whether any incident edge is flagged as
   * being in the result.
   * This test can be used to determine if the node is in the result,
   * since if any incident edge is in the result, the node must be in the result as well.
   *
   * @return <code>true</code> if any incident edge in the in the result
   */
  bool isIncidentEdgeInResult() {
    for (Iterator it = getEdges()!.getEdges().iterator; it.moveNext();) {
      DirectedEdge de = it.current;
      if (de.getEdge().isInResult()) return true;
    }
    return false;
  }

  bool isIsolated() {
    return (label!.getGeometryCount() == 1);
  }

  /**
   * Basic nodes do not compute IMs
   */
  void computeIM(IntersectionMatrix im) {}

  /**
   * Add the edge to the list of edges at this node
   */
  void add(EdgeEnd e) {
    // Assert: start pt of e is equal to node point
    edges!.insert(e);
    e.setNode(this);
  }

  void mergeLabelFromNode(Node n) {
    mergeLabel(n.label!);
  }

  /**
   * To merge labels for two nodes,
   * the merged location for each LabelElement is computed.
   * The location for the corresponding node LabelElement is set to the result,
   * as long as the location is non-null.
   */

  void mergeLabel(Label label2) {
    for (int i = 0; i < 2; i++) {
      int loc = computeMergedLocation(label2, i);
      int thisLoc = label!.getLocation(i);
      if (thisLoc == Location.NONE) label!.setLocationWithIndex(i, loc);
    }
  }

  void setLabelWithIndex(int argIndex, int onLocation) {
    if (label == null) {
      label = new Label.args2(argIndex, onLocation);
    } else
      label!.setLocationWithIndex(argIndex, onLocation);
  }

  /**
   * Updates the label of a node to BOUNDARY,
   * obeying the mod-2 boundaryDetermination rule.
   */
  void setLabelBoundary(int argIndex) {
    if (label == null) return;

    // determine the current location for the point (if any)
    int loc = Location.NONE;
    if (label != null) loc = label!.getLocation(argIndex);
    // flip the loc
    int newLoc;
    switch (loc) {
      case Location.BOUNDARY:
        newLoc = Location.INTERIOR;
        break;
      case Location.INTERIOR:
        newLoc = Location.BOUNDARY;
        break;
      default:
        newLoc = Location.BOUNDARY;
        break;
    }
    label!.setLocationWithIndex(argIndex, newLoc);
  }

  /**
   * The location for a given eltIndex for a node will be one
   * of { null, INTERIOR, BOUNDARY }.
   * A node may be on both the boundary and the interior of a geometry;
   * in this case, the rule is that the node is considered to be in the boundary.
   * The merged location is the maximum of the two input values.
   */
  int computeMergedLocation(Label label2, int eltIndex) {
    int loc = Location.NONE;
    loc = label!.getLocation(eltIndex);
    if (!label2.isNull(eltIndex)) {
      int nLoc = label2.getLocation(eltIndex);
      if (loc != Location.BOUNDARY) loc = nLoc;
    }
    return loc;
  }

//   void print(PrintStream out)
//  {
//    out.println("node " + coord + " lbl: " + label);
//  }
}
