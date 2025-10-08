import 'dart:ui';

class CanvasElement {
  final String id;
  final String title;
  final String value;
  Offset position;
  double rotation;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final Color color;
  bool isHidden;

  CanvasElement({
    required this.id,
    required this.title,
    required this.value,
    required this.position,
    required this.rotation,
    required this.fontSize,
    this.fontWeight = FontWeight.w900,
    this.letterSpacing = 2,
    required this.color,
    this.isHidden = false,
  });

  CanvasElement copyWith({
    Offset? position,
    double? rotation,
    bool? isHidden,
  }) {
    return CanvasElement(
      id: id,
      title: title,
      value: value,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      color: color,
      isHidden: isHidden ?? this.isHidden,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'value': value,
        'x': position.dx,
        'y': position.dy,
        'rotation': rotation,
        'fontSize': fontSize,
        'fontWeight': fontWeight.index,
        'letterSpacing': letterSpacing,
        'color': color.value,
        'isHidden': isHidden,
      };

  factory CanvasElement.fromJson(Map<String, dynamic> json) {
    return CanvasElement(
      id: json['id'],
      title: json['title'],
      value: json['value'],
      position: Offset(json['x'], json['y']),
      rotation: json['rotation'],
      fontSize: json['fontSize'],
      fontWeight: FontWeight.values[json['fontWeight'] ?? 8],
      letterSpacing: json['letterSpacing'] ?? 2,
      color: Color(json['color']),
      isHidden: json['isHidden'] ?? false,
    );
  }
}
