import 'dart:collection';
import '../geom/coordinate.dart';
import '../geom/util.dart';
import 'edge_end.dart';
import 'node.dart';
import 'node_factory.dart';

/**
 * A map of nodes, indexed by the coordinate of the node
 * @version 1.7
 */
class NodeMap {
  //Map nodeMap = new HashMap();
  Map<Coordinate, Node?> nodeMap = new SplayTreeMap();
  NodeFactory nodeFact;

  NodeMap(this.nodeFact);

  /**
   * Factory function - subclasses can override to create their own types of nodes
   */
  /*
   Node createNode(Coordinate coord)
  {
    return new Node(coord);
  }
  */
  /**
   * This method expects that a node has a coordinate value.
   */
  Node addNodeFromCoordinate(Coordinate coord) {
    Node? node = nodeMap[coord];
    if (node == null) {
      node = nodeFact.createNode(coord);
      nodeMap[coord] = node;
    }
    return node;
  }

  Node addNode(Node n) {
    Node? node = nodeMap[n.getCoordinate()];
    if (node == null) {
      nodeMap[n.getCoordinate()] = n;
      return n;
    }
    node.mergeLabelFromNode(n);
    return node;
  }

  /**
   * Adds a node for the start point of this EdgeEnd
   * (if one does not already exist in this map).
   * Adds the EdgeEnd to the (possibly new) node.
   */
  void add(EdgeEnd e) {
    Coordinate p = e.getCoordinate()!;
    Node n = addNodeFromCoordinate(p);
    n.add(e);
  }

  /**
   * @return the node if found; null otherwise
   */
  Node? find(Coordinate coord) {
    return nodeMap[coord];
  }

  Iterator iterator() {
    return nodeMap.values.iterator;
  }

  List values() {
    return List.from(nodeMap.values);
  }

  List getBoundaryNodes(int geomIndex) {
    List bdyNodes = [];
    for (Iterator i = iterator(); i.moveNext();) {
      Node node = i.current;
      if (node.getLabel()!.getLocation(geomIndex) == Location.BOUNDARY) bdyNodes.add(node);
    }
    return bdyNodes;
  }

//   void print(PrintStream out)
//  {
//    for (Iterator it = iterator(); it.hasNext(); )
//    {
//      Node n = (Node) it.next();
//      n.print(out);
//    }
//  }
}
