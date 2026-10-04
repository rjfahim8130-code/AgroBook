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

    // ১. যদি সংখ্যা (Quantity) এবং প্রতিটার ওজন (Weight per unit) থাকে, তবে মোট ওজন বের করা সম্ভব
    if (q > 0 && wpu > 0 && tw == 0) {
      tw = q * wpu;
    }

    // ২. যদি মোট ওজন এবং সংখ্যা থাকে, তবে প্রতিটার ওজন বের করা সম্ভব
    if (tw > 0 && q > 0 && wpu == 0) {
      wpu = tw / q;
    }

    // ৩. যদি মোট ওজন এবং প্রতিটার ওজন থাকে, তবে সংখ্যা বের করা সম্ভব
    if (tw > 0 && wpu > 0 && q == 0) {
      q = tw / wpu;
    }

    // ৪. যদি সংখ্যা এবং প্রতি সংখ্যার দাম থাকে, তবে মোট দাম বের করা সম্ভব
    if (q > 0 && ppu > 0 && ta == 0) {
      ta = q * ppu;
    }

    // ৫. যদি মোট ওজন এবং প্রতি ওজনের দাম থাকে, তবে মোট দাম বের করা সম্ভব
    if (tw > 0 && ppw > 0 && ta == 0) {
      ta = tw * ppw;
    }

    // ৬. যদি মোট দাম এবং সংখ্যা থাকে, তবে প্রতি সংখ্যার দাম বের করা সম্ভব
    if (ta > 0 && q > 0 && ppu == 0) {
      ppu = ta / q;
    }

    // ৭. যদি মোট দাম এবং মোট ওজন থাকে, তবে প্রতি ওজনের দাম বের করা সম্ভব
    if (ta > 0 && tw > 0 && ppw == 0) {
      ppw = ta / tw;
    }

    // ৮. যদি প্রতি সংখ্যার দাম এবং প্রতিটার ওজন জানা থাকে, তবে প্রতি ওজনের দাম বের করা সম্ভব
    if (ppu > 0 && wpu > 0 && ppw == 0) {
      ppw = ppu / wpu;
    }

    // ৯. যদি প্রতি ওজনের দাম এবং প্রতিটার ওজন জানা থাকে, তবে প্রতি সংখ্যার দাম বের করা সম্ভব
    if (ppw > 0 && wpu > 0 && ppu == 0) {
      ppu = ppw * wpu;
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
