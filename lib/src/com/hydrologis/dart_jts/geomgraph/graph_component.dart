import '../geom/coordinate.dart';
import '../geom/util.dart';
import 'label.dart';

/**
 * A GraphComponent is the parent class for the objects'
 * that form a graph.  Each GraphComponent can carry a
 * Label.
 * @version 1.7
 */
abstract class GraphComponent {
  Label? label;

  /**
   * isInResult indicates if this component has already been included in the result
   */
  bool _isInResult = false;
  bool _isCovered = false;
  bool _isCoveredSet = false;
  bool _isVisited = false;

  GraphComponent() {}

  GraphComponent.fromLabel(this.label);

  Label? getLabel() {
    return label;
  }

  void setLabel(Label label) {
    this.label = label;
  }

  void setInResult(bool isInResult) {
    this._isInResult = isInResult;
  }

  bool isInResult() {
    return _isInResult;
  }

  void setCovered(bool isCovered) {
    this._isCovered = isCovered;
    this._isCoveredSet = true;
  }

  bool isCovered() {
    return _isCovered;
  }

  bool isCoveredSet() {
    return _isCoveredSet;
  }

  bool isVisited() {
    return _isVisited;
  }

  void setVisited(bool isVisited) {
    this._isVisited = isVisited;
  }

  /**
   * @return a coordinate in this component (or null, if there are none)
   */
  Coordinate? getCoordinate();

  /**
   * compute the contribution to an IM for this component
   */
  void computeIM(IntersectionMatrix im);

  /**
   * An isolated component is one that does not intersect or touch any other
   * component.  This is the case if the label has valid locations for
   * only a single Geometry.
   *
   * @return true if this component is isolated
   */
  bool isIsolated();

  /**
   * Update the IM with the contribution for this component.
   * A component only contributes if it has a labelling for both parent geometries
   */
  void updateIM(IntersectionMatrix im) {
//  TODO  Assert.isTrue(label.getGeometryCount() >= 2, "found partial label");
    computeIM(im);
  }
}
