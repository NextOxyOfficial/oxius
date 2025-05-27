// i18n error handling plugin
export default defineNuxtPlugin(({ $i18n }) => {
  // Store a reference to the original translate method
  const originalT = $i18n.t;

  // Create a wrapped function that handles missing keys gracefully
  $i18n.t = function (key, ...args) {
    try {
      const result = originalT.call($i18n, key, ...args);

      // Check if the result is the same as the key (indicating a missing translation)
      if (result === key) {
        console.warn(`Missing translation for key: ${key}`);
        // Return a fallback if the key exists in another locale
        const fallbackResult = checkFallbackLocales(key);
        return fallbackResult || key;
      }

      return result;
    } catch (error) {
      console.error(`Error translating key '${key}':`, error);
      return key; // Return the key as a fallback
    }
  };

  // Helper function to check for translations in other locales
  function checkFallbackLocales(key) {
    const currentLocale = $i18n.locale.value;
    const availableLocales = $i18n.availableLocales;

    for (const locale of availableLocales) {
      if (locale === currentLocale) continue;

      // Try getting the translation from other locales
      try {
        const messages = $i18n.messages.value[locale];
        if (messages) {
          // Navigate the nested message structure using the key path
          const keyPath = key.split(".");
          let result = messages;

          for (const k of keyPath) {
            if (result && typeof result === "object" && k in result) {
              result = result[k];
            } else {
              result = null;
              break;
            }
          }

          if (result && typeof result === "string") {
            console.info(
              `Found fallback translation for '${key}' in locale '${locale}'`
            );
            return result;
          }
        }
      } catch (e) {
        // Ignore errors in fallback checking
      }
    }

    return null;
  }
});
