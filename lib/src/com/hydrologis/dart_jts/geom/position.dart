/**
 * A Position indicates the position of a Location relative to a graph component
 * (Node, Edge, or Area).
 * @version 1.7
 */
class Position {
  /** An indicator that a Location is <i>on</i> a GraphComponent */
  static final int ON = 0;

  /** An indicator that a Location is to the <i>left</i> of a GraphComponent */
  static final int LEFT = 1;

  /** An indicator that a Location is to the <i>right</i> of a GraphComponent */
  static final int RIGHT = 2;

  /**
   * Returns LEFT if the position is RIGHT, RIGHT if the position is LEFT, or the position
   * otherwise.
   */
  static int opposite(int position) {
    if (position == LEFT) return RIGHT;
    if (position == RIGHT) return LEFT;
    return position;
  }
}
