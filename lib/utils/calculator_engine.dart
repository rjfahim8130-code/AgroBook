class CalculatorEngine {
  /// ইউজার যে তথ্য দিয়েছে তার ভিত্তিতে সম্ভব হলে বাকি ঘরগুলো পূরণ করে
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

    // ----- ওজন হিসাব -----
    if (q > 0 && wpu > 0) {
      tw = q * wpu;
    } else if (tw > 0 && q > 0 && wpu == 0) {
      wpu = tw / q;
    } else if (tw > 0 && wpu > 0 && q == 0) {
      q = tw / wpu;
    }

    // ----- মোট টাকা হিসাব -----
    if (q > 0 && ppu > 0) {
      ta = q * ppu;
    } else if (tw > 0 && ppw > 0) {
      ta = tw * ppw;
    }

    // ----- রিভার্স রেট -----
    if (ta > 0 && q > 0 && ppu == 0) {
      ppu = ta / q;
    }
    if (ta > 0 && tw > 0 && ppw == 0) {
      ppw = ta / tw;
    }

    // ----- একক দাম ↔ ওজন দাম সম্পর্ক -----
    if (ppu > 0 && wpu > 0 && ppw == 0) {
      ppw = ppu / wpu;
    }
    if (ppw > 0 && wpu > 0 && ppu == 0) {
      ppu = ppw * wpu;
    }

    // চূড়ান্ত মোট টাকা নিশ্চিতকরণ
    if (q > 0 && ppu > 0) {
      ta = q * ppu;
    } else if (tw > 0 && ppw > 0) {
      ta = tw * ppw;
    }

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
