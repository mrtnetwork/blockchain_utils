// DKLs23 persisted key-share record.
//
// Byte-identical to `blockchain-utils/src/dkls23/codec.rs`:
// `KeyShare = [party,n,t,curve:u32 LE][x:32][pk:33][shares: n*33]`.
// Encoding/decoding lives on [DklsUtils]; this file only holds the record
// type.
import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_curve.dart';

class DklsProtocolShare {
  final int party;
  final int n;
  final int? t;
  final DklsProtocolCurve curve;
  final List<int> x;
  final List<int> pk;
  final List<List<int>> shares;
  DklsProtocolShare({
    required this.party,
    required this.n,
    required this.t,
    required this.curve,
    required List<int> x,
    required List<int> pk,
    required List<List<int>> shares,
  }) : x = List<int>.from(x),
       pk = List<int>.from(pk),
       shares = [for (final s in shares) List<int>.from(s)];
}
