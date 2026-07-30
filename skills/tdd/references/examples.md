# Worked examples

Paired good and bad tests for the principles in `SKILL.md`, plus mocking
recipes. Examples are TypeScript with plain `describe` / `it` / `expect`
style; the patterns carry over to any runner.

The examples share this small domain:

```ts
export type Item = { readonly sku: string; readonly price: number; readonly qty: number };

export type Cart = { readonly items: readonly Item[]; readonly discountCode?: string };

export type Receipt = {
  readonly subtotal: number;
  readonly discount: number;
  readonly total: number;
};
```

## 1. Behavior versus implementation detail

The unit under test:

```ts
export type DiscountLookup = (code: string) => number;

export const priceCart = (cart: Cart, lookupDiscount: DiscountLookup): Receipt => {
  const subtotal = cart.items.reduce((sum, item) => sum + item.price * item.qty, 0);
  const rate = cart.discountCode === undefined ? 0 : lookupDiscount(cart.discountCode);
  const discount = Math.round(subtotal * rate);
  return { subtotal, discount, total: subtotal - discount };
};
```

### Bad

```ts
it("calls the discount lookup with the code", () => {
  const lookupDiscount = jest.fn<number, [string]>().mockReturnValue(0.1);
  priceCart({ items: [{ sku: "a", price: 500, qty: 1 }], discountCode: "SAVE10" }, lookupDiscount);

  expect(lookupDiscount).toHaveBeenCalledTimes(1);
  expect(lookupDiscount).toHaveBeenCalledWith("SAVE10");
});
```

This asserts on the mechanism, not the outcome. It passes even if the
discount is never applied to the total, and it breaks if `priceCart` starts
caching rates or looks the code up once for a batch of carts - both correct
refactors. The name describes plumbing, so a reader learns nothing about
what pricing guarantees.

### Good

```ts
it("applies a percentage discount to the subtotal", () => {
  const cart: Cart = {
    items: [{ sku: "widget", price: 500, qty: 2 }],
    discountCode: "SAVE10",
  };
  const lookupDiscount: DiscountLookup = () => 0.1;

  const receipt = priceCart(cart, lookupDiscount);

  expect(receipt).toEqual({ subtotal: 1000, discount: 100, total: 900 });
});
```

The assertion is on the observable result. Any implementation that prices
correctly passes, and the name states the requirement. Note the stub is a
plain function rather than a mock: nothing here needs to record calls.

## 2. AAA versus interleaved phases

The unit under test:

```ts
export type CartStore = {
  readonly add: (item: Item) => void;
  readonly remove: (sku: string) => void;
  readonly contents: () => readonly Item[];
};

export const createCartStore = (): CartStore => {
  let items: readonly Item[] = [];
  return {
    add: (item) => {
      items = [...items, item];
    },
    remove: (sku) => {
      items = items.filter((item) => item.sku !== sku);
    },
    contents: () => items,
  };
};
```

### Bad

```ts
it("manages cart contents", () => {
  const store = createCartStore();
  store.add({ sku: "a", price: 100, qty: 1 });
  expect(store.contents()).toHaveLength(1);
  store.add({ sku: "b", price: 200, qty: 1 });
  expect(store.contents()).toHaveLength(2);
  store.remove("a");
  expect(store.contents()).toHaveLength(1);
  expect(store.contents()[0].sku).toBe("b");
});
```

Actions and assertions alternate, so a failure on the last line does not
say whether adding or removing is broken. The test also cannot fail for one
reason: it covers three requirements, and the name ("manages cart
contents") had to become vague enough to cover all of them.

### Good

```ts
it("holds an added item", () => {
  const store = createCartStore();
  const item: Item = { sku: "widget", price: 100, qty: 1 };

  store.add(item);

  expect(store.contents()).toEqual([item]);
});

it("drops a removed item and keeps the rest", () => {
  const store = createCartStore();
  const kept: Item = { sku: "kept", price: 200, qty: 1 };
  store.add({ sku: "dropped", price: 100, qty: 1 });
  store.add(kept);

  store.remove("dropped");

  expect(store.contents()).toEqual([kept]);
});
```

Each test has one action between visually separate arrange and assert
phases, and each name states a single requirement. Setup calls to `add`
in the second test are arrangement, not the act; only the line under test
sits in the act phase.

Legitimate departures from AAA: a parameterized table where arrange and act
collapse into one call per row, a property-based test whose arrange step is
a generator, and integration tests that necessarily interleave steps
against a live system.

## 3. One behavior versus kitchen-sink

### Bad

```ts
it("prices carts correctly", () => {
  const lookupDiscount: DiscountLookup = (code) => (code === "SAVE10" ? 0.1 : 0);

  expect(priceCart({ items: [] }, lookupDiscount).total).toBe(0);
  expect(
    priceCart({ items: [{ sku: "a", price: 300, qty: 3 }] }, lookupDiscount).total,
  ).toBe(900);
  expect(
    priceCart(
      { items: [{ sku: "a", price: 300, qty: 3 }], discountCode: "SAVE10" },
      lookupDiscount,
    ).total,
  ).toBe(810);
  expect(
    priceCart({ items: [{ sku: "a", price: 300, qty: 3 }], discountCode: "NOPE" }, lookupDiscount)
      .total,
  ).toBe(900);
});
```

Four requirements in one test. The first failing assertion hides the rest,
so a run tells you one thing was wrong rather than which three still work.

The stub is a second problem: it branches on the code to serve all four
cases, which re-implements the real lookup's decision inside the test. A
stub should return canned data, not decide. Splitting the test removes the
need for it - each case pins the one rate it is about, as below.

### Good

Separate tests when the requirements differ:

```ts
it("totals an empty cart as zero", () => {
  const receipt = priceCart({ items: [] }, () => 0);

  expect(receipt.total).toBe(0);
});

it("ignores a discount code that is not recognized", () => {
  const cart: Cart = { items: [{ sku: "a", price: 300, qty: 3 }], discountCode: "NOPE" };

  const receipt = priceCart(cart, () => 0);

  expect(receipt).toEqual({ subtotal: 900, discount: 0, total: 900 });
});
```

Or parameterize when the requirement is one rule over many inputs. This is
the AAA exception in practice, and it is fine because every row exercises
the same behavior:

```ts
const quantityCases: readonly { qty: number; expected: number }[] = [
  { qty: 1, expected: 300 },
  { qty: 2, expected: 600 },
  { qty: 3, expected: 900 },
];

it.each(quantityCases)("multiplies unit price by quantity ($qty)", ({ qty, expected }) => {
  const receipt = priceCart({ items: [{ sku: "a", price: 300, qty }] }, () => 0);

  expect(receipt.subtotal).toBe(expected);
});
```

## 4. Mocking recipe: the clock

Take the clock as a dependency instead of reading it inside the function.
The seam makes the test deterministic without any patching.

```ts
export type Clock = () => Date;

export const isExpired = (expiresAt: Date, now: Clock): boolean =>
  now().getTime() >= expiresAt.getTime();
```

```ts
it("treats a token as expired once the expiry has passed", () => {
  const expiresAt = new Date("2026-01-01T00:00:00Z");
  const now: Clock = () => new Date("2026-01-01T00:00:01Z");

  expect(isExpired(expiresAt, now)).toBe(true);
});

it("treats a token as live before the expiry", () => {
  const expiresAt = new Date("2026-01-01T00:00:00Z");
  const now: Clock = () => new Date("2025-12-31T23:59:59Z");

  expect(isExpired(expiresAt, now)).toBe(false);
});
```

If the code under test cannot take a clock (third-party code, deep call
stack), fall back to the runner's fake timers. That is a weaker option
because it couples the test to the framework, so prefer the seam.

## 5. Mocking recipe: a service boundary

Stub at the boundary you own - the narrow interface your code calls -
rather than at the HTTP client.

```ts
export type PaymentGateway = {
  readonly charge: (cents: number) => Promise<{ readonly ok: boolean }>;
};

export const checkout = async (
  cart: Cart,
  lookupDiscount: DiscountLookup,
  gateway: PaymentGateway,
): Promise<"paid" | "declined"> => {
  const receipt = priceCart(cart, lookupDiscount);
  const result = await gateway.charge(receipt.total);
  return result.ok ? "paid" : "declined";
};
```

```ts
const stubGateway = (ok: boolean): PaymentGateway => ({
  charge: async () => ({ ok }),
});

it("reports a declined payment", async () => {
  const cart: Cart = { items: [{ sku: "a", price: 500, qty: 1 }] };

  const outcome = await checkout(cart, () => 0, stubGateway(false));

  expect(outcome).toBe("declined");
});
```

When the requirement really is about what crosses the boundary, asserting
on the call is legitimate - that message is observable behavior, not an
internal detail:

```ts
it("charges the discounted total", async () => {
  const charged: number[] = [];
  const gateway: PaymentGateway = {
    charge: async (cents) => {
      charged.push(cents);
      return { ok: true };
    },
  };
  const cart: Cart = { items: [{ sku: "a", price: 1000, qty: 1 }], discountCode: "SAVE10" };

  await checkout(cart, () => 0.1, gateway);

  expect(charged).toEqual([900]);
});
```

## 6. The internal collaborator tradeoff

`priceCart` is an internal collaborator of `checkout`. Shown both ways.

**Leave it real (the default).** It is pure, fast, and yours, so running it
means the test covers the two pieces actually fitting together. Note that
example 5 already did this: it passed a real discount lookup and let
`priceCart` compute, which is why the `[900]` assertion is meaningful.

**Mock it when it drags a boundary in.** Suppose pricing grows a tax step
that calls a rates service over the network:

```ts
export type TaxedPricer = (cart: Cart) => Promise<Receipt>;

export const checkoutWithTax = async (
  cart: Cart,
  price: TaxedPricer,
  gateway: PaymentGateway,
): Promise<"paid" | "declined"> => {
  const receipt = await price(cart);
  const result = await gateway.charge(receipt.total);
  return result.ok ? "paid" : "declined";
};
```

Now a checkout test that used the real pricer would hit the network: slow,
nondeterministic, and failing for reasons that have nothing to do with
checkout. Substituting it is justified here.

```ts
it("declines when the gateway rejects the taxed total", async () => {
  const price: TaxedPricer = async () => ({ subtotal: 1000, discount: 0, total: 1080 });

  const outcome = await checkoutWithTax({ items: [] }, price, stubGateway(false));

  expect(outcome).toBe("declined");
});
```

The test that the real pricing and the real tax boundary agree still has to
exist. It belongs in its own test of the pricer, where the tax service is
the thing being faked, not a coincidental dependency.

The tradeoff in one line: leave internal collaborators real until one is
slow, nondeterministic, or pulls in a boundary, and when you do fake one,
make sure some other test still covers the real thing.
