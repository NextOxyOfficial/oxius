import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import {
  Search,
  X,
  Calendar,
  Globe,
  BarChart2,
  ChevronDown,
  ChevronRight,
} from "lucide-react";

const Header: React.FC = () => {
  const router = useRouter();

  // State management
  const [logo, setLogo] = useState<string | null>(null);
  const [categories, setCategories] = useState<any[]>([]);
  const [activeCategory, setActiveCategory] = useState<string>("all");
  const [moreMenuOpen, setMoreMenuOpen] = useState(false);
  const [isSearchVisible, setIsSearchVisible] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [breakingNews, setBreakingNews] = useState<string[]>([]);

  const searchInputRef = useRef<HTMLInputElement>(null);

  // Fetch logo
  useEffect(() => {
    const fetchLogo = async () => {
      const response = await fetch("/api/news-logo");
      const data = await response.json();
      setLogo(data?.image || null);
    };
    fetchLogo();
  }, []);

  // Fetch categories
  useEffect(() => {
    const fetchCategories = async () => {
      const response = await fetch("/api/news/categories");
      const data = await response.json();
      setCategories(data?.results || []);
    };
    fetchCategories();
  }, []);

  // Fetch breaking news
  useEffect(() => {
    const fetchBreakingNews = async () => {
      const response = await fetch("/api/news/breaking-news");
      const data = await response.json();
      setBreakingNews(data?.map((news: any) => news.title) || []);
    };
    fetchBreakingNews();
  }, []);

  // Handle search input
  const handleSearchInput = async () => {
    if (!searchQuery.trim()) {
      setSearchResults([]);
      return;
    }
    setIsSearching(true);
    try {
      const response = await fetch(
        `/api/news/posts?search=${encodeURIComponent(searchQuery.trim())}`
      );
      const data = await response.json();
      setSearchResults(data?.results || []);
    } catch (error) {
      console.error("Error fetching search results:", error);
      setSearchResults([]);
    } finally {
      setIsSearching(false);
    }
  };

  // Clear search
  const clearSearch = () => {
    setSearchQuery("");
    setSearchResults([]);
  };

  // Navigate to article
  const navigateToArticle = (article: any) => {
    clearSearch();
    setIsSearchVisible(false);
    router.push(`/adsy-news/${article.slug}`);
  };

  // Format date
  const formatDate = (dateString: string) => {
    return new Date(dateString).toLocaleDateString("en-US", {
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  };

  return (
    <div>
      <header className="sticky top-0 z-50 bg-white shadow-md">
        <div className="max-w-7xl mx-auto">
          {/* Main Navigation */}
          <div className="flex items-center justify-between px-4 py-3 sm:py-4 lg:py-5 sm:px-6 lg:px-8">
            {/* Logo */}
            <Link href="/adsy-news">
              <a className="flex-shrink-0 mr-3">
                {logo && (
                  <img
                    src={logo}
                    alt="Adsy News Logo"
                    width="120"
                    height="40"
                    className="h-6 sm:h-8 w-auto object-contain"
                  />
                )}
              </a>
            </Link>

            {/* Desktop Nav Categories */}
            <nav className="hidden md:flex flex-1 justify-center space-x-4 lg:space-x-8">
              {categories.slice(0, 4).map((category) => (
                <Link key={category.id} href={`/adsy-news/categories/${category.slug}`}>
                  <a
                    className={`text-sm font-medium hover:text-primary transition-colors duration-200 py-1 ${
                      activeCategory === category.id
                        ? "text-primary border-b-2 border-primary"
                        : "text-gray-800"
                    }`}
                  >
                    {category.name}
                  </a>
                </Link>
              ))}
              {categories.length > 4 && (
                <div className="relative">
                  <button
                    onClick={() => setMoreMenuOpen(!moreMenuOpen)}
                    className="flex items-center text-sm font-medium text-gray-800 hover:text-primary transition-colors duration-200 py-1"
                  >
                    More
                    <ChevronDown className="ml-1" />
                  </button>
                  {moreMenuOpen && (
                    <div className="absolute top-full right-0 mt-1 bg-white shadow-lg rounded-md py-2 z-50 w-48 overflow-y-auto border border-gray-200">
                      {categories.slice(4).map((category) => (
                        <Link
                          key={category.id}
                          href={`/adsy-news/categories/${category.slug}`}
                        >
                          <a
                            className={`block px-4 py-2 text-sm hover:bg-gray-100 transition-colors ${
                              activeCategory === category.id
                                ? "text-primary"
                                : "text-gray-800"
                            }`}
                          >
                            {category.name}
                          </a>
                        </Link>
                      ))}
                    </div>
                  )}
                </div>
              )}
            </nav>

            {/* Right Side Actions */}
            <div className="flex items-center space-x-1.5 sm:space-x-3">
              {/* Search Icon */}
              <button
                onClick={() => setIsSearchVisible(!isSearchVisible)}
                className="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 text-gray-600 transition-colors"
                aria-label="Search"
              >
                <Search className="h-5 w-5" />
              </button>

              {/* Navigation Buttons */}
              <Link href="/">
                <a className="flex items-center gap-1.5 px-2.5 py-1.5 sm:px-3 sm:py-2 rounded-full text-xs sm:text-sm font-medium text-white bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-700 hover:to-indigo-800 transition-all">
                  <BarChart2 className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
                  <span>AdsyClub</span>
                </a>
              </Link>
              <Link href="/business-network">
                <a className="flex items-center gap-1.5 px-2.5 py-1.5 sm:px-3 sm:py-2 rounded-full text-xs sm:text-sm font-medium text-white bg-gradient-to-r from-amber-500 to-orange-600 hover:from-amber-600 hover:to-orange-700 transition-all">
                  <Globe className="h-3.5 w-3.5 sm:h-4 sm:w-4" />
                  <span>Adsy BN</span>
                </a>
              </Link>
            </div>
          </div>

          {/* Breaking News Ticker */}
          <div className="bg-primary text-white py-2.5 px-4 sm:px-6 rounded-lg shadow-md mt-3 mb-6 sm:mb-8">
            <div className="flex items-center">
              <div className="flex-shrink-0">
                <span className="font-semibold text-xs sm:text-base mr-3 sm:mr-4 border-r border-white/30 pr-3 sm:pr-4">
                  BREAKING
                </span>
              </div>
              <div className="overflow-hidden relative w-full">
                <div className="flex whitespace-nowrap animate-ticker">
                  {breakingNews.map((news, index) => (
                    <p
                      key={index}
                      className="ticker-item px-4 capitalize text-sm sm:text-base"
                    >
                      {news}
                    </p>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      </header>

      {/* Search Overlay */}
      {isSearchVisible && (
        <div
          className="fixed inset-0 bg-black/20 backdrop-blur-sm z-50 flex items-start justify-center pt-20 px-4 sm:px-0"
          onClick={() => setIsSearchVisible(false)}
        >
          <div
            className="bg-white rounded-lg shadow-xl w-full max-w-lg transform transition-all duration-300 overflow-hidden"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="p-4 border-b border-gray-100">
              <div className="relative">
                <Search className="h-5 w-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400" />
                <input
                  type="text"
                  placeholder="Search news articles..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  onInput={handleSearchInput}
                  className="w-full pl-10 pr-4 py-2.5 border border-gray-300 rounded-full text-sm focus:outline-none focus:ring-2 focus:ring-primary focus:border-transparent bg-gray-50 text-gray-800"
                  ref={searchInputRef}
                />
                {searchQuery && (
                  <button
                    onClick={clearSearch}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 text-gray-400 hover:text-gray-600"
                  >
                    <X className="h-4 w-4" />
                  </button>
                )}
              </div>
            </div>

            <div className="divide-y divide-gray-100 max-h-[60vh] overflow-y-auto">
              {searchQuery && searchResults.length > 0 ? (
                searchResults.map((result) => (
                  <div
                    key={result.id}
                    className="p-4 hover:bg-gray-50 cursor-pointer transition-colors"
                    onClick={() => navigateToArticle(result)}
                  >
                    <p className="font-medium text-gray-800 line-clamp-2 mb-1">
                      {result.title}
                    </p>
                    <div className="flex items-center text-xs text-gray-500">
                      <Calendar className="h-3 w-3 mr-1" />
                      {formatDate(result.created_at)}
                      <span className="mx-2">•</span>
                      <span className="bg-primary/10 text-primary px-2 py-0.5 rounded-full text-xs capitalize">
                        {result.categories?.[0]?.title || "News"}
                      </span>
                    </div>
                  </div>
                ))
              ) : isSearching ? (
                <div className="p-6 text-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-t-2 border-b-2 border-primary mx-auto"></div>
                  <p className="mt-4 text-gray-500">Searching...</p>
                </div>
              ) : (
                <div className="p-6 text-center text-gray-500">
                  <Search className="mx-auto h-8 w-8 text-gray-300 mb-2" />
                  <p>Type to start searching</p>
                  <p className="text-xs mt-1">Press ESC to close</p>
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Header;