"""Kaggriculture market price model, transcribed from the competition README.

price(inv) = base + sign * amp * f(|inv - I0|)
  sign = +1 if inv < I0 (scarcity), -1 if inv > I0 (glut)
  amp  = target * base / f(T)
Floored at $1, rounded to nearest dollar.
"""
import math

PARAMS = {
    # base,  I0,     T,   below_func, below_t, above_func, above_t
    "WHEAT":      (25, 10000, 400, "sqrt", 0.80, "log",    0.20),
    "CARROT":     (35, 10000, 450, "hinge", 1.00, "sqrt",  0.70),
    "TOMATO":     (60, 10000, 200, "hinge", 0.40, "sqrt",  0.60),
    "STRAWBERRY": (120, 10000, 100, "sqrt", 0.70, "linear", 1.60),
    "MELON":      (250, 10000, 300, "log",  0.20, "sq",     3.60),
    "EGG":        (50, 10000, 332, "hinge", 0.40, "log",    0.20),
    "MILK":       (160, 10000, 122, "sqrt", 0.60, "linear", 1.60),
    "WOOL":       (200, 10000, 105, "log",  0.20, "sq",     3.20),
    "FERTILIZER": (100, 10000, 200, "linear", 0.40, "linear", 0.40),
}


def _f(name, x, T):
    if name == "linear":
        return x / T
    if name == "sq":
        return (x / T) ** 2
    if name == "sqrt":
        return math.sqrt(x / T)
    if name == "log":
        return math.log(1 + x) / math.log(1 + T)
    if name == "log10":
        return math.log10(1 + x) / math.log10(1 + T)
    if name == "hinge":
        u = x / T
        return u + 8 * max(0.0, u - 1) ** 2
    raise ValueError(name)


def price(product, inv):
    base, I0, T, bf, bt, af, at = PARAMS[product]
    x = abs(inv - I0)
    if inv < I0:
        p = base + bt * base * _f(bf, x, T)
    else:
        p = base - at * base * _f(af, x, T)
    return max(1, round(p))


def revenue_curve(product, qty, inv0=10000):
    """Total revenue from dumping `qty` units starting at market inventory inv0."""
    total, inv = 0, inv0
    for _ in range(qty):
        p = price(product, inv)
        total += p
        if p > 1:
            inv += 1
    return total


if __name__ == "__main__":
    for prod in PARAMS:
        row = [f"{prod:11s}"]
        for q in (50, 100, 200, 400, 800, 1600):
            row.append(f"q={q}: ${revenue_curve(prod, q):7d} (last ${price(prod, 10000 + q):4d})")
        print("  ".join(row))
