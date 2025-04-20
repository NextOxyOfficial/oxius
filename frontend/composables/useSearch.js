export function useSearch() {
  const recentSearches = ref([]);
  const loading = ref(false);
  const error = ref(null);

  // Get recent searches from localStorage
  const getRecentSearches = async () => {
    loading.value = true;

    try {
      // In a real app, this might come from an API
      const searches = localStorage.getItem("recentSearches");
      recentSearches.value = searches
        ? JSON.parse(searches)
        : [
            "Marketing Strategy",
            "Business Development",
            "Networking Events",
            "Leadership Training",
          ];

      return recentSearches.value;
    } catch (err) {
      error.value = err.message || "Failed to load recent searches";
      return [];
    } finally {
      loading.value = false;
    }
  };

  // Save a search term to recent searches
  const saveRecentSearch = (term) => {
    if (!term.trim()) return;

    try {
      // Remove if already exists
      const index = recentSearches.value.indexOf(term);
      if (index !== -1) {
        recentSearches.value.splice(index, 1);
      }

      // Add to beginning of array
      recentSearches.value = [term, ...recentSearches.value.slice(0, 4)];

      // Save to localStorage
      localStorage.setItem(
        "recentSearches",
        JSON.stringify(recentSearches.value)
      );
    } catch (err) {
      error.value = err.message || "Failed to save recent search";
    }
  };

  // Clear recent searches
  const clearRecentSearches = () => {
    try {
      recentSearches.value = [];
      localStorage.removeItem("recentSearches");
    } catch (err) {
      error.value = err.message || "Failed to clear recent searches";
    }
  };

  return {
    recentSearches,
    loading,
    error,
    getRecentSearches,
    saveRecentSearch,
    clearRecentSearches,
  };
}
