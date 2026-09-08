# Personal Coding Preferences

## About Me
Senior Software Developer with a strong focus on code quality and maintainability.

## Code Style
- Prioritize clean code and high readability over brevity
- Prefer extracting logic into smaller, well-named helper methods rather than writing long methods
- Follow the Single Responsibility Principle consistently
- Keep functions short and focused on one task
- Use descriptive, intention-revealing names for variables, functions, and classes
- Always write source code in English (variable names, comments, function names, strings)

```typescript
// Good - small, focused functions with clear names
function calculateDiscountedPrice(price: number, discount: number): number {
  const discountAmount = computeDiscountAmount(price, discount);
  return applyMinimumPrice(price - discountAmount);
}

// Bad - long method doing multiple things
function process(p: number, d: number): number {
  let result = p;
  if (d > 0 && d <= 100) {
    result = p - (p * d / 100);
    if (result < 0) result = 0;
  }
  return result;
}
```

## Naming
- Use intention-revealing names; the name should explain *why* something exists, not just *what* it is
- Avoid abbreviations unless they are universally understood (e.g. `id`, `url`, `http`)
- Boolean variables and functions should read as yes/no questions: `isActive`, `hasPermission`, `canRetry`

```typescript
// Good
const activeUsers = users.filter(isAccountActive);
const maxRetryCount = 3;

// Bad
const list = users.filter(x => x.a);
const n = 3;
```

## Structure
- Favor a well-organized project structure with clear separation of concerns
- Extract reusable logic into dedicated utility functions or modules
- Prefer composition over inheritance where applicable
- When in doubt, extract a method — one more well-named function is always better than a long block of inline code
- Avoid deep nesting; prefer early returns and guard clauses

```typescript
// Good - early return, flat structure
function processOrder(order: Order): Result {
  if (!order.isValid()) {
    return Result.invalid("Order validation failed");
  }

  if (!order.hasItems()) {
    return Result.invalid("Order has no items");
  }

  const total = calculateTotal(order.items);
  return Result.success(total);
}

// Bad - deep nesting
function processOrder(order: Order): Result {
  if (order.isValid()) {
    if (order.hasItems()) {
      const total = calculateTotal(order.items);
      return Result.success(total);
    } else {
      return Result.invalid("Order has no items");
    }
  } else {
    return Result.invalid("Order validation failed");
  }
}
```

## Error Handling
- Handle errors explicitly; never silently swallow exceptions
- Prefer returning result types or specific error objects over throwing generic exceptions
- Log errors with sufficient context for debugging (what failed, with which input)
- Use typed errors where the language supports it

```typescript
// Good - explicit error handling with context
function parseConfig(path: string): Config {
  const content = readFile(path);
  if (!content) {
    throw new ConfigError(`Failed to read config file at: ${path}`);
  }

  const parsed = validateSchema(content);
  if (!parsed.success) {
    throw new ConfigError(`Invalid config in ${path}: ${parsed.error}`);
  }

  return parsed.data;
}

// Bad - swallowed error, no context
function parseConfig(path: string): Config | null {
  try {
    return JSON.parse(readFileSync(path, "utf-8"));
  } catch {
    return null;
  }
}
```

## Testing
- Aim for high test coverage
- Write unit tests for all business logic
- Prefer small, focused test cases with clear assertions
- Follow the Arrange-Act-Assert pattern
- Test edge cases and error paths, not just happy paths
- Test names should describe the expected behavior, not the implementation
- Avoid mocking where possible; prefer real implementations or fakes

```typescript
// Good - clear test name, AAA pattern, tests behavior
describe("calculateDiscount", () => {
  it("should apply percentage discount to the original price", () => {
    const originalPrice = 100;
    const discountPercent = 20;

    const result = calculateDiscount(originalPrice, discountPercent);

    expect(result).toBe(80);
  });

  it("should return zero when discount is 100 percent", () => {
    const result = calculateDiscount(50, 100);

    expect(result).toBe(0);
  });

  it("should not allow negative prices", () => {
    expect(() => calculateDiscount(-10, 20)).toThrow(InvalidPriceError);
  });
});

// Bad - vague name, no structure, tests implementation
test("test1", () => {
  expect(calculateDiscount(100, 20)).toBe(80);
  expect(calculateDiscount(50, 100)).toBe(0);
  expect(calculateDiscount(200, 0)).toBe(200);
});
```

## Git Conventions
- Use conventional commit format: `type(scope): description`
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `style`, `perf`
- Write commit messages in English
- Keep the subject line concise (max 72 characters)
- Explain *why* in the commit body when the change is not obvious

```
feat(auth): add token refresh for expired sessions
fix(cart): prevent duplicate items when adding concurrently
refactor(api): extract validation into dedicated middleware
test(user): add edge cases for email validation
```

## Anti-Patterns to Avoid
- Do NOT use `any` type; use `unknown` and narrow with type guards
- Do NOT leave `console.log` in production code; use a proper logger
- Do NOT use magic numbers or strings; extract them into named constants
- Do NOT write comments that restate the code; only explain the *why*
- Do NOT catch errors just to rethrow them without adding context
- Do NOT mix business logic with I/O or framework concerns

## General Principles
- Readability always wins over cleverness
- Code should be self-documenting; add comments only when the "why" is not obvious
- Prefer explicit over implicit behavior
- Rather split code into too many small methods than too few large ones
