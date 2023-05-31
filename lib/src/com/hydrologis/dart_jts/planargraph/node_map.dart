import 'dart:collection';
import '../geom/coordinate.dart';
import 'node.dart';

/**
 * A map of {@link Node}s, indexed by the coordinate of the node.
 *
 * @version 1.7
 */
class NodeMap {
  Map<Coordinate, Node> nodeMap = SplayTreeMap<Coordinate, Node>();

  /**
   * Constructs a NodeMap without any Nodes.
   */
  NodeMap() {}

  /**
   * Adds a node to the map, replacing any that is already at that location.
   * @return the added node
   */
  Node add(Node n) {
    Coordinate? c = n.getCoordinate();
    if (c != null) {
      nodeMap[c] = n;
    }
    return n;
  }

  /**
   * Removes the Node at the given location, and returns it (or null if no Node was there).
   */
  Node? remove(Coordinate pt) {
    return nodeMap.remove(pt);
  }

  /**
   * Returns the Node at the given location, or null if no Node was there.
   */
  Node? find(Coordinate coord) {
    return nodeMap[coord];
  }

  /**
   * Returns an Iterator over the Nodes in this NodeMap, sorted in ascending order
   * by angle with the positive x-axis.
   */
  Iterator iterator() {
    return nodeMap.values.iterator;
  }

  /**
   * Returns the Nodes in this NodeMap, sorted in ascending order
   * by angle with the positive x-axis.
   */
  List<Node> values() {
    return List<Node>.from(nodeMap.values);
  }
}
