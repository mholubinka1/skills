# Good and Bad Tests

## Translating Scenarios to Code

Given-When-Then scenarios map directly to test structure. The scenario title becomes the test name; Given/When/Then become the test body sections:

```gherkin
Scenario: shopper receives confirmation when checking out with a valid cart
  Given a cart with one in-stock product
  When the shopper checks out with a valid payment method
  Then the order is confirmed and the shopper receives a confirmation number
```

```typescript
test("shopper receives confirmation when checking out with a valid cart", async () => {
  // Given
  const cart = createCart();
  cart.add(inStockProduct);

  // When
  const result = await checkout(cart, validPaymentMethod);

  // Then
  expect(result.status).toBe("confirmed");
  expect(result.confirmationNumber).toBeDefined();
});
```

Test names should be readable sentences in the language of the business, not implementation descriptions. "checkout returns 200" → bad. "shopper receives confirmation" → good.

## Good Tests

**Integration-style**: Test through real interfaces, not mocks of internal parts.

```typescript
// GOOD: Tests observable behavior
test("user can checkout with valid cart", async () => {
  const cart = createCart();
  cart.add(product);
  const result = await checkout(cart, paymentMethod);
  expect(result.status).toBe("confirmed");
});
```

Characteristics:

- Tests behavior users/callers care about
- Uses public API only
- Survives internal refactors
- Describes WHAT, not HOW
- One logical assertion per test

## Bad Tests

**Implementation-detail tests**: Coupled to internal structure.

```typescript
// BAD: Tests implementation details
test("checkout calls paymentService.process", async () => {
  const mockPayment = jest.mock(paymentService);
  await checkout(cart, payment);
  expect(mockPayment.process).toHaveBeenCalledWith(cart.total);
});
```

Red flags:

- Mocking internal collaborators
- Testing private methods
- Asserting on call counts/order
- Test breaks when refactoring without behavior change
- Test name describes HOW not WHAT
- Verifying through external means instead of interface

```typescript
// BAD: Bypasses interface to verify
test("createUser saves to database", async () => {
  await createUser({ name: "Alice" });
  const row = await db.query("SELECT * FROM users WHERE name = ?", ["Alice"]);
  expect(row).toBeDefined();
});

// GOOD: Verifies through interface
test("createUser makes user retrievable", async () => {
  const user = await createUser({ name: "Alice" });
  const retrieved = await getUser(user.id);
  expect(retrieved.name).toBe("Alice");
});
```

## Tests that never earn their place

A test earns its place when breaking a behaviour a scenario names turns it red. Never write
these:

- **Unreachable input**: a state no production caller produces, such as an empty list the
  caller already guards against. Read the callers first, then test the guard.
- **Echoes**: assertions that restate a constant, a config structure, or a class or handler
  type. Assert the behaviour the value causes.
- **Library proofs**: showing the standard library, framework or a dependency works (log
  rotation, a config call replacing handlers). Test your use of it.
- **Impossible failures**: patching your own code to raise an error it cannot raise, so a
  defensive branch gets covered. Drive failures from a real boundary, or delete the branch.
- **Accidents**: pinning behaviour no scenario asked for: a leaked `KeyError`, an order
  nothing depends on, a missing bound noted as "there is no lower bound". Leave it free to
  change.
- **Repeats**: one behaviour asserted at two layers, or twice in one file under different
  names. Test a rule's boundary values once, at the unit that owns the rule; test the
  wiring once, at the outermost layer.
- **Log transcripts**: an exact sequence of log lines, or a filter on the logging file's
  name. When a scenario says something is logged, assert that one line.
- **Ghost absences**: asserting that text is absent when it only ever appeared in a draft.
  Keep a negative assertion when a scenario requires the absence (a secret never logged)
  or it guards a defect that could come back.
