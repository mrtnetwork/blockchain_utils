import 'package:blockchain_utils/helper/helper.dart';

class FieldElement {
  final List<int> h;
  const FieldElement.uncheck(this.h);
  factory FieldElement() => FieldElement.uncheck(List<int>.filled(10, 0));
  FieldElement clone({bool immutable = false}) {
    return FieldElement.uncheck(h.clone(immutable: immutable));
  }

  factory FieldElement.fromJson(Map<String, dynamic> json) {
    return FieldElement.uncheck(json["h"]);
  }

  Map<String, dynamic> toJson() {
    return {"h": h};
  }

  void fillZero() {
    for (int i = 0; i < 10; i++) {
      h[i] = 0;
    }
  }

  void fillOne() {
    h[0] = 1;
    for (int i = 1; i < 10; i++) {
      h[i] = 0;
    }
  }

  void fill(List<int> other) {
    assert(other.length >= 10);
    for (int i = 0; i < 10; i++) {
      h[i] = other[i];
    }
  }
}

class GroupElementP2 {
  final FieldElement x;
  final FieldElement y;
  final FieldElement z;
  const GroupElementP2.uncheck(
      {required this.x, required this.y, required this.z});
  factory GroupElementP2() => GroupElementP2.uncheck(
      x: FieldElement(), y: FieldElement(), z: FieldElement());

  Map<String, dynamic> toJson() {
    return {
      "x": x.toJson(),
      "y": y.toJson(),
      "z": z.toJson(),
    };
  }

  @override
  String toString() {
    String m = "";
    for (final i in toJson().entries) {
      final ln = List<int>.from(i.value["h"]);
      final sm = ln.fold<int>(0, (c, p) => c + p);
      m += "${i.key}:${i.value["h"]} sum: $sm \n";
    }
    return m;
  }
}

class GroupElementP1P1 {
  final FieldElement x;
  final FieldElement y;
  final FieldElement z;
  final FieldElement t;
  const GroupElementP1P1.uncheck(
      {required this.x, required this.y, required this.z, required this.t});
  factory GroupElementP1P1() => GroupElementP1P1.uncheck(
      x: FieldElement(),
      y: FieldElement(),
      z: FieldElement(),
      t: FieldElement());
  Map<String, dynamic> toJson() {
    return {"x": x.toJson(), "y": y.toJson(), "z": z.toJson(), "t": t.toJson()};
  }

  @override
  String toString() {
    String m = "";
    for (final i in toJson().entries) {
      final ln = List<int>.from(i.value["h"]);
      final sm = ln.fold<int>(0, (c, p) => c + p);
      m += "${i.key}:${i.value["h"]} sum: $sm \n";
    }
    return m;
  }
}

class GroupElementP3 {
  final FieldElement x;
  final FieldElement y;
  final FieldElement z;
  final FieldElement t;
  const GroupElementP3.uncheck(
      {required this.x, required this.y, required this.z, required this.t});
  factory GroupElementP3() => GroupElementP3.uncheck(
      x: FieldElement(),
      y: FieldElement(),
      z: FieldElement(),
      t: FieldElement());
  GroupElementP3 clone({bool immutable = false}) {
    return GroupElementP3.uncheck(
      x: x.clone(immutable: immutable),
      y: y.clone(immutable: immutable),
      z: z.clone(immutable: immutable),
      t: t.clone(immutable: immutable),
    );
  }

  Map<String, dynamic> toJson() {
    return {"x": x.toJson(), "y": y.toJson(), "z": z.toJson(), "t": t.toJson()};
  }

  factory GroupElementP3.fromJson(Map<String, dynamic> json) {
    return GroupElementP3.uncheck(
        x: FieldElement.fromJson(json["x"]),
        y: FieldElement.fromJson(json["y"]),
        z: FieldElement.fromJson(json["z"]),
        t: FieldElement.fromJson(json["t"]));
  }
  @override
  String toString() {
    String m = "";
    for (final i in toJson().entries) {
      final ln = List<int>.from(i.value["h"]);
      final sm = ln.fold<int>(0, (c, p) => c + p);
      m += "${i.key}:${i.value["h"]} sum: $sm \n";
    }
    return m;
  }
}

class GroupElementCached {
  final FieldElement yPlusX;
  final FieldElement yMinusX;
  final FieldElement z;
  final FieldElement t2d;
  const GroupElementCached.uncheck(
      {required this.yPlusX,
      required this.yMinusX,
      required this.z,
      required this.t2d});

  factory GroupElementCached() => GroupElementCached.uncheck(
      yPlusX: FieldElement(),
      yMinusX: FieldElement(),
      z: FieldElement(),
      t2d: FieldElement());

  static List<GroupElementCached> get dsmp {
    return List.generate(8, (_) => GroupElementCached()).immutable;
  }

  Map<String, dynamic> toJson() {
    return {
      "yPlusX": yPlusX.toJson(),
      "yMinusX": yMinusX.toJson(),
      "z": z.toJson(),
      "t2d": t2d.toJson(),
    };
  }

  @override
  String toString() {
    String m = "";
    for (final i in toJson().entries) {
      final ln = List<int>.from(i.value["h"]);
      final sm = ln.fold<int>(0, (c, p) => c + p);
      m += "${i.key}:${i.value["h"]} sum: $sm \n";
    }
    return m;
  }
}

class GroupElementPrecomp {
  final FieldElement yplusx;
  final FieldElement yminusx;
  final FieldElement xy2d;
  const GroupElementPrecomp.uncheck(
      {required this.yplusx, required this.yminusx, required this.xy2d});
  factory GroupElementPrecomp() => GroupElementPrecomp.uncheck(
      yplusx: FieldElement(), yminusx: FieldElement(), xy2d: FieldElement());
  Map<String, dynamic> toJson() {
    return {
      "yplusx": yplusx.toJson(),
      "yminusx": yminusx.toJson(),
      "xy2d": xy2d.toJson()
    };
  }

  @override
  String toString() {
    String m = "";
    for (final i in toJson().entries) {
      m += "${i.key}:${i.value}\n";
    }
    return m;
  }
}

typedef GroupElementDsmp = List<GroupElementCached>;
