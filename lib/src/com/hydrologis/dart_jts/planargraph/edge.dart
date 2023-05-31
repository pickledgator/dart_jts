import 'directed_edge.dart';
import 'graph_component.dart';
import 'node.dart';

/**
 * Represents an undirected edge of a {@link PlanarGraph}. An undirected edge
 * in fact simply acts as a central point of reference for two opposite
 * {@link DirectedEdge}s.
 * <p>
 * Usually a client using a <code>PlanarGraph</code> will subclass <code>Edge</code>
 * to add its own application-specific data and methods.
 *
 * @version 1.7
 */
class Edge extends GraphComponent {
  /**
   * The two DirectedEdges associated with this Edge.
   * Index 0 is forward, 1 is reverse.
   */
  List<DirectedEdge>? dirEdge;

  /**
   * Constructs an Edge whose DirectedEdges are not yet set. Be sure to call
   * {@link #setDirectedEdges(DirectedEdge, DirectedEdge)}
   */
  Edge() {}

  /**
   * Constructs an Edge initialized with the given DirectedEdges, and for each
   * DirectedEdge: sets the Edge, sets the symmetric DirectedEdge, and adds
   * this Edge to its from-Node.
   */
  Edge.fromDirectedEdges(DirectedEdge de0, DirectedEdge de1) {
    setDirectedEdges(de0, de1);
  }

  /**
   * Initializes this Edge's two DirectedEdges, and for each DirectedEdge: sets the
   * Edge, sets the symmetric DirectedEdge, and adds this Edge to its from-Node.
   */
  void setDirectedEdges(DirectedEdge de0, DirectedEdge de1) {
    dirEdge = List<DirectedEdge>.from([de0, de1]);
    de0.setEdge(this);
    de1.setEdge(this);
    de0.setSym(de1);
    de1.setSym(de0);
    de0.getFromNode().addOutEdge(de0);
    de1.getFromNode().addOutEdge(de1);
  }

  /**
   * Returns one of the DirectedEdges associated with this Edge.
   * @param i 0 or 1.  0 returns the forward directed edge, 1 returns the reverse
   */
  DirectedEdge getDirEdge(int i) {
    return dirEdge![i];
  }

  /**
   * Returns the {@link DirectedEdge} that starts from the given node, or null if the
   * node is not one of the two nodes associated with this Edge.
   */
  DirectedEdge? getDirEdgeFromNode(Node fromNode) {
    if (dirEdge![0].getFromNode() == fromNode) return dirEdge![0];
    if (dirEdge![1].getFromNode() == fromNode) return dirEdge![1];
    // node not found
    // possibly should throw an exception here?
    return null;
  }

  /**
   * If <code>node</code> is one of the two nodes associated with this Edge,
   * returns the other node; otherwise returns null.
   */
  Node? getOppositeNode(Node node) {
    if (dirEdge![0].getFromNode() == node) return dirEdge![0].getToNode();
    if (dirEdge![1].getFromNode() == node) return dirEdge![1].getToNode();
    // node not found
    // possibly should throw an exception here?
    return null;
  }

  /**
   * Removes this edge from its containing graph.
   */
  void remove() {
    this.dirEdge = null;
  }

  /**
   * Tests whether this edge has been removed from its containing graph
   *
   * @return <code>true</code> if this edge is removed
   */
  bool isRemoved() {
    return dirEdge == null;
  }
}
