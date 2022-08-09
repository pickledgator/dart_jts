abstract class GraphComponent {
  bool _isMarked = false;
  bool _isVisited = false;
  Object? _data = null;

  /**
   * Sets the Visited state for all {@link GraphComponent}s in an {@link Iterator}
   *
   * @param i the Iterator to scan
   * @param visited the state to set the visited flag to
   */
  static void setVisitedIter(Iterator i, bool visited) {
    while (i.moveNext()) {
      GraphComponent comp = i.current as GraphComponent;
      comp.setVisited(visited);
    }
  }

  /**
   * Sets the Marked state for all {@link GraphComponent}s in an {@link Iterator}
   *
   * @param i the Iterator to scan
   * @param marked the state to set the Marked flag to
   */
  static void setMarkedIter(Iterator i, bool marked) {
    while (i.moveNext()) {
      GraphComponent comp = i.current as GraphComponent;
      comp.setMarked(marked);
    }
  }

  /**
   * Finds the first {@link GraphComponent} in a {@link Iterator} set
   * which has the specified visited state.
   *
   * @param i an Iterator of GraphComponents
   * @param visitedState the visited state to test
   * @return the first component found, or <code>null</code> if none found
   */
  static GraphComponent? getComponentWithVisitedState(Iterator i, bool visitedState) {
    while (i.moveNext()) {
      GraphComponent comp = i.current as GraphComponent;
      if (comp.isVisited() == visitedState) {
        return comp;
      }
    }
    return null;
  }

  GraphComponent() {}

  /**
   * Tests if a component has been visited during the course of a graph algorithm
   * @return <code>true</code> if the component has been visited
   */
  bool isVisited() {
    return _isVisited;
  }

  /**
   * Sets the visited flag for this component.
   * @param isVisited the desired value of the visited flag
   */
  void setVisited(bool isVisited) {
    _isVisited = isVisited;
  }

  /**
   * Tests if a component has been marked at some point during the processing
   * involving this graph.
   * @return <code>true</code> if the component has been marked
   */
  bool isMarked() {
    return _isMarked;
  }

  /**
   * Sets the marked flag for this component.
   * @param isMarked the desired value of the marked flag
   */
  void setMarked(bool isMarked) {
    _isMarked = isMarked;
  }

  /**
   * Sets the user-defined data for this component.
   *
   * @param data an Object containing user-defined data
   */
  void setContext(Object data) {
    _data = data;
  }

  /**
   * Gets the user-defined data for this component.
   *
   * @return the user-defined data
   */
  Object? getContext() {
    return _data;
  }

  /**
   * Sets the user-defined data for this component.
   *
   * @param data an Object containing user-defined data
   */
  void setData(Object? data) {
    _data = data;
  }

  /**
   * Gets the user-defined data for this component.
   *
   * @return the user-defined data
   */
  Object? getData() {
    return _data;
  }

  /**
   * Tests whether this component has been removed from its containing graph
   *
   * @return <code>true</code> if this component is removed
   */
  bool isRemoved();
}
