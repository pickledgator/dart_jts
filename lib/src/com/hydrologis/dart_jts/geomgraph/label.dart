import '../geom/util.dart';
import '../geom/position.dart';
import 'topology_location.dart';

/**
 * A <code>Label</code> indicates the topological relationship of a component
 * of a topology graph to a given <code>Geometry</code>.
 * This class supports labels for relationships to two <code>Geometry</code>s,
 * which is sufficient for algorithms for binary operations.
 * <P>
 * Topology graphs support the concept of labeling nodes and edges in the graph.
 * The label of a node or edge specifies its topological relationship to one or
 * more geometries.  (In fact, since JTS operations have only two arguments labels
 * are required for only two geometries).  A label for a node or edge has one or
 * two elements, depending on whether the node or edge occurs in one or both of the
 * input <code>Geometry</code>s.  Elements contain attributes which categorize the
 * topological location of the node or edge relative to the parent
 * <code>Geometry</code>; that is, whether the node or edge is in the interior,
 * boundary or exterior of the <code>Geometry</code>.  Attributes have a value
 * from the set <code>{Interior, Boundary, Exterior}</code>.  In a node each
 * element has  a single attribute <code>&lt;On&gt;</code>.  For an edge each element has a
 * triplet of attributes <code>&lt;Left, On, Right&gt;</code>.
 * <P>
 * It is up to the client code to associate the 0 and 1 <code>TopologyLocation</code>s
 * with specific geometries.
 * @version 1.7
 *
 */
class Label {
  // converts a Label to a Line label (that is, one with no side Locations)
  static Label toLineLabel(Label label) {
    Label lineLabel = new Label(Location.NONE);
    for (int i = 0; i < 2; i++) {
      lineLabel.setLocationWithIndex(i, label.getLocation(i));
    }
    return lineLabel;
  }

  List<TopologyLocation?> elt = []..length = (2);

  /**
   * Construct a Label with a single location for both Geometries.
   * Initialize the locations to Null
   */
  Label(int onLoc) {
    elt[0] = new TopologyLocation.fromOn(onLoc);
    elt[1] = new TopologyLocation.fromOn(onLoc);
  }

  /**
   * Construct a Label with a single location for both Geometries.
   * Initialize the location for the Geometry index.
   */
  Label.args2(int geomIndex, int onLoc) {
    elt[0] = new TopologyLocation.fromOn(Location.NONE);
    elt[1] = new TopologyLocation.fromOn(Location.NONE);
    elt[geomIndex]!.setLocation(onLoc);
  }

  /**
   * Construct a Label with On, Left and Right locations for both Geometries.
   * Initialize the locations for both Geometries to the given values.
   */
  Label.args3(int onLoc, int leftLoc, int rightLoc) {
    elt[0] = new TopologyLocation(onLoc, leftLoc, rightLoc);
    elt[1] = new TopologyLocation(onLoc, leftLoc, rightLoc);
  }

  /**
   * Construct a Label with On, Left and Right locations for both Geometries.
   * Initialize the locations for the given Geometry index.
   */
  Label.args4(int geomIndex, int onLoc, int leftLoc, int rightLoc) {
    elt[0] = new TopologyLocation(Location.NONE, Location.NONE, Location.NONE);
    elt[1] = new TopologyLocation(Location.NONE, Location.NONE, Location.NONE);
    elt[geomIndex]!.setLocations(onLoc, leftLoc, rightLoc);
  }

  /**
   * Construct a Label with the same values as the argument Label.
   */
  Label.fromLabel(Label lbl) {
    elt[0] = new TopologyLocation.fromTL(lbl.elt[0]!);
    elt[1] = new TopologyLocation.fromTL(lbl.elt[1]!);
  }

  void flip() {
    elt[0]!.flip();
    elt[1]!.flip();
  }

  int getLocationWithPosIndex(int geomIndex, int posIndex) {
    return elt[geomIndex]!.get(posIndex);
  }

  int getLocation(int geomIndex) {
    return elt[geomIndex]!.get(Position.ON);
  }

  void setLocation(int geomIndex, int posIndex, int location) {
    elt[geomIndex]!.setLocationWithIndex(posIndex, location);
  }

  void setLocationWithIndex(int geomIndex, int location) {
    elt[geomIndex]!.setLocationWithIndex(Position.ON, location);
  }

  void setAllLocations(int geomIndex, int location) {
    elt[geomIndex]!.setAllLocations(location);
  }

  void setAllLocationsIfNullWithIndex(int geomIndex, int location) {
    elt[geomIndex]!.setAllLocationsIfNull(location);
  }

  void setAllLocationsIfNull(int location) {
    setAllLocationsIfNullWithIndex(0, location);
    setAllLocationsIfNullWithIndex(1, location);
  }

  /**
   * Merge this label with another one.
   * Merging updates any null attributes of this label with the attributes from lbl
   */
  void merge(Label lbl) {
    for (int i = 0; i < 2; i++) {
      if (elt[i] == null && lbl.elt[i] != null) {
        elt[i] = new TopologyLocation.fromTL(lbl.elt[i]!);
      } else {
        elt[i]!.merge(lbl.elt[i]!);
      }
    }
  }

  int getGeometryCount() {
    int count = 0;
    if (!elt[0]!.isNull()) count++;
    if (!elt[1]!.isNull()) count++;
    return count;
  }

  bool isNull(int geomIndex) {
    return elt[geomIndex]!.isNull();
  }

  bool isAnyNull(int geomIndex) {
    return elt[geomIndex]!.isAnyNull();
  }

  bool isArea() {
    return elt[0]!.isArea() || elt[1]!.isArea();
  }

  bool isAreaWithIndex(int geomIndex) {
    /*  Testing
  	if (elt[0].getLocations().length != elt[1].getLocations().length) {
  		System.out.println(this);
  	}
  		*/
    return elt[geomIndex]!.isArea();
  }

  bool isLine(int geomIndex) {
    return elt[geomIndex]!.isLine();
  }

  bool isEqualOnSide(Label lbl, int side) {
    return this.elt[0]!.isEqualOnSide(lbl.elt[0]!, side) && this.elt[1]!.isEqualOnSide(lbl.elt[1]!, side);
  }

  bool allPositionsEqual(int geomIndex, int loc) {
    return elt[geomIndex]!.allPositionsEqual(loc);
  }

  /**
   * Converts one GeometryLocation to a Line location
   */
  void toLine(int geomIndex) {
    if (elt[geomIndex]!.isArea()) elt[geomIndex] = new TopologyLocation.fromOn(elt[geomIndex]!.location[0]);
  }

  String toString() {
    StringBuffer buf = new StringBuffer();
    if (elt[0] != null) {
      buf.write("A:");
      buf.write(elt[0].toString());
    }
    if (elt[1] != null) {
      buf.write(" B:");
      buf.write(elt[1].toString());
    }
    return buf.toString();
  }
}