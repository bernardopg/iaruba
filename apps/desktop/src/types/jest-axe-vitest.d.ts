// Vitest 5 moved the `Assertion` interface used by `expect()`, and the legacy
// `@types/jest-axe` augmentation targets the old `jest.Matchers` namespace,
// which no longer reaches it. Augment the Vitest `Assertion` directly so
// `expect(await axe(...)).toHaveNoViolations()` typechecks again.
import type { AxeResults } from "axe-core";

declare module "vitest" {
  interface Assertion<T = any> {
    toHaveNoViolations(): void;
  }
}
