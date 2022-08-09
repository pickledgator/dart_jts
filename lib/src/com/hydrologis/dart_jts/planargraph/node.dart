import 'dart:collection';
import '../geom/coordinate.dart';
import 'directed_edge.dart';
import 'directed_edge_star.dart';
import 'edge.dart';
import 'graph_component.dart';

/**
 * A node in a {@link PlanarGraph}is a location where 0 or more {@link Edge}s
 * meet. A node is connected to each of its incident Edges via an outgoing
 * DirectedEdge. Some clients using a <code>PlanarGraph</code> may want to
 * subclass <code>Node</code> to add their own application-specific
 * data and methods.
 *
 * @version 1.7
 */
class Node extends GraphComponent {
  /** The location of this Node */
  Coordinate? pt;

  /** The collection of DirectedEdges that leave this Node */
  DirectedEdgeStar? deStar;

  /**
   * Returns all Edges that connect the two nodes (which are assumed to be different).
   */
  static HashSet getEdgesBetween(Node node0, Node node1) {
    List edges0 = DirectedEdge.toEdges(node0.getOutEdges()!.getEdges());
    HashSet commonEdges = HashSet.from(edges0);
    List edges1 = DirectedEdge.toEdges(node1.getOutEdges()!.getEdges());
    commonEdges.retainAll(edges1);
    return commonEdges;
  }

  /**
   * Constructs a Node with the given location.
   */
  Node(Coordinate pt, DirectedEdgeStar? deStar) : this.pt = pt {
    this.deStar = (deStar != null) ? deStar : DirectedEdgeStar();
  }

  /**
   * Returns the location of this Node.
   */
  Coordinate? getCoordinate() {
    return this.pt;
  }

  /**
   * Adds an outgoing DirectedEdge to this Node.
   */
  void addOutEdge(DirectedEdge de) {
    deStar!.add(de);
  }

  /**
   * Returns the collection of DirectedEdges that leave this Node.
   */
  DirectedEdgeStar? getOutEdges() {
    return deStar;
  }

  /**
   * Returns the number of edges around this Node.
   */
  int getDegree() {
    return deStar!.getDegree();
  }

  /**
   * Returns the zero-based index of the given Edge, after sorting in ascending order
   * by angle with the positive x-axis.
   */
  int getIndex(Edge edge) {
    return deStar!.getIndexOfEdge(edge);
  }

  /**
   * Removes a {@link DirectedEdge} incident on this node.
   * Does not change the state of the directed edge.
   */
  void removeDirectedEdge(DirectedEdge de) {
    deStar!.remove(de);
  }

  /**
   * Removes this node from its containing graph.
   */
  void remove() {
    pt = null;
  }

  /**
   * Tests whether this node has been removed from its containing graph
   *
   * @return <code>true</code> if this node is removed
   */
  bool isRemoved() {
    return pt == null;
  }
}
