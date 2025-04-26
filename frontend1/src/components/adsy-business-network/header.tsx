import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import {
  SunIcon,
  MenuIcon,
  XIcon,
  SearchIcon,
  ChevronLeftIcon,
  ChevronRightIcon,
  Newspaper,
  BarChart2,
} from "lucide-react";

// Simulated hooks (replace with actual implementations)
const useAuth = () => ({
  user: {
    user: {
      id: "123",
      is_pro: true,
      kyc: true,
      first_name: "John",
      pro_validity: "2025-12-31",
    },
  },
  logout: () => console.log("Logged out"),
});

const useApi = () => ({
  get: async (url: string) => {
    if (url === "/bn-logo/") {
      return { data: [{ image: "/logo.png" }] };
    }
    return { data: [] };
  },
});

const Header: React.FC = () => {
  const { user, logout } = useAuth();
  const { get } = useApi();
  const router = useRouter();

  const [logo, setLogo] = useState<{ image: string }[]>([]);
  const [openMenu, setOpenMenu] = useState(false);
  const [showSearchDropdown, setShowSearchDropdown] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");
  const [searchResults, setSearchResults] = useState<any[]>([]);

  const searchInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    const fetchLogo = async () => {
      const { data } = await get("/bn-logo/");
      setLogo(data);
    };
    fetchLogo();
  }, [get]);

  const toggleSearchDropdown = () => {
    setShowSearchDropdown(!showSearchDropdown);
    if (!showSearchDropdown) {
      setTimeout(() => searchInputRef.current?.focus(), 0);
    }
  };

  const handleClickOutside = (event: MouseEvent) => {
    const searchDropdown = document.querySelector(".search-dropdown-container");
    const searchButton = document.querySelector(".search-button-container");

    if (
      searchDropdown &&
      !searchDropdown.contains(event.target as Node) &&
      searchButton &&
      !searchButton.contains(event.target as Node)
    ) {
      setShowSearchDropdown(false);
    }
  };

  useEffect(() => {
    document.addEventListener("click", handleClickOutside);
    return () => {
      document.removeEventListener("click", handleClickOutside);
    };
  }, []);

  const upgradeToPro = () => {
    setOpenMenu(false);
    router.push("/upgrade-to-pro");
  };

  const manageSubscription = () => {
    setOpenMenu(false);
    router.push("/account/subscription");
  };

  const formatDate = (date: string) => {
    return new Date(date).toLocaleDateString(undefined, {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  };

  return (
    <div className="fixed top-0 left-0 right-0 z-50 w-full mx-auto">
      <header className="backdrop-blur-sm bg-white/95 dark:bg-gray-900/95 shadow-sm">
        <div className="max-w-5xl mx-auto px-3 sm:px-4">
          <div className="flex items-center justify-between h-16 sm:h-18">
            {/* Left Section: Sidebar Toggle + Logo */}
            <div className="flex items-center sm:gap-5">
              {/* Sidebar Toggle Button */}
              <button
                onClick={() => console.log("Toggle Sidebar")}
                className="flex sm:hidden group relative h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-gray-50 dark:bg-gray-800 hover:bg-gray-100 dark:hover:bg-gray-700 transition-all"
                aria-label="Toggle sidebar"
              >
                <div className="flex flex-col justify-center items-center w-5 space-y-1.5 transform transition-all duration-300">
                  <span className="block h-0.5 w-5 bg-gray-600 dark:bg-gray-300 transform transition-all duration-300 group-hover:bg-blue-600 dark:group-hover:bg-blue-400"></span>
                  <span className="block h-0.5 w-3.5 bg-gray-600 dark:bg-gray-300 transform transition-all duration-300 group-hover:bg-blue-600 dark:group-hover:bg-blue-400 group-hover:w-5"></span>
                  <span className="block h-0.5 w-5 bg-gray-600 dark:bg-gray-300 transform transition-all duration-300 group-hover:bg-blue-600 dark:group-hover:bg-blue-400"></span>
                </div>
              </button>

              {/* Logo */}
              <Link href="/business-network/">
                <a
                  className="flex items-center overflow-hidden transform hover:scale-[1.02] transition-transform duration-300"
                  aria-label="Logo"
                >
                  <div className="relative">
                    {logo[0]?.image && (
                      <img
                        src={logo[0].image}
                        alt="Adsy Logo"
                        width="150"
                        height="50"
                        className="h-8 sm:h-10 w-auto object-contain"
                        loading="eager"
                      />
                    )}
                    <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/20 to-transparent opacity-0 hover:opacity-100 -translate-x-full hover:translate-x-full transition-all duration-1000 ease-in-out"></div>
                  </div>
                </a>
              </Link>
            </div>

            {/* Right Section: Search + Navigation + User Menu */}
            <div className="flex items-center gap-1 sm:gap-3">
              {/* Search Button */}
              <div className="relative search-button-container">
                <button
                  className="flex items-center justify-center h-9 w-9 rounded-full hover:bg-gray-100 dark:hover:bg-gray-800 transition-colors group"
                  onClick={toggleSearchDropdown}
                  aria-label="Search"
                >
                  <SearchIcon className="h-[18px] w-[18px] text-gray-600 dark:text-gray-300 group-hover:text-blue-600 dark:group-hover:text-blue-400 transition-colors" />
                </button>

                {/* Search Dropdown */}
                {showSearchDropdown && (
                  <div className="absolute top-full right-0 mt-2 w-72 sm:w-80 bg-white dark:bg-gray-800 rounded-xl shadow-xl border border-gray-200 dark:border-gray-700 overflow-hidden z-50 search-dropdown-container">
                    <div className="p-3 border-b border-gray-200 dark:border-gray-700">
                      <div className="relative">
                        <input
                          type="text"
                          placeholder="Search topics..."
                          value={searchQuery}
                          onChange={(e) => setSearchQuery(e.target.value)}
                          className="w-full pl-9 pr-8 py-2.5 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/50 dark:focus:ring-blue-500/70 border border-gray-200 dark:border-gray-700 bg-gray-50 dark:bg-gray-900 text-gray-800 dark:text-gray-200 transition-all duration-300 search-input"
                          ref={searchInputRef}
                        />
                        <SearchIcon className="absolute left-3 top-2.5 h-4 w-4 text-gray-500 dark:text-gray-400" />
                        {searchQuery && (
                          <button
                            onClick={() => setSearchQuery("")}
                            className="absolute right-2.5 top-2.5 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 p-1 transition-colors"
                          >
                            <XIcon className="h-3.5 w-3.5 text-gray-500 dark:text-gray-400" />
                          </button>
                        )}
                      </div>
                    </div>
                    {/* Search Results */}
                    {searchQuery && searchResults.length > 0 ? (
                      <div className="divide-y divide-gray-100 dark:divide-gray-800 max-h-80 overflow-y-auto">
                        {searchResults.map((result) => (
                          <div
                            key={result.id}
                            className="p-3 hover:bg-gray-50 dark:hover:bg-gray-700/50 cursor-pointer transition-colors duration-150"
                            onClick={() => console.log("Selected:", result)}
                          >
                            <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                              {result.title}
                            </p>
                            <p className="text-xs text-gray-500 dark:text-gray-400 mt-1">
                              <span className="bg-blue-50 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 px-2 py-0.5 rounded-full text-xs">
                                {result.category}
                              </span>
                            </p>
                          </div>
                        ))}
                      </div>
                    ) : searchQuery ? (
                      <div className="p-4 text-center text-gray-500 dark:text-gray-400">
                        No results found for "{searchQuery}"
                      </div>
                    ) : (
                      <div className="p-4 text-center">
                        <div className="text-gray-400 dark:text-gray-500 mb-2">
                          <SearchIcon className="h-5 w-5 mx-auto mb-2" />
                          Type to start searching...
                        </div>
                        <div className="text-xs text-gray-500 dark:text-gray-500">
                          Press ESC to close
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>

              {/* User Menu */}
              <button
                onClick={() => setOpenMenu(!openMenu)}
                className="flex items-center gap-2 py-2 px-3 rounded-lg text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700/50 transition-colors"
              >
                {user?.user?.is_pro && (
                  <span className="text-xs px-2 py-0.5 bg-gradient-to-r from-indigo-500 to-blue-600 text-white rounded-full font-medium shadow-sm">
                    Pro
                  </span>
                )}
                <span>Hi {user?.user?.first_name.slice(0, 8)}</span>
              </button>
            </div>
          </div>
        </div>
      </header>
    </div>
  );
};

export default Header;