const ENTITY_MAP: Record<string, string> = {
  amp: "&",
  lt: "<",
  gt: ">",
  quot: '"',
  apos: "'",
  nbsp: " ",
};

const decodeHtmlEntities = (value: string): string => {
  return value.replace(/&(#(?:x[\da-f]+|\d+)|[a-z]+);/gi, (entity, code) => {
    if (code.startsWith("#x")) {
      const parsed = Number.parseInt(code.slice(2), 16);
      return Number.isNaN(parsed) ? entity : String.fromCodePoint(parsed);
    }

    if (code.startsWith("#")) {
      const parsed = Number.parseInt(code.slice(1), 10);
      return Number.isNaN(parsed) ? entity : String.fromCodePoint(parsed);
    }

    return ENTITY_MAP[code.toLowerCase()] ?? entity;
  });
};

const decodeRichText = (value: string): string => {
  let decoded = value;

  for (let index = 0; index < 3; index += 1) {
    const nextValue = decodeHtmlEntities(decoded);

    if (nextValue === decoded) {
      break;
    }

    decoded = nextValue;
  }

  return decoded;
};

const escapeHtml = (value: string): string => {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/\"/g, "&quot;")
    .replace(/'/g, "&#39;");
};

export const useRichText = () => {
  const toPlainText = (value: unknown, fallback = ""): string => {
    const normalizedValue = decodeRichText(String(value ?? ""))
      .replace(/<\s*br\s*\/?>/gi, "\n")
      .replace(/<\s*\/\s*(p|div|li|ul|ol|h[1-6]|blockquote|section|article|tr)>/gi, "\n")
      .replace(/<\s*li\b[^>]*>/gi, "- ")
      .replace(/<[^>]+>/g, " ")
      .replace(/\u00a0/g, " ");

    const collapsedValue = normalizedValue
      .split("\n")
      .map((line) => line.replace(/\s+/g, " ").trim())
      .filter(Boolean)
      .join("\n")
      .trim();

    return collapsedValue || fallback;
  };

  const renderRichText = (value: unknown, fallback = ""): string => {
    const normalizedValue = decodeRichText(String(value ?? "")).trim();

    if (!normalizedValue) {
      return fallback ? escapeHtml(fallback) : "";
    }

    if (/<[a-z][\s\S]*>/i.test(normalizedValue)) {
      return normalizedValue;
    }

    return escapeHtml(normalizedValue).replace(/\n/g, "<br>");
  };

  const previewText = (
    value: unknown,
    maxLength: number,
    fallback = ""
  ): string => {
    const plainText = toPlainText(value, fallback);

    if (!plainText || plainText.length <= maxLength) {
      return plainText;
    }

    return `${plainText.slice(0, maxLength).trimEnd()}...`;
  };

  return {
    previewText,
    renderRichText,
    toPlainText,
  };
};