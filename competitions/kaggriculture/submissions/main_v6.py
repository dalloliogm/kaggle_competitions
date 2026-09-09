"""Kaggriculture agent: price-driven crop rotation plus a small fertilizer herd.

What the market actually rewards (measured, not assumed):

* Every animal drops one fertilizer a day whether or not it was fed, and the
  first ~400 units of fertilizer are worth ~$24k.  A small herd (about eight
  geese plus two cows and two sheep) collects most of that pool; a larger one
  just buys wheat at a price its eggs cannot repay.
* Eggs are the worst thing a farm hand can spend a turn on.  Feeding a goose
  daily costs a wheat -- and importing wheat at scale walks its price from $25
  to $65, because the town's bakeries are draining the same supply.
* The town keeps consuming carrot, tomato, strawberry, milk and wheat all
  season while nobody produces them, and those resources sit on steep scarcity
  curves (carrot and tomato are `hinge`), so their prices climb to several
  times base.  Melon starts as the best crop at $250 and crashes once ~150 have
  been sold.  So the crop mix is chosen from live prices every turn rather than
  fixed in advance: each free tile goes to whichever crop has the highest
  (marginal revenue - seed) / days-occupied, valued *after* the units already
  in the ground will have hit the market.

Everything else follows from labour being cheap (a hand costs fib(n) and the
count resets daily) and land being cheap relative to what a tile earns.

The scheduler is greedy over dollar values: each turn it enumerates the jobs the
farm needs, scores every (unit, job) pair as `value - distance * action_value`,
and assigns highest-first, with a small bonus for keeping last turn's target so
units do not oscillate between two equally attractive jobs.
"""

import json
import math
import os

CROPS = {
    "WHEAT": {"seed": 10, "first_yield_day": 2, "max_yield_day": 4, "interval": 0, "max_yield": 6, "ongoing": False},
    "CARROT": {"seed": 20, "first_yield_day": 2, "max_yield_day": 3, "interval": 0, "max_yield": 4, "ongoing": False},
    "TOMATO": {"seed": 50, "first_yield_day": 8, "max_yield_day": 8, "interval": 1, "max_yield": 4, "ongoing": True},
    "STRAWBERRY": {"seed": 100, "first_yield_day": 10, "max_yield_day": 10, "interval": 2, "max_yield": 4, "ongoing": True},
    "MELON": {"seed": 80, "first_yield_day": 10, "max_yield_day": 12, "interval": 0, "max_yield": 6, "ongoing": False},
}

ANIMALS = {
    "GOOSE": {"cost": 300, "structure": "COOP", "first_yield_day": 4, "interval": 1, "max_held": 4, "product": "EGG"},
    "COW": {"cost": 400, "structure": "PASTURE", "first_yield_day": 8, "interval": 2, "max_held": 6, "product": "MILK"},
    "SHEEP": {"cost": 500, "structure": "PASTURE", "first_yield_day": 6, "interval": 3, "max_held": 6, "product": "WOOL"},
}

PRODUCTS = ["WHEAT", "CARROT", "TOMATO", "STRAWBERRY", "MELON", "EGG", "MILK", "WOOL", "FERTILIZER"]

def _crop_profile(crop):
    """(harvest age, yield without fertilizer, days the tile is occupied)."""
    cd = CROPS[crop]
    if cd["ongoing"]:
        n = cd["max_yield"]
        last = cd["first_yield_day"] + (n - 1) * cd["interval"]
        return last, n, last + 1
    window = (cd["max_yield_day"] + 1) // 2
    cap = min(cd["max_yield"], 1 + (cd["max_yield_day"] - window + 1))
    age = max(cd["first_yield_day"], window + cap - 2)
    return age, cap, age + 1


CROP_PROFILE = {c: _crop_profile(c) for c in CROPS}
# Age (in days since planting) at which a one-time crop is worth harvesting.
HARVEST_AGE = {c: CROP_PROFILE[c][0] for c in CROPS}

MOVES = {"NORTH": (0, -1), "SOUTH": (0, 1), "EAST": (1, 0), "WEST": (-1, 0)}

PARAMS = {
    # --- crops -------------------------------------------------------------
    "town_drain_weight": 1.0,   # how much of the town's future demand to price in
    "min_crop_value": 25.0,     # $/tile/day below which a tile stays empty
    "wheat_crop_bias": 0.8,     # when feed is covered, wheat is just a cash crop
    "wheat_short_bias": 2.5,    # when it is not, growing feed outranks its sale price
    "wheat_cover_days": 4.0,    # days of feed on hand that counts as covered
    "max_crop_plan": 40,
    "labour_efficiency": 0.70,  # share of unit-turns that are not walking
    "seeds_per_turn": 6,
    "struct_slots_ahead": 12,
    # --- animals -----------------------------------------------------------
    "max_geese": 0,           # caps; the mix within them is chosen from prices
    "cows": 8,
    "sheep": 4,
    "animal_min_value": 0.0,
    "opponent_weight": 0.0,    # rival output to price in; measured no better at 0.5-1.0
    "last_animal_day": 18,      # after this, a new animal cannot pay for itself
    "cash_reserve": 260,        # keep this much on hand for wheat/hires
    "max_pending_animals": 3,   # unplaced livestock is dead capital
    # --- wheat -------------------------------------------------------------
    "feed_gain": 1.0,          # value of a feed = one banked CARE unit
    "wheat_days_buffer": 4.0,   # days of feed to keep in the shed; 2 starved the herd
    "last_wheat_day": 24,   # target shed wheat = animals * buffer
    "max_wheat_price": 70,      # floor under the dynamic ceiling below
    "feed_price_share": 0.0,    # buy feed up to this share of the herd's product price
    # --- labour ------------------------------------------------------------
    "max_hands": 13,
    "actions_per_unit": 24,
    "work_slack": 2.0,
    "work_per_animal": 7.0,
    "work_per_plant": 2.5,
    "max_hire_cost": 250,
    "min_hands": 4,
    # --- land --------------------------------------------------------------
    "land_reserve": 900,        # cash kept back after buying a quadrant
    "last_land_day": 20,
    "max_quadrants": 3,
    "land_when_empties": 8,
    # --- market ------------------------------------------------------------
    "fertilize_gain": 0.0,     # share of the extra yield we credit to FERTILIZE
    "fert_min_price": 4,        # below this, collecting fertilizer is a waste
    "wheat_take_mult": 0.34,   # wheat carried per hungry animal, per trip
    "idle_return": 1,          # idle hands walk back to the shed (measured even)
    "drop_load": 6,             # carried items that trigger a shed run
    "hold_days": 0.0,          # 0 = sell on sight; holding measured worse (see LEARNINGS)
    "hold_gain": 1.15,         # hold only if waiting beats selling by this much
    "hold_shed_cap": 70,       # never hold once the shed is this full
    "dump_days": 2,            # final days: sell everything, stock is worthless
    "min_sell_slots": 4,        # market-order slots always kept for selling
    "max_hires_per_turn": 4,
    # --- scheduler ---------------------------------------------------------
    "action_value": 30.0,       # dollars a unit-turn is worth (distance charge)
    "cluster_decay": 0.7,      # weight of the 2nd, 3rd... job on the same tile
    "sticky_bonus": 30.0,
    "fetch_range": 6,       # discourages re-targeting mid-walk
    "build_value": 160.0,
    "dig_value": 90.0,
    "plant_discount": 0.30,     # melon value is ten days away
    "builds_per_turn": 3,
    "build_lookahead": 2,
}
PARAMS.update(json.loads(os.environ.get("KAG_PARAMS", "{}")))
_LAST = {}          # (player, unit index) -> (target pos, op) from last turn
_TRACE = set(int(d) for d in os.environ.get("KAG_TRACE", "").split(",") if d.strip())

MARKET_PARAMS = {
    "WHEAT":      (25, 400, "sqrt", 0.80, "log", 0.20),
    "CARROT":     (35, 450, "hinge", 1.00, "sqrt", 0.70),
    "TOMATO":     (60, 200, "hinge", 0.40, "sqrt", 0.60),
    "STRAWBERRY": (120, 100, "sqrt", 0.70, "linear", 1.60),
    "MELON":      (250, 300, "log", 0.20, "sq", 3.60),
    "EGG":        (50, 332, "hinge", 0.40, "log", 0.20),
    "MILK":       (160, 122, "sqrt", 0.60, "linear", 1.60),
    "WOOL":       (200, 105, "log", 0.20, "sq", 3.20),
    "FERTILIZER": (100, 200, "linear", 0.40, "linear", 0.40),
}
MARKET_I0 = 10000


def _shape(func, x, T):
    x = max(0.0, x)
    if func == "linear":
        return x
    if func == "sq":
        return x * x
    if func == "sqrt":
        return math.sqrt(x)
    if func == "log":
        return math.log(1.0 + x)
    if func == "log10":
        return math.log10(1.0 + x)
    if func == "hinge":
        u = x / T
        return u + 8.0 * max(0.0, u - 1.0) ** 2
    return x


def market_price(item, inventory):
    base, T, bf, bt, af, at = MARKET_PARAMS[item]
    if inventory < MARKET_I0:
        amp = bt * base / _shape(bf, T, T)
        p = base + amp * _shape(bf, MARKET_I0 - inventory, T)
    else:
        amp = at * base / _shape(af, T, T)
        p = base - amp * _shape(af, inventory - MARKET_I0, T)
    return max(1, int(round(p)))


def sell_revenue(item, qty, inventory, offset=0):
    """Revenue from selling `qty` units, accounting for our own price impact.

    `offset` pretends that many units have already been sold, which is how the
    planner values the *next* tile of a crop it is already growing.
    """
    if qty <= 0:
        return 0.0
    inv = inventory + offset
    total = 0.0
    # Price moves slowly per unit; sample in blocks to keep the turn cheap.
    block = max(1, qty // 6)
    left = qty
    while left > 0:
        n = min(block, left)
        p = market_price(item, inv)
        total += p * n
        if p > 1:
            inv += n
        left -= n
    return total


def animal_value(name, day, market_inv, pipeline, fert_price, wheat_price, last_day=29):
    """Net dollars a newly placed animal is expected to add before the season ends.

    Counts the product it will produce (priced at the margin, after what the herd
    we already own will dump), the fertilizer it drops every day whether fed or
    not, and the wheat it eats.
    """
    d = ANIMALS[name]
    first = day + d["first_yield_day"] + 1
    prod_days = last_day - first + 1
    if prod_days <= 0:
        return -1e9
    # Daily feeding + CARE banks one extra unit per day, paid at each tick.
    units = int(prod_days * (1.0 + d["interval"]) / d["interval"])
    units = min(units, prod_days * d["max_held"])
    revenue = sell_revenue(d["product"], units, market_inv, pipeline)
    alive_days = max(0, last_day - day)
    return (revenue
            + alive_days * fert_price * 0.55      # fertilizer price decays as we sell
            - alive_days * wheat_price * 0.5      # we only feed when it pays
            - d["cost"])


# Each unlocked shop instance consumes one of every product it demands every 4
# turns (a single-product shop takes two), and the town centre takes one of
# every non-fertilizer product once a day. Shops keep unlocking every 3 days up
# to 8 instances, so this drain grows all season.
SHOPS = {
    "BAKERY": ("EGG", "WHEAT"),
    "PIZZA_SHOP": ("MILK", "TOMATO", "WHEAT"),
    "BRUNCH_SPOT": ("EGG", "WHEAT", "STRAWBERRY"),
    "YARN_STORE": ("WOOL",),
    "ICE_CREAM_SHOP": ("STRAWBERRY", "MILK", "WHEAT"),
    "PET_CAFE": ("CARROT",),
    "SMOOTHIE_SHOP": ("STRAWBERRY", "MILK"),
    "FARMERS_MARKET": ("WHEAT", "CARROT", "TOMATO", "STRAWBERRY"),
}


def town_drain(shops):
    """Units per day the town removes from the market, per product."""
    drain = {p: (0.0 if p == "FERTILIZER" else 1.0) for p in PRODUCTS}
    for name in shops or ():
        items = SHOPS.get(name)
        if not items:
            continue
        per_day = 12.0 if len(items) == 1 else 6.0
        for item in items:
            drain[item] += per_day
    return drain


LAND_PRICES = [1000, 2000, 4000]
_FIB = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, 233, 377, 610, 987, 1597, 2584, 4181, 6765]


def _fib(n):
    return _FIB[n] if n < len(_FIB) else 10 ** 9


def _shed_tiles(n):
    half = n // 2
    return [(half - 1, half - 1), (half, half - 1), (half - 1, half), (half, half)]


def _dist(a, b):
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def _step_towards(pos, target):
    dx = target[0] - pos[0]
    dy = target[1] - pos[1]
    if abs(dx) >= abs(dy):
        if dx > 0:
            return ["EAST"]
        if dx < 0:
            return ["WEST"]
    if dy > 0:
        return ["SOUTH"]
    if dy < 0:
        return ["NORTH"]
    if dx > 0:
        return ["EAST"]
    if dx < 0:
        return ["WEST"]
    return ["PASS"]


def _quadrant(x, y, n):
    half = n // 2
    return ("N" if y < half else "S") + ("W" if x < half else "E")


def _plan(obs):
    player = obs["player"]
    farms = obs["farms"]
    me = farms[player]
    priv = obs["private"]
    day = obs["day"]
    hour = obs["hour"]
    tiles = me["tiles"]
    n = len(tiles)
    money = me["money"]
    shed = dict(priv.get("shed") or {})
    seeds = dict(priv.get("seeds") or {})
    invs = priv.get("inventories") or [{}]
    prices = obs["market"]["prices"]
    shed_tiles = _shed_tiles(n)
    shed_count = sum(shed.values())

    units = [(0, tuple(me["farmer"]), dict(invs[0] if invs else {}))]
    for i, pos in enumerate(me.get("hands") or []):
        inv = dict(invs[i + 1]) if len(invs) > i + 1 else {}
        units.append((i + 1, tuple(pos), inv))
    n_hands = len(me.get("hands") or [])

    # ------------------------------------------------------------------ scan
    animals = []          # (x, y, tile)
    empty_struct = []     # structures waiting for an animal
    plants = []
    weeds = []
    empties = []
    for y in range(n):
        row = tiles[y]
        for x in range(n):
            t = row[x]
            if t is None:
                empties.append((x, y))
            elif t == "LOCKED":
                continue
            elif isinstance(t, dict):
                kind = t.get("kind")
                if kind == "PLANT":
                    plants.append((x, y, t))
                elif kind == "WEED":
                    weeds.append((x, y))
                elif "animal" in t:
                    animals.append((x, y, t))
                else:
                    empty_struct.append((x, y, kind))

    # The opponent's farm is public. Everything growing on it will hit the same
    # market we are pricing against, so count it into the supply pipeline —
    # otherwise we keep investing in milk that their herd is about to flood.
    opp_crop = {c: 0 for c in CROPS}
    opp_prod = {}
    for opp_i, opp in enumerate(farms):
        if opp_i == player:
            continue
        for row in opp["tiles"]:
            for t in row:
                if not isinstance(t, dict):
                    continue
                if t.get("kind") == "PLANT":
                    opp_crop[t["crop"]] += CROP_PROFILE[t["crop"]][1]
                elif "animal" in t:
                    d = ANIMALS[t["animal"]]
                    opp_prod[d["product"]] = opp_prod.get(d["product"], 0) + int(
                        max(0, 29 - day) * (1.0 + d["interval"]) / d["interval"])

    n_animals = len(animals)
    n_geese = sum(1 for _, _, t in animals if t["animal"] == "GOOSE")
    n_cows = sum(1 for _, _, t in animals if t["animal"] == "COW")
    n_sheep = sum(1 for _, _, t in animals if t["animal"] == "SHEEP")

    # Distance from the shed decides land use: animals need four visits a day
    # and live close in, crops need about one and take the outer tiles.
    def shed_dist(pos):
        return min(_dist(pos, s) for s in shed_tiles)

    pending_animals = sum(shed.get(a, 0) for a in ANIMALS)
    carried_animals = {}
    for idx, pos, inv in units:
        for a in ANIMALS:
            if inv.get(a, 0):
                carried_animals[idx] = a
                break

    empties.sort(key=shed_dist)
    n_struct_want = min(PARAMS["max_geese"] + PARAMS["cows"] + PARAMS["sheep"],
                        len(empties) + len(empty_struct) + n_animals)
    n_struct_need = max(0, min(n_struct_want - n_animals - len(empty_struct),
                               PARAMS["struct_slots_ahead"]))
    struct_slots = empties[:n_struct_need]
    crop_tiles = empties[n_struct_need:]

    # ---------------------------------------------------------- crop planner
    # Pick what to plant from the live market: town shops drain carrot, tomato
    # and strawberry all season and their scarcity curves are steep, so the best
    # crop changes as the season runs. Each extra tile is valued at the margin,
    # after the units our existing plantings will already dump.
    inv = obs["market"]["inventory"]
    pipeline = {c: opp_crop[c] * PARAMS["opponent_weight"] for c in CROPS}
    for _x, _y, t in plants:
        pipeline[t["crop"]] += CROP_PROFILE[t["crop"]][1]
    # Days of feed on hand, counting wheat still in the ground.
    growing_wheat = sum(1 for _x, _y, t in plants if t["crop"] == "WHEAT")
    wheat_cover = ((shed.get("WHEAT", 0) + sum(u[2].get("WHEAT", 0) for u in units)
                    + growing_wheat * CROP_PROFILE["WHEAT"][1])
                   / float(max(1, n_animals + pending_animals)))

    crop_plan = []
    days_left = 29 - day
    # Planting past what the hands can water just manufactures weeds: a tile
    # missed two days running is gone. Budget tiles against the labour we can
    # actually field, not against the land we happen to own.
    labour = (1 + PARAMS["max_hands"]) * PARAMS["actions_per_unit"] * PARAMS["labour_efficiency"]
    crop_capacity = int((labour - (n_animals + pending_animals) * PARAMS["work_per_animal"])
                        / PARAMS["work_per_plant"])
    room = max(0, min(PARAMS["max_crop_plan"], crop_capacity - len(plants)))
    # An ongoing crop planted late still delivers the yields that land before the
    # season ends: a strawberry sown on day 15 pays two of its four. Valuing it
    # at all-or-nothing retired strawberry from the plan on day 14 and left the
    # best late tiles going to wheat at half the return.
    def _partial(c):
        """(yields that will actually land, days the tile is tied up)."""
        cd = CROPS[c]
        age, yld, occ = CROP_PROFILE[c]
        if not cd["ongoing"]:
            return (yld, occ) if age <= days_left else (0, occ)
        n = 0
        last = 0
        for k in range(cd["max_yield"]):
            a = cd["first_yield_day"] + k * cd["interval"]
            if a > days_left:
                break
            n, last = n + 1, a
        return n, min(occ, last + 1)

    # Price the crop against the market it will actually be sold into: the town
    # will have eaten `drain * days` more of it by the time it is harvested.
    # Ignoring that made every additional tile look like self-inflicted glut and
    # left a third of the farm standing empty.
    drain = town_drain(obs.get("town", {}).get("unlocked_shops"))

    def _sale_inventory(c, wait_days):
        d = drain.get(c, 0.0) * wait_days * PARAMS["town_drain_weight"]
        return max(MARKET_I0 - 4000, inv.get(c, MARKET_I0) - d)

    for pos in crop_tiles[:room]:
        best_c, best_v, best_y = None, 0.0, 0
        for c in CROPS:
            yld, occ = _partial(c)
            if yld <= 0:
                continue
            rev = sell_revenue(c, yld, _sale_inventory(c, CROPS[c]["first_yield_day"]),
                               int(pipeline[c]))
            vpd = (rev - CROPS[c]["seed"]) / float(occ)
            if c == "WHEAT":
                # Wheat is feed before it is cash. Its sale price understates it
                # whenever the herd is running short, because the alternative is
                # buying on a curve that climbs as 25 + sqrt(units drawn down) --
                # and an unfed animal stops banking its CARE bonus.
                vpd *= PARAMS["wheat_crop_bias"] if wheat_cover >= PARAMS["wheat_cover_days"] \
                    else PARAMS["wheat_short_bias"]
            if vpd > best_v:
                best_c, best_v, best_y = c, vpd, yld
        if best_c is None or best_v < PARAMS["min_crop_value"]:
            break
        crop_plan.append((pos, best_c, best_v))
        pipeline[best_c] += best_y
    want_seeds = {}
    for _pos, c, _v in crop_plan:
        want_seeds[c] = want_seeds.get(c, 0) + 1

    # --------------------------------------------------------------- economy
    fert_price = prices.get("FERTILIZER", 0)
    wheat_price = prices.get("WHEAT", 999)
    wheat_stock = shed.get("WHEAT", 0) + sum(u[2].get("WHEAT", 0) for u in units)

    # ------------------------------------------------------------------ jobs
    jobs = []

    def add(pos, op, val, kind=None):
        jobs.append({"pos": pos, "op": op, "val": float(val), "kind": kind})

    # Job values are in dollars: what the action is expected to add to the bank.
    # Distance is charged at `action_value` per tile, so a unit only crosses the
    # farm when the payoff is genuinely worth the turns it burns.
    prod_price = {a: prices.get(d["product"], 1) for a, d in ANIMALS.items()}
    SURVIVAL = 1500.0

    wheat_available = wheat_stock
    for (x, y, t) in animals:
        pos = (x, y)
        name = t["animal"]
        a = ANIMALS[name]
        pp = prod_price[name]
        if not t["fed_today"] and wheat_available > 0:
            if t.get("consecutive_unfed", 0) >= 1:
                # One more missed day and the animal is gone for good.
                v = SURVIVAL + pp
            else:
                # An unfed animal still produces its base unit; feeding only buys
                # the CARE bonus (one extra unit at the next yield tick). For a
                # goose that barely covers the wheat, for a cow it is a bargain.
                v = pp * PARAMS["feed_gain"] - wheat_price
            if v > 0:
                add(pos, ["FEED"], v, "feed")
                wheat_available -= 1
        if t["fed_today"] and not t["cared_today"]:
            # CARE banks one extra unit of product, paid on the next yield tick.
            if t.get("yield_units", 0) + t.get("pending_care_bonus", 0) < a["max_held"]:
                add(pos, ["CARE"], pp, "care")
        yu = t.get("yield_units", 0)
        if yu > 0:
            v = yu * pp
            # At the holding cap further production is silently thrown away.
            add(pos, ["HARVEST"], v if yu >= a["max_held"] - 1 else v * 0.4, "harvest")
        if t.get("fertilizer_available") and fert_price >= PARAMS["fert_min_price"]:
            add(pos, ["COLLECT_FERTILIZER"], float(fert_price), "fert")

    for (x, y, t) in plants:
        pos = (x, y)
        crop = t["crop"]
        cd = CROPS[crop]
        cp = prices.get(crop, 1)
        age = day - t["planted_day"]
        yu = t.get("yield_units", 0)
        if not t["watered_today"]:
            if cd["ongoing"]:
                in_window = True
                gain = cp if t.get("fertilized_until_day", -1) >= day else 0.0
            else:
                window_start = (cd["max_yield_day"] + 1) // 2
                in_window = window_start <= age <= cd["max_yield_day"]
                gain = 0.0
                if in_window and yu < cd["max_yield"]:
                    gain = cp * (2 if t.get("fertilized_until_day", -1) >= day else 1)
            v = gain
            if t.get("consecutive_unwatered", 0) >= 1:
                # Missing today turns the tile into a weed tonight.
                remaining = max(0, cd["max_yield"] - yu) if age <= cd["max_yield_day"] else 0
                v += SURVIVAL + (yu + remaining * 0.6) * cp
            if v > 0:
                add(pos, ["WATER"], v, "water")
        # Fertilizer doubles the watering bonus for three days. On melon that
        # brings the tile to its cap two days early; on carrot and wheat it
        # raises the cap outright. Only units already carrying fertilizer (from
        # collecting it that morning) can do it, so no extra shed trip.
        if (t.get("fertilized_until_day", -1) < day and yu < cd["max_yield"]
                and fert_price < cp * PARAMS["fertilize_gain"]):
            if cd["ongoing"]:
                window_days = min(3, max(0, cd["max_yield_day"] + 4 - age))
            else:
                ws = (cd["max_yield_day"] + 1) // 2
                window_days = min(3, max(0, cd["max_yield_day"] - max(age, ws) + 1))
            if window_days > 0 and age + window_days <= days_left + 1:
                extra = min(window_days, cd["max_yield"] - yu)
                v = extra * cp * PARAMS["fertilize_gain"] - fert_price
                if v > 0:
                    add(pos, ["FERTILIZE"], v, "fertilize")
        if yu > 0 and age >= cd["first_yield_day"]:
            ripe = cd["ongoing"] or age >= HARVEST_AGE.get(crop, cd["max_yield_day"])
            decaying = (not cd["ongoing"]) and age > cd["max_yield_day"]
            if ripe:
                add(pos, ["HARVEST"], yu * cp * (1.0 if decaying else 0.5), "harvest")

    # Place animals that are waiting in a farmer's hands.
    free_structs = {"COOP": [], "PASTURE": []}
    for (x, y, kind) in empty_struct:
        free_structs[kind].append((x, y))
    for idx, animal in carried_animals.items():
        want = ANIMALS[animal]["structure"]
        days_left = max(0, 29 - day)
        v = 200 + prod_price[animal] * days_left / ANIMALS[animal]["interval"] * 0.15
        for pos in free_structs[want]:
            add(pos, ["PLACE", animal], v, "place:%s" % animal)

    # Build only slightly ahead of demand: an empty coop earns nothing and the
    # tile it sits on could have held a melon.
    incoming = pending_animals + len(carried_animals) + PARAMS["build_lookahead"]
    build_budget = max(0, min(incoming - len(empty_struct), len(struct_slots),
                              PARAMS["builds_per_turn"]))
    # What to build is decided by the livestock actually waiting to be placed:
    # building for the target mix instead deadlocks whenever the shed holds a
    # goose and every free structure is a pasture (or vice versa).
    waiting = {"COOP": 0, "PASTURE": 0}
    for a in ANIMALS:
        waiting[ANIMALS[a]["structure"]] += shed.get(a, 0)
    for _idx, a in carried_animals.items():
        waiting[ANIMALS[a]["structure"]] += 1
    short = {k: waiting[k] - len(free_structs[k]) for k in waiting}
    need_pasture = (PARAMS["cows"] - n_cows) + (PARAMS["sheep"] - n_sheep)
    build_val = PARAMS["build_value"] if day <= PARAMS["last_animal_day"] else 0.0
    if max(short.values()) > 0:
        build_val = max(build_val, 450.0)
    for i in range(build_budget):
        pos = struct_slots[i]
        if build_val <= 0:
            break
        if short["COOP"] > 0:
            kind, short["COOP"] = "BUILD_COOP", short["COOP"] - 1
        elif short["PASTURE"] > 0:
            kind, short["PASTURE"] = "BUILD_PASTURE", short["PASTURE"] - 1
        elif need_pasture > len(free_structs["PASTURE"]) + i:
            kind = "BUILD_PASTURE"
        else:
            kind = "BUILD_COOP"
        add(pos, [kind], build_val, "build")

    # Planting: the plan is ordered best-tile-first; only plant what we hold.
    left = dict(seeds)
    for pos, c, vpd in crop_plan:
        if left.get(c, 0) <= 0:
            continue
        left[c] -= 1
        add(pos, ["PLANT", c], vpd * CROP_PROFILE[c][2] * PARAMS["plant_discount"], "plant")

    if day <= PARAMS["last_animal_day"]:
        for pos in weeds[:6]:
            add(pos, ["DIG"], PARAMS["dig_value"], "dig")

    # ------------------------------------------------------- unit assignment
    # Two thirds of every unit-turn used to be spent walking, because each unit
    # was sent to a single best job and then re-decided from scratch next turn.
    # Jobs are grouped by tile instead: an animal tile is usually worth four
    # consecutive turns (feed, care, harvest, collect) with no walking at all,
    # so a unit should travel to the tile with the best *total* work on it, and
    # the walk is amortised over everything it will do once it arrives.
    unfed = sum(1 for _, _, t in animals if not t["fed_today"])

    def _can_do(job, idx, inv):
        if job["kind"] == "feed" and inv.get("WHEAT", 0) <= 0:
            return False
        if job["kind"] == "fertilize" and inv.get("FERTILIZER", 0) <= 0:
            return False
        if job["kind"] and job["kind"].startswith("place:"):
            return carried_animals.get(idx) == job["kind"].split(":")[1]
        return True

    by_tile = {}
    for ji, job in enumerate(jobs):
        by_tile.setdefault(job["pos"], []).append(ji)

    assign = {}
    taken = set()
    pairs = []
    decay = PARAMS["cluster_decay"]
    for ui, (idx, pos, inv) in enumerate(units):
        for tpos, jis in by_tile.items():
            doable = [ji for ji in jis if _can_do(jobs[ji], idx, inv)]
            if not doable:
                continue
            doable.sort(key=lambda ji: -jobs[ji]["val"])
            # Later jobs on the tile are worth less: each one costs another turn
            # and may be done by whoever passes through next.
            value = 0.0
            w = 1.0
            for ji in doable:
                value += jobs[ji]["val"] * w
                w *= decay
            score = value - _dist(pos, tpos) * PARAMS["action_value"]
            if _LAST.get((player, idx)) == tpos:
                score += PARAMS["sticky_bonus"]
            pairs.append((score, ui, tpos, doable[0]))
    pairs.sort(key=lambda p: (-p[0], p[1]))
    for _score, ui, tpos, ji in pairs:
        if ui in assign or tpos in taken:
            continue
        assign[ui] = ji
        taken.add(tpos)

    # ------------------------------------------------------------ unit moves
    unit_actions = []
    wheat_in_shed = shed.get("WHEAT", 0)
    animals_in_shed = {a: shed.get(a, 0) for a in ANIMALS}
    for ui, (idx, pos, inv) in enumerate(units):
        act = None
        carry = sum(v for k, v in inv.items() if k != "WHEAT" and k not in ANIMALS)
        at_shed = pos in shed_tiles
        shed_target = min(shed_tiles, key=lambda s: _dist(pos, s))

        need_wheat = inv.get("WHEAT", 0) <= 0 and unfed > 0 and wheat_in_shed > 0
        want_drop = carry >= PARAMS["drop_load"]
        # Only fetch livestock we can actually place: a goose is useless without
        # a free coop.
        pickup_animal = None
        if idx not in carried_animals:
            for a in ("SHEEP", "COW", "GOOSE"):
                if animals_in_shed.get(a, 0) > 0 and free_structs[ANIMALS[a]["structure"]]:
                    pickup_animal = a
                    break

        if at_shed:
            if want_drop:
                act = ["DROP"]
            elif pickup_animal:
                act = ["PICKUP", pickup_animal, 1]
                animals_in_shed[pickup_animal] -= 1
                carried_animals[idx] = pickup_animal
            elif need_wheat:
                # Inventories are unbounded, so carry a real load: every extra
                # wheat taken now is a shed round-trip not made later.
                take = max(1, min(wheat_in_shed, int(unfed * PARAMS["wheat_take_mult"]) + 2))
                act = ["PICKUP", "WHEAT", take]
                wheat_in_shed -= take
                inv["WHEAT"] = inv.get("WHEAT", 0) + take

        # Walking to the shed to restock / unload beats most field work: a unit
        # with no wheat cannot feed, and a full load risks the shed cap.
        if act is None and not at_shed and (need_wheat or want_drop or pickup_animal):
            if need_wheat or want_drop or _dist(pos, shed_target) <= PARAMS["fetch_range"]:
                act = _step_towards(pos, shed_target)

        if act is None and ui in assign:
            job = jobs[assign[ui]]
            act = list(job["op"]) if pos == job["pos"] else _step_towards(pos, job["pos"])

        if act is None:
            # With nothing to do, only walk back if there is something to unload:
            # two thirds of every turn is already spent walking.
            if carry > 0 and pos != shed_target:
                act = _step_towards(pos, shed_target)
            elif PARAMS["idle_return"] and pos != shed_target:
                act = _step_towards(pos, shed_target)
            else:
                act = ["PASS"]
        unit_actions.append(act)

    if _TRACE and player == 0 and day in _TRACE:
        kinds = {}
        for j in jobs:
            kinds[j["kind"]] = kinds.get(j["kind"], 0) + 1
        with open(os.environ.get("KAG_TRACE_FILE", "/tmp/kag_trace.log"), "a") as _fh:
            _fh.write("d%02d h%02d units=%d jobs=%s assigned=%d acts=%s empties=%d slots=%d/%d shed=%s\n"
                      % (day, hour, len(units), kinds, len(assign),
                         [a[0] for a in unit_actions], len(empties), len(struct_slots),
                         len(crop_plan), {k: v for k, v in shed.items() if v}))

    for ui, (idx, _pos, _inv) in enumerate(units):
        if ui in assign:
            _LAST[(player, idx)] = jobs[assign[ui]]["pos"]
        else:
            _LAST.pop((player, idx), None)

    farmer_action = unit_actions[0] if unit_actions else ["PASS"]
    hand_actions = unit_actions[1:1 + n_hands]
    while len(hand_actions) < n_hands:
        hand_actions.append(["PASS"])

    # ----------------------------------------------------------- market plan
    # Only `maxMarketOrdersPerTurn` (10) orders are processed per turn, so sells
    # and buys have to share the queue: a turn spent selling five products is a
    # turn that could not restock wheat or buy a goose.
    sells = []
    orders = []
    budget = money
    last_day = day >= 29

    # Hold what the town is about to make scarcer. Shops eat 6 units a day of
    # every product they demand, so a scarce resource's price climbs all season
    # (strawberry runs $120 -> $330); dumping a harvest the turn it lands sells
    # into the cheapest market it will ever have. Fertilizer and melon have no
    # shop demand, so they only ever get cheaper and go out immediately.
    sell_drain = town_drain(obs.get("town", {}).get("unlocked_shops"))
    hold_days = PARAMS["hold_days"]
    room_pressure = shed_count > PARAMS["hold_shed_cap"]
    dumping = day >= 29 - PARAMS["dump_days"]
    for item in PRODUCTS:
        if item == "WHEAT":
            continue
        qty = shed.get(item, 0)
        if qty <= 0:
            continue
        p_now = prices.get(item, 1)
        if not dumping and not room_pressure and hold_days > 0:
            later = max(MARKET_I0 - 4000,
                        inv.get(item, MARKET_I0) - sell_drain.get(item, 0.0) * hold_days)
            if market_price(item, later) > p_now * PARAMS["hold_gain"]:
                continue
        value = qty * p_now
        sells.append((value, ["SELL", item, qty]))
        budget += value
    # Wheat above what the animals need is dead weight.
    keep_wheat = 0 if last_day else int(n_animals * PARAMS["wheat_days_buffer"]) + 4
    surplus_wheat = shed.get("WHEAT", 0) - keep_wheat
    if surplus_wheat > 0:
        sells.append((surplus_wheat * prices.get("WHEAT", 1), ["SELL", "WHEAT", surplus_wheat]))
    sells.sort(key=lambda kv: -kv[0])

    hires_today = me.get("hires_today", 0)

    # Hiring first: a hand costs fib(n) (the first six together cost $20) and
    # supplies 24 actions, so labour is almost never the thing to economise on.
    if hour <= 3 and not last_day:
        work = (n_animals * PARAMS["work_per_animal"] + len(plants) * PARAMS["work_per_plant"]
                + pending_animals * 3 + 8)
        want_units = int(work * PARAMS["work_slack"] / PARAMS["actions_per_unit"]) + 1
        if n_animals or plants:
            want_units = max(want_units, PARAMS["min_hands"] + 1)
        want_units = min(1 + PARAMS["max_hands"], want_units)
        for _ in range(min(PARAMS["max_hires_per_turn"], max(0, want_units - 1 - n_hands))):
            cost = _fib(hires_today)
            if cost > PARAMS["max_hire_cost"] or budget - cost < 30:
                break
            orders.append(["HIRE"])
            budget -= cost
            hires_today += 1

    if not last_day:
        # Wheat feed: each extra wheat buys a full day of care bonus (2 eggs).
        want_wheat = int(n_animals * PARAMS["wheat_days_buffer"]) + 3
        short = want_wheat - wheat_stock
        room = 100 - shed_count
        # A fed-and-cared animal banks one extra unit of its product, so a wheat
        # is worth up to that unit: ~$40 for a goose but $250+ for a dairy cow.
        # A flat $70 ceiling was a leftover from the goose era and starved the
        # herd the moment the town pushed wheat past it.
        herd_worth = max([prod_price[t["animal"]] for _x, _y, t in animals] or [0])
        wheat_ceiling = max(PARAMS["max_wheat_price"], herd_worth * PARAMS["feed_price_share"])
        if short > 0 and wheat_price <= wheat_ceiling and room > 4:
            qty = min(short, room - 2, max(0, int((budget - PARAMS["cash_reserve"]) // max(1, wheat_price))))
            if qty > 0:
                orders.append(["BUY_PRODUCT", "WHEAT", qty])
                budget -= qty * wheat_price

        # Seed for whatever the crop planner asked for, dearest crop first:
        # those are the tiles worth the most per day.
        for c in sorted(want_seeds, key=lambda k: -CROPS[k]["seed"]):
            need = want_seeds[c] - seeds.get(c, 0)
            if need <= 0:
                continue
            afford = int(max(0, budget - PARAMS["cash_reserve"]) // CROPS[c]["seed"])
            qty = min(need, afford, PARAMS["seeds_per_turn"])
            if qty > 0:
                orders.append(["BUY_SEED", c, qty])
                budget -= qty * CROPS[c]["seed"]

        # Land: a quadrant is 25 tiles and a stocked tile clears its cost in days.
        n_extra = len(me.get("unlocked_quadrants", ["NW"])) - 1
        if (n_extra < PARAMS["max_quadrants"] - 1 and day <= PARAMS["last_land_day"]
                and len(empties) <= PARAMS["land_when_empties"]):
            cost = LAND_PRICES[n_extra]
            if budget - cost >= PARAMS["land_reserve"]:
                orders.append(["BUY_LAND"])
                budget -= cost

        # Livestock, valued the same way as crops: what the animal will earn in
        # product and fertilizer before the season ends, minus its feed and its
        # price, with the product priced at the margin after the herd we already
        # own has sold. That keeps the mix responsive to which shops the town
        # happened to unlock instead of betting on a fixed cow/sheep ratio.
        if day <= PARAMS["last_animal_day"] and pending_animals < PARAMS["max_pending_animals"]:
            open_struct = len(empty_struct) + build_budget - pending_animals - len(carried_animals)
            slots = min(open_struct, PARAMS["max_pending_animals"] - pending_animals)
            reserve = PARAMS["cash_reserve"] + n_animals * min(wheat_price, 40) * 1.5
            herd_pipeline = {k: v * PARAMS["opponent_weight"] for k, v in opp_prod.items()}
            for _x, _y, t in animals:
                d = ANIMALS[t["animal"]]
                left = max(0, 29 - day)
                herd_pipeline[d["product"]] = herd_pipeline.get(d["product"], 0) + int(
                    left * (1.0 + d["interval"]) / d["interval"])
            caps = {"GOOSE": PARAMS["max_geese"], "COW": PARAMS["cows"], "SHEEP": PARAMS["sheep"]}
            have = {"GOOSE": n_geese, "COW": n_cows, "SHEEP": n_sheep}
            while slots > 0 and shed_count < 96:
                best, best_v = None, PARAMS["animal_min_value"]
                for a, d in ANIMALS.items():
                    if have[a] + shed.get(a, 0) >= caps[a] or budget - d["cost"] < reserve:
                        continue
                    drained = max(MARKET_I0 - 4000,
                                  inv.get(d["product"], MARKET_I0)
                                  - town_drain(obs.get("town", {}).get("unlocked_shops")).get(
                                      d["product"], 0.0)
                                  * d["first_yield_day"] * PARAMS["town_drain_weight"])
                    v = animal_value(a, day, drained,
                                     int(herd_pipeline.get(d["product"], 0)), fert_price,
                                     wheat_price)
                    if v > best_v:
                        best, best_v = a, v
                if best is None:
                    break
                orders.append(["BUY_ANIMAL", best, 1])
                budget -= ANIMALS[best]["cost"]
                have[best] += 1
                d = ANIMALS[best]
                herd_pipeline[d["product"]] = herd_pipeline.get(d["product"], 0) + int(
                    max(0, 29 - day) * (1.0 + d["interval"]) / d["interval"])
                slots -= 1

    # Merge: keep room for the most valuable sells, then spend what is left on
    # the buy/hire queue (which is already in priority order).
    n_sell = min(len(sells), max(10 - len(orders), PARAMS["min_sell_slots"]))
    market = [o for _v, o in sells[:n_sell]] + orders[:10 - n_sell]
    return {"farmer": farmer_action, "hands": hand_actions, "market": market[:10]}


def agent(obs):
    """Entry point. A crash here would cost the whole episode, so fall back to
    a harmless action rather than letting the exception escape."""
    try:
        return _plan(obs)
    except Exception:  # pragma: no cover - defensive
        try:
            n_hands = len(obs["farms"][obs["player"]].get("hands") or [])
        except Exception:
            n_hands = 0
        return {"farmer": ["PASS"], "hands": [["PASS"]] * n_hands, "market": []}
