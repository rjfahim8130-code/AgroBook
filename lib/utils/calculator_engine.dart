class CalculatorEngine {
  static Map<String, double> calculateMissingValues({
    required double quantity,
    required double weightPerUnit,
    required double totalWeight,
    required double pricePerUnit,
    required double pricePerWeight,
    required double totalAmount,
  }) {
    double q = quantity;
    double wpu = weightPerUnit;
    double tw = totalWeight;
    double ppu = pricePerUnit;
    double ppw = pricePerWeight;
    double ta = totalAmount;

    // ওজনের স্বয়ংক্রিয় হিসাব
    if (q > 0 && wpu > 0 && tw == 0) tw = q * wpu;
    if (tw > 0 && q > 0 && wpu == 0) wpu = tw / q;
    if (tw > 0 && wpu > 0 && q == 0) q = tw / wpu;

    // মোট টাকার স্বয়ংক্রিয় হিসাব
    if (q > 0 && ppu > 0 && ta == 0) ta = q * ppu;
    if (tw > 0 && ppw > 0 && ta == 0) ta = tw * ppw;

    // রিভার্স রেট হিসাব (যদি মোট টাকা সরাসরি দেওয়া থাকে)
    if (ta > 0 && q > 0 && ppu == 0) ppu = ta / q;
    if (ta > 0 && tw > 0 && ppw == 0) ppw = ta / tw;
    if (ppu > 0 && wpu > 0 && ppw == 0) ppw = ppu / wpu;
    if (ppw > 0 && wpu > 0 && ppu == 0) ppu = ppw * wpu;

    return {
      'quantity': q,
      'weightPerUnit': wpu,
      'totalWeight': tw,
      'pricePerUnit': ppu,
      'pricePerWeight': ppw,
      'totalAmount': ta,
    };
  }
}
