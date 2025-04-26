import React, { useState, useEffect, useRef } from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import {
  Home,
  User,
  Bell,
  Settings,
  ShoppingBag,
  DollarSign,
  Store,
  Hash,
  ChevronLeft,
  ChevronRight,
  X,
  Menu,
  Newspaper,
  LogOut,
  Award,
  Zap,
  Smartphone,
  Clock,
  Link as LinkIcon,
  Users,
  FileText,
  Trophy,
  RefreshCw,
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
});

const useApi = () => ({
  get: async (url: string) => {
    if (url === "/bn-logo/") {
      return { data: [{ image: "/logo.png" }] };
    }
    if (url === "/top-contributors/?limit=5") {
      return {
        data: [
          {
            id: 1,
            first_name: "Jane",
            last_name: "Smith",
            profile_image: null,
            post_count: 18,
            follower_count: 85,
          },
          {
            id: 2,
            first_name: "John",
            last_name: "Doe",
            profile_image: null,
            post_count: 25,
            follower_count: 120,
          },
        ],
      };
    }
    return { data: [] };
  },
});

const Sidebar: React.FC = () => {
  const { user } = useAuth();
  const { get } = useApi();
  const router = useRouter();

  const [isMobile, setIsMobile] = useState(false);
  const [burgerMenu, setBurgerMenu] = useState(false);
  const [topContributors, setTopContributors] = useState<any[]>([]);
  const [isLoadingContributors, setIsLoadingContributors] = useState(true);

  const mainMenu = [
    {
      label: "Recent",
      path: "/business-network",
      icon: Home,
    },
    {
      label: "Profile",
      path: `/business-network/profile/${user?.user?.id}`,
      icon: User,
    },
    {
      label: "Notifications",
      path: "/business-network/notifications",
      icon: Bell,
      badge: 5,
    },
    {
      label: "Settings",
      path: "/settings",
      icon: Settings,
    },
  ];

  const mainMenu2 = [
    {
      label: "Recent",
      path: "/business-network",
      icon: Home,
    },
    {
      label: "Login",
      path: `/auth/login`,
      icon: User,
    },
  ];

  const usefulLinks = [
    {
      label: "eShop",
      path: "/eshop",
      icon: ShoppingBag,
    },
    {
      label: "Earn Money",
      path: "/#micro-gigs",
      icon: DollarSign,
    },
    {
      label: "Sell Products",
      path: "/shop-manager",
      icon: Store,
    },
    {
      label: "Mobile Recharge",
      path: "/mobile-recharge",
      icon: Smartphone,
    },
  ];

  const fetchTopContributors = async () => {
    setIsLoadingContributors(true);
    try {
      const response = await get("/top-contributors/?limit=5");
      if (response.data) {
        setTopContributors(
          response.data.map((user: any) => ({
            id: user.id,
            name: user.first_name
              ? `${user.first_name} ${user.last_name || ""}`
              : user.username,
            avatar: user.profile_image,
            posts: user.post_count || 0,
            followers: user.follower_count || 0,
          }))
        );
      }
    } catch (error) {
      console.error("Error fetching contributors:", error);
    } finally {
      setIsLoadingContributors(false);
    }
  };

  const toggleBurgerMenu = () => {
    setBurgerMenu(!burgerMenu);
  };

  const handleResize = () => {
    setIsMobile(window.innerWidth < 1024);
  };

  useEffect(() => {
    handleResize();
    window.addEventListener("resize", handleResize);
    fetchTopContributors();

    return () => {
      window.removeEventListener("resize", handleResize);
    };
  }, []);

  return (
    <div className="rounded-t-sm mt-16">
      {/* Mobile Overlay */}
      {isMobile && burgerMenu && (
        <div
          className="fixed inset-0 bg-black/50 z-40 lg:hidden"
          onClick={toggleBurgerMenu}
        ></div>
      )}

      {/* Sidebar */}
      <aside
        className={`sm:max-h-screen fixed sm:static top-14 bottom-0 pb-16 sm:pb-0 z-50 flex flex-col bg-white border-r border-gray-200 transition-all duration-300 ease-in-out rounded-t-sm ${
          isMobile
            ? burgerMenu
              ? "translate-x-0 w-72"
              : "-translate-x-full"
            : "w-72"
        }`}
      >
        {/* Sidebar Header */}
        <div className="h-12 mt-2 flex items-center justify-between px-4 border-gray-100 relative">
          {burgerMenu && (
            <button
              className="fixed flex top-3 -right-10 lg:hidden h-8 w-8 items-center justify-center rounded-md bg-gray-200 text-gray-500"
              onClick={toggleBurgerMenu}
            >
              <X className="h-5 w-5" />
            </button>
          )}
        </div>

        {/* Sidebar Content */}
        <div className="flex-1 overflow-y-auto py-4 px-2 space-y-7 -mt-12 sm:-mt-10">
          {/* Main Menu Section */}
          <div>
            <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center">
              <Menu className="h-3.5 w-3.5 mr-1.5" />
              <span>Menu</span>
            </h3>
            <nav className="space-y-1">
              {(user?.user?.id ? mainMenu : mainMenu2).map((item) => (
                <Link key={item.path} href={item.path}>
                  <a
                    className={`flex items-center px-3 py-2.5 rounded-md transition-colors group ${
                      router.pathname === item.path
                        ? "bg-blue-50 text-blue-600"
                        : "text-gray-700 hover:bg-gray-50"
                    }`}
                    onClick={toggleBurgerMenu}
                  >
                    <item.icon
                      className={`h-5 w-5 mr-3 ${
                        router.pathname === item.path
                          ? "text-blue-600"
                          : "text-gray-500 group-hover:text-gray-600"
                      }`}
                    />
                    <span className="text-sm font-medium">{item.label}</span>
                    {item.badge && (
                      <div className="ml-auto bg-blue-600 text-white text-xs rounded-full min-w-[20px] h-5 flex items-center justify-center px-1">
                        {item.badge}
                      </div>
                    )}
                  </a>
                </Link>
              ))}
            </nav>
          </div>

          {/* Useful Links Section */}
          <div>
            <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center">
              <LinkIcon className="h-3.5 w-3.5 mr-1.5" />
              <span>Useful Links</span>
            </h3>
            <div className="grid grid-cols-2 gap-2 px-3">
              {usefulLinks.map((item) => (
                <Link key={item.path} href={item.path}>
                  <a className="flex flex-col items-center justify-center p-3 rounded-md bg-gray-50 border border-gray-100 hover:bg-blue-50 hover:border-blue-100 transition-all shadow-sm">
                    <item.icon className="h-5 w-5 mb-2 text-blue-600" />
                    <span className="text-xs font-medium text-gray-700">
                      {item.label}
                    </span>
                  </a>
                </Link>
              ))}
            </div>
          </div>

          {/* Top Contributors Section */}
          <div>
            <h3 className="text-xs font-semibold text-gray-500 uppercase tracking-wider px-3 mb-3 flex items-center justify-between">
              <div className="flex items-center">
                <Users className="h-3.5 w-3.5 mr-1.5" />
                <span>Top Contributors</span>
              </div>
              <Link href="/contributors">
                <a className="text-blue-600 text-xs normal-case font-medium hover:underline flex items-center">
                  <span>Top 100</span>
                  <ChevronRight className="h-3 w-3 ml-0.5" />
                </a>
              </Link>
            </h3>
            <div className="space-y-2">
              {isLoadingContributors ? (
                <div className="flex justify-center items-center h-20 bg-gray-50 rounded-lg">
                  <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
                </div>
              ) : (
                topContributors.map((contributor, index) => (
                  <Link
                    key={contributor.id}
                    href={`/business-network/profile/${contributor.id}`}
                  >
                    <a className="flex items-center px-3 py-2 rounded-md hover:bg-gray-50 transition-colors">
                      <div className="relative">
                        <img
                          src={
                            contributor.avatar ||
                            "/static/frontend/images/placeholder.jpg"
                          }
                          alt={contributor.name}
                          className="h-10 w-10 rounded-full object-cover border-2 border-white shadow-sm"
                        />
                        <div className="absolute -top-1 -right-1 bg-blue-600 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center border border-white">
                          {index + 1}
                        </div>
                      </div>
                      <div className="ml-3 min-w-0">
                        <h4 className="text-sm font-medium text-gray-800 truncate">
                          {contributor.name}
                        </h4>
                        <p className="text-xs text-gray-500 flex items-center">
                          <FileText className="h-3 w-3 mr-1" />
                          <span>{contributor.posts} posts</span>
                          <Users className="h-3 w-3 mx-1" />
                          <span>{contributor.followers}</span>
                        </p>
                      </div>
                      <div className="ml-auto">
                        <div className="text-xs px-1.5 py-0.5 bg-blue-50 text-blue-600 rounded-md border border-blue-100">
                          <Trophy className="h-3 w-3" />
                        </div>
                      </div>
                    </a>
                  </Link>
                ))
              )}
            </div>
          </div>
        </div>
      </aside>
    </div>
  );
};

export default Sidebar;