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

    // ২ বার লুপ চালানো হচ্ছে যেন ১টি মান বের হওয়ার পর পরবর্তী নির্ভরশীল মানগুলোও অটোমেটিক হিসাব হয়ে যায়
    for (int i = 0; i < 2; i++) {
      // ১. ওজন হিসাব
      if (q > 0 && wpu > 0 && tw <= 0) {
        tw = q * wpu;
      } else if (tw > 0 && q > 0 && wpu <= 0) {
        wpu = tw / q;
      } else if (tw > 0 && wpu > 0 && q <= 0) {
        q = tw / wpu;
      }

      // ২. মোট টাকা হিসাব
      if (ta <= 0) {
        if (q > 0 && ppu > 0) {
          ta = q * ppu;
        } else if (tw > 0 && ppw > 0) {
          ta = tw * ppw;
        }
      }

      // ৩. রিভার্স রেট (মোট টাকা থেকে)
      if (ta > 0) {
        if (q > 0 && ppu <= 0) {
          ppu = ta / q;
        }
        if (tw > 0 && ppw <= 0) {
          ppw = ta / tw;
        }
        if (ppu > 0 && q <= 0) {
          q = ta / ppu;
        }
        if (ppw > 0 && tw <= 0) {
          tw = ta / ppw;
        }
      }

      // ৪. একক দাম ↔ ওজন দাম সম্পর্ক
      if (wpu > 0) {
        if (ppu > 0 && ppw <= 0) {
          ppw = ppu / wpu;
        } else if (ppw > 0 && ppu <= 0) {
          ppu = ppw * wpu;
        }
      }
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
