import 'dart:collection';
import '../directed_edge.dart';
import '../directed_edge_star.dart';
import '../edge.dart';
import '../graph_component.dart';
import '../node.dart';
import '../planargraph.dart';
import '../subgraph.dart';

/**
 * Finds all connected {@link Subgraph}s of a {@link PlanarGraph}.
 * <p>
 * <b>Note:</b> uses the <code>isVisited</code> flag on the nodes.
 */
class ConnectedSubgraphFinder {
  PlanarGraph graph;

  ConnectedSubgraphFinder(this.graph);

  /**
   * Returns subgraphs that are connected
   *
   * @return A list of connected subgraphs
   */
  List getConnectedSubgraphs() {
    List<Subgraph> subgraphs = [];
    GraphComponent.setVisitedIter(graph.nodeIterator(), false);
    for (Iterator i = graph.edgeIterator(); i.moveNext();) {
      Edge e = i.current as Edge;
      Node node = e.getDirEdge(0).getFromNode();
      if (!node.isVisited()) {
        subgraphs.add(findSubgraph(node));
      }
    }
    return subgraphs;
  }

  /**
   * Returns subgraphs that are connected
   *
   * @param Node The node by which to search for the subgraph
   * 
   * @return The corresponding subgraph
   */
  Subgraph findSubgraph(Node node) {
    Subgraph subgraph = Subgraph(graph);
    addReachable(node, subgraph);
    return subgraph;
  }

  /**
   * Adds all nodes and edges reachable from this node to the subgraph.
   * Uses an explicit stack to avoid a large depth of recursion.
   *
   * @param node a node known to be in the subgraph
   */
  void addReachable(Node startNode, Subgraph subgraph) {
    // Note that we use a ListQueue here instead of a Stack
    // Dart docs indicate this is the most common data structure for Stack operations
    ListQueue<Node> nodeStack = ListQueue<Node>();
    nodeStack.add(startNode);
    while (!nodeStack.isEmpty) {
      Node node = nodeStack.removeLast(); // pop()
      addEdges(node, nodeStack, subgraph);
    }
  }

  /**
   * Adds the argument node and all its out edges to the subgraph.
   * @param node the node to add
   * @param nodeStack the current set of nodes being traversed
   */
  void addEdges(Node node, ListQueue<Node> nodeStack, Subgraph subgraph) {
    node.setVisited(true);
    for (Iterator i = (node.getOutEdges() as DirectedEdgeStar).iterator as Iterator; i.moveNext();) {
      DirectedEdge de = i.current as DirectedEdge;
      subgraph.add(de.getEdge()!);
      Node toNode = de.getToNode();
      if (!toNode.isVisited()) nodeStack.add(toNode); // push()
    }
  }
}
