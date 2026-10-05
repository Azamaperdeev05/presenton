export function isTruthyAuthValue(value?: string | null): boolean {
  if (value === undefined || value === null) {
    return true;
  }
  const raw = value.trim().toLowerCase();
  return raw === "1" || raw === "true" || raw === "yes" || raw === "on";
}

export function getDisableAuthValue(): string | undefined {
  if (typeof window !== "undefined") {
    if (window.env?.DISABLE_AUTH !== undefined) {
      return window.env.DISABLE_AUTH;
    }
    if (window.env?.NEXT_PUBLIC_DISABLE_AUTH !== undefined) {
      return window.env.NEXT_PUBLIC_DISABLE_AUTH;
    }
  }

  if (typeof process !== "undefined") {
    if (process.env.NEXT_PUBLIC_DISABLE_AUTH !== undefined) {
      return process.env.NEXT_PUBLIC_DISABLE_AUTH;
    }
    if (process.env.DISABLE_AUTH !== undefined) {
      return process.env.DISABLE_AUTH;
    }
  }

  return "true";
}

export function isAuthDisabled(): boolean {
  return isTruthyAuthValue(getDisableAuthValue());
}
