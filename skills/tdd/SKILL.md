---
name: tdd
description: How to write good tests - behavior-focused assertions, the AAA structure, red/green/refactor, small vertical slices, and what to mock versus leave real. Use whenever writing a new test, modifying or fixing an existing test, reviewing someone else's tests, deciding whether something needs a test, choosing what to mock or fake, or answering a question about testing practice.
---

Tests are read far more often than they are written, and a bad test is worse
than no test: it fails when the code is fine, passes when the code is broken,
or freezes a design decision nobody meant to commit to. These rules describe
what good looks like. They are language-agnostic; worked examples in
TypeScript live in `references/examples.md`.

## What makes a good test

- **Tests behavior, not implementation.** Assert on what a caller can
  observe: return values, thrown errors, messages sent across a boundary,
  persisted state. Never on private fields, internal call counts, or the
  order of internal steps. A correct refactor must not break a good test.
- **Fails for one reason you care about.** A test can rarely have only one
  technical cause of failure, and chasing that is a dead end. The real rule
  is one behavior or requirement per test: when it goes red, the name alone
  should tell you which requirement broke.
- **Deterministic.** Same input, same result, on any machine, in any order,
  at any time of day. No real clocks, no real network, no reliance on test
  execution order or on state another test left behind.
- **Readable as documentation.** The test name states the requirement in
  domain language, not mechanics. Someone who has never seen the
  implementation should learn what it guarantees by reading the test.
- **Structured as Arrange, Act, Assert by default.** Set up the state,
  perform the one action under test, then assert on the outcome, with the
  three phases visually distinct (a blank line between them is enough).
  Default, not law: parameterized tests, property-based tests, and some
  integration tests do not map onto separated phases, and forcing the shape
  onto them makes them worse. Depart from AAA when the test genuinely does
  not fit it, not to save a few lines.

## Anti-patterns

- **Testing implementation details.** Asserting that a helper was called,
  or reaching into private state. This is the most common way tests become
  a tax on refactoring instead of a safety net for it.
- **Snapshot-everything.** Broad snapshots assert on everything and
  therefore specify nothing. Every unrelated change produces a diff, and
  the habitual fix is to re-record the snapshot, which is not review.
  Snapshots are for genuinely opaque large output, and even then, prefer
  targeted assertions on the parts that carry meaning.
- **Shared mutable fixtures.** State built once and mutated by several
  tests couples them, makes failures order-dependent, and makes any single
  test unreadable in isolation. Construct fresh state per test.
- **Tests that mirror the code.** One test file per source file, one test
  per method, is a structure that follows the implementation rather than
  the requirements. Organize around behaviors instead, so that reshaping
  the code does not mean rewriting the suite.
- **Tautological assertions.** Computing the expected value with the same
  logic the code uses, or asserting a mock returns what it was configured
  to return. The test passes by construction and verifies nothing.
- **Interleaved act and assert.** Alternating actions and checks inside one
  test hides which action a failure belongs to. If several actions each
  need assertions, that is several tests, or one action whose observable
  outcome you assert once.

## Process

Work red, green, refactor:

1. **Red.** Write the smallest test that expresses the next requirement,
   then run it and watch it fail. Skipping this step is how tests that
   assert nothing get written, and the failure message is the only proof
   the test can detect the thing it claims to.
2. **Green.** Make it pass by the most direct means available. Do not
   generalize ahead of a second case that demands it.
3. **Refactor.** With the test green, improve names and structure. The
   suite staying green is what makes this step safe.

Slice work into small vertical increments: pick the thinnest end-to-end
behavior that is worth something on its own, test it, make it work, then
take the next slice. A slice too large to describe in one test name is too
large to implement in one step, and its test cannot fail for one clear
reason. When a requirement resists testing, that is usually a design
signal, so treat it as one rather than reaching for heavier test machinery.

## Mocking

Every fake is a claim that the real thing behaves as you have described,
and that claim is never verified by the test that relies on it. So each
one has to earn its place.

Replace things at real boundaries, where the alternative is slow,
nondeterministic, or outside your control:

- network calls and external services
- clocks, timers, and randomness
- the filesystem, at the boundary where your code touches it
- anything whose real version has side effects you cannot allow in a test

Leave real:

- the code under test, always, including its private helpers
- data types and values you own that are cheap to construct, especially
  plain data - a fake for something you can build in one line is pure cost

Internal collaborators are the genuinely arguable case, so weigh it rather
than applying a rule. The default is to leave them real: they are yours,
they are usually fast, and running them means the test covers how the
pieces actually fit together instead of how you imagined they do. Mocking
one is justified when it is slow, when it is nondeterministic, or when it
drags an unintended boundary into the test - a collaborator that opens a
socket or reads a file pulls the real dependency in behind it. Reach for a
fake when one of those holds, not by default, and prefer a simple stub over
a mock that asserts on how it was called.

Prefer faking the boundary at a seam you own: pass the dependency in and
substitute a plain implementation in the test. That keeps the fake honest
and readable, and it avoids coupling the test to the framework's
patching mechanics.

Whatever you fake, be clear what a stub is: a test replacement that
returns predetermined responses and neither records nor verifies how it
was called. A stub may select among canned responses by input, such as a
fixed input-to-output map - scripted responses are still data you chose.
What it must not do is re-implement the collaborator's production
decisions: that branching is a second copy of your logic living in the
test, and like the tautological assert, two copies that agree prove
nothing and drift apart silently. If a fake only works by mirroring the
real rules, split the test so each case pins its own canned response, or
stop faking and use the real collaborator.

## Worked examples

`references/examples.md` has paired good and bad versions of these
principles in TypeScript, plus concrete mocking recipes: faking a clock,
stubbing a service boundary, and one internal collaborator shown both ways
so the tradeoff above is visible in code.
