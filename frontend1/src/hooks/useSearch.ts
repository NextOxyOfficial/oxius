import { useState } from 'react';

export function useSearch() {
  const [recentSearches, setRecentSearches] = useState<string[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Get recent searches from localStorage
  const getRecentSearches = async () => {
    setLoading(true);

    try {
      // In a real app, this might come from an API
      const searches = localStorage.getItem("recentSearches");
      const searchData = searches
        ? JSON.parse(searches)
        : [
            "Marketing Strategy",
            "Business Development",
            "Networking Events",
            "Leadership Training",
          ];
      
      setRecentSearches(searchData);
      return searchData;
    } catch (err: any) {
      const errorMsg = err.message || "Failed to load recent searches";
      setError(errorMsg);
      return [];
    } finally {
      setLoading(false);
    }
  };

  // Save a search term to recent searches
  const saveRecentSearch = (term: string) => {
    if (!term.trim()) return;

    try {
      // Remove if already exists
      const updatedSearches = [...recentSearches];
      const index = updatedSearches.indexOf(term);
      if (index !== -1) {
        updatedSearches.splice(index, 1);
      }

      // Add to beginning of array
      const newSearches = [term, ...updatedSearches.slice(0, 4)];
      setRecentSearches(newSearches);

      // Save to localStorage
      localStorage.setItem("recentSearches", JSON.stringify(newSearches));
    } catch (err: any) {
      setError(err.message || "Failed to save recent search");
    }
  };

  // Clear recent searches
  const clearRecentSearches = () => {
    try {
      setRecentSearches([]);
      localStorage.removeItem("recentSearches");
    } catch (err: any) {
      setError(err.message || "Failed to clear recent searches");
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