import '../geom/coordinate.dart';

/**
 * Represents a point on an
 * edge which intersects with another edge.
 * <p>
 * The intersection may either be a single point, or a line segment
 * (in which case this point is the start of the line segment)
 * The intersection point must be precise.
 *
 * @version 1.7
 */
class EdgeIntersection implements Comparable {
  late Coordinate coord; // the point of intersection
  int segmentIndex; // the index of the containing line segment in the parent edge
  double dist; // the edge distance of this point along the containing line segment

  EdgeIntersection(Coordinate coord, this.segmentIndex, this.dist) {
    this.coord = new Coordinate.fromCoordinate(coord);
  }

  Coordinate getCoordinate() {
    return coord;
  }

  int getSegmentIndex() {
    return segmentIndex;
  }

  double getDistance() {
    return dist;
  }

  int compareTo(dynamic obj) {
    EdgeIntersection other = obj as EdgeIntersection;
    return compare(other.segmentIndex, other.dist);
  }

  /**
   * @return -1 this EdgeIntersection is located before the argument location
   * @return 0 this EdgeIntersection is at the argument location
   * @return 1 this EdgeIntersection is located after the argument location
   */
  int compare(int segmentIndex, double dist) {
    if (this.segmentIndex < segmentIndex) return -1;
    if (this.segmentIndex > segmentIndex) return 1;
    if (this.dist < dist) return -1;
    if (this.dist > dist) return 1;
    return 0;
  }

  bool isEndPoint(int maxSegmentIndex) {
    if (segmentIndex == 0 && dist == 0.0) return true;
    if (segmentIndex == maxSegmentIndex) return true;
    return false;
  }

//   void print(PrintStream out)
//  {
//    out.print(coord);
//    out.print(" seg # = " + segmentIndex);
//    out.println(" dist = " + dist);
//  }
  String toString() {
    return "$coord seg # = $segmentIndex dist = $dist";
  }
}
