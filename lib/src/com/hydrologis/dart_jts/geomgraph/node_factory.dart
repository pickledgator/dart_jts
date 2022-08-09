import '../geom/coordinate.dart';
import 'node.dart';

/**
 * @version 1.7
 */
class NodeFactory {
  /**
   * The basic node constructor does not allow for incident edges
   */
  Node createNode(Coordinate coord) {
    return new Node(coord, null);
  }
}
