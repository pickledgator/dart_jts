import '../geom/coordinate.dart';
import 'directed_edge.dart';
import 'edge.dart';
import 'node.dart';
import 'node_map.dart';

/**
 * Represents a directed graph which is embeddable in a planar surface.
 * <p>
 * This class and the other classes in this package serve as a framework for
 * building planar graphs for specific algorithms. This class must be
 * subclassed to expose appropriate methods to construct the graph. This allows
 * controlling the types of graph components ({@link DirectedEdge}s,
 * {@link Edge}s and {@link Node}s) which can be added to the graph. An
 * application which uses the graph framework will almost always provide
 * subclasses for one or more graph components, which hold application-specific
 * data and graph algorithms.
 *
 * @version 1.7
 */
abstract class PlanarGraph {
  Set<Edge> edges = {};
  Set<DirectedEdge> dirEdges = {};
  NodeMap nodeMap = NodeMap();

  /**
   * Constructs a empty graph.
   */
  PlanarGraph() {}

  /**
   * Returns the {@link Node} at the given location,
   * or null if no {@link Node} was there.
   *
   * @param pt the location to query
   * @return the node found
   * or <code>null</code> if this graph contains no node at the location
   */
  Node? findNode(Coordinate pt) {
    return nodeMap.find(pt);
  }

  /**
   * Adds a node to the map, replacing any that is already at that location.
   * Only subclasses can add Nodes, to ensure Nodes are of the right type.
   * 
   * @param node the node to add
   */
  void addNode(Node node) {
    nodeMap.add(node);
  }

  /**
   * Adds the Edge and its DirectedEdges with this PlanarGraph.
   * Assumes that the Edge has already been created with its associated DirectEdges.
   * Only subclasses can add Edges, to ensure the edges added are of the right class.
   */
  void addEdge(Edge edge) {
    edges.add(edge);
    addDirectedEdge(edge.getDirEdge(0));
    addDirectedEdge(edge.getDirEdge(1));
  }

  /**
   * Adds the Edge to this PlanarGraph; only subclasses can add DirectedEdges,
   * to ensure the edges added are of the right class.
   */
  void addDirectedEdge(DirectedEdge dirEdge) {
    dirEdges.add(dirEdge);
  }

  /**
   * Returns an Iterator over the Nodes in this PlanarGraph.
   */
  Iterator nodeIterator() {
    return nodeMap.iterator();
  }

  /**
   * Tests whether this graph contains the given {@link Edge}
   *
   * @param e the edge to query
   * @return <code>true</code> if the graph contains the edge
   */
  bool containsEdge(Edge e) {
    return edges.contains(e);
  }

  /**
   * Tests whether this graph contains the given {@link DirectedEdge}
   *
   * @param de the directed edge to query
   * @return <code>true</code> if the graph contains the directed edge
   */
  bool containsDirectedEdge(DirectedEdge de) {
    return dirEdges.contains(de);
  }

  /**
   * Returns the Nodes in this PlanarGraph.
   */
  List<Node> getNodes() {
    return nodeMap.values();
  }

  /**
   * Returns an Iterator over the DirectedEdges in this PlanarGraph, in the order in which they
   * were added.
   *
   * @see #add(Edge)
   * @see #add(DirectedEdge)
   */
  Iterator dirEdgeIterator() {
    return dirEdges.iterator;
  }

  /**
   * Returns an Iterator over the Edges in this PlanarGraph, in the order in which they
   * were added.
   *
   * @see #add(Edge)
   */
  Iterator edgeIterator() {
    return edges.iterator;
  }

  /**
   * Returns the Edges that have been added to this PlanarGraph
   * @see #add(Edge)
   */
  Set<Edge> getEdges() {
    return edges;
  }

  /**
   * Removes an {@link Edge} and its associated {@link DirectedEdge}s
   * from their from-Nodes and from the graph.
   * Note: This method does not remove the {@link Node}s associated
   * with the {@link Edge}, even if the removal of the {@link Edge}
   * reduces the degree of a {@link Node} to zero.
   */
  void removeEdge(Edge edge) {
    removeDirectedEdge(edge.getDirEdge(0));
    removeDirectedEdge(edge.getDirEdge(1));
    edges.remove(edge);
    edge.remove();
  }

  /**
   * Removes a {@link DirectedEdge} from its from-{@link Node} and from this graph.
   * This method does not remove the {@link Node}s associated with the DirectedEdge,
   * even if the removal of the DirectedEdge reduces the degree of a Node to zero.
   */
  void removeDirectedEdge(DirectedEdge de) {
    DirectedEdge? sym = de.getSym();
    if (sym != null) sym.setSym(null);
    de.getFromNode().removeDirectedEdge(de);
    de.remove();
    dirEdges.remove(de);
  }

  /**
   * Removes a node from the graph, along with any associated DirectedEdges and
   * Edges.
   */
  void removeNode(Node node) {
    // unhook all directed edges
    List outEdges = node.getOutEdges()!.getEdges();
    for (Iterator i = outEdges.iterator; i.moveNext();) {
      DirectedEdge de = i.current as DirectedEdge;
      DirectedEdge? sym = de.getSym();
      // remove the diredge that points to this node
      if (sym != null) removeDirectedEdge(sym);
      // remove this diredge from the graph collection
      dirEdges.remove(de);

      Edge? edge = de.getEdge();
      if (edge != null) {
        edges.remove(edge);
      }
    }
    // remove the node from the graph
    nodeMap.remove(node.getCoordinate()!);
    node.remove();
  }

  /**
   * Returns all Nodes with the given number of Edges around it.
   */
  List<Node> findNodesOfDegree(int degree) {
    List<Node> nodesFound = [];
    for (Iterator i = nodeIterator(); i.moveNext();) {
      Node node = i.current as Node;
      if (node.getDegree() == degree) nodesFound.add(node);
    }
    return nodesFound;
  }
}
