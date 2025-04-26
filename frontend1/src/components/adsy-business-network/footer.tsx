import React from "react";
import Link from "next/link";
import { useRouter } from "next/router";
import {
  BarChart2,
  Bell,
  Clock,
  Newspaper,
  User,
} from "lucide-react";

// Simulated useAuth hook (replace with your actual implementation)
const useAuth = () => {
  return {
    user: {
      user: {
        id: "123", // Replace with dynamic user ID
      },
    },
  };
};

const Footer: React.FC = () => {
  const { user } = useAuth();
  const router = useRouter();

  const isActive = (path: string) => router.pathname === path;

  return (
    <div className="md:hidden fixed bottom-0 left-0 right-0 bg-white border-t border-gray-200 z-50 shadow-lg">
      {user?.user?.id ? (
        <div className="flex justify-between items-center px-2">
          <Link href="/business-network">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/business-network")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <Clock
                  className={`h-6 w-6 mb-1 ${
                    isActive("/business-network")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Recent</span>
            </a>
          </Link>
          <Link href="/business-network/notifications">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/business-network/notifications")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <Bell
                  className={`h-6 w-6 mb-1 ${
                    isActive("/business-network/notifications")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
                <span className="absolute -top-1 -right-1 bg-blue-600 text-white text-[10px] rounded-full min-w-[16px] h-4 flex items-center justify-center px-1">
                  5
                </span>
              </div>
              <span>Notifications</span>
            </a>
          </Link>
          <Link href={`/business-network/profile/${user?.user?.id}`}>
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive(`/business-network/profile/${user?.user?.id}`)
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <User
                  className={`h-6 w-6 mb-1 ${
                    isActive(`/business-network/profile/${user?.user?.id}`)
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Profile</span>
            </a>
          </Link>
          <Link href="/">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <BarChart2
                  className={`h-6 w-6 mb-1 ${
                    isActive("/") ? "text-blue-600" : "text-gray-500"
                  }`}
                />
              </div>
              <span>Adsy Club</span>
            </a>
          </Link>
          <Link href="/adsy-news">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/adsy-news")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <Newspaper
                  className={`h-6 w-6 mb-1 ${
                    isActive("/adsy-news")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Adsy News</span>
            </a>
          </Link>
        </div>
      ) : (
        <div className="flex justify-between items-center px-2">
          <Link href="/business-network">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/business-network")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <Clock
                  className={`h-6 w-6 mb-1 ${
                    isActive("/business-network")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Recent</span>
            </a>
          </Link>
          <Link href="/auth/login">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/auth/login")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <i
                  className={`i-ic-sharp-person h-6 w-6 mb-1 ${
                    isActive("/auth/login")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Login</span>
            </a>
          </Link>
          <Link href="/#micro-gigs">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/#micro-gigs")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <i
                  className={`i-material-symbols-attach-money h-6 w-6 mb-1 ${
                    isActive("/#micro-gigs")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Earn</span>
            </a>
          </Link>
          <Link href="/">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <BarChart2
                  className={`h-6 w-6 mb-1 ${
                    isActive("/") ? "text-blue-600" : "text-gray-500"
                  }`}
                />
              </div>
              <span>Adsy Club</span>
            </a>
          </Link>
          <Link href="/adsy-news">
            <a
              className={`flex flex-col items-center py-3 px-3 text-xs relative ${
                isActive("/adsy-news")
                  ? "text-blue-600 after:absolute after:bottom-0 after:left-0 after:right-0 after:h-0.5 after:bg-blue-600"
                  : "text-gray-500"
              }`}
            >
              <div className="relative">
                <Newspaper
                  className={`h-6 w-6 mb-1 ${
                    isActive("/adsy-news")
                      ? "text-blue-600"
                      : "text-gray-500"
                  }`}
                />
              </div>
              <span>Adsy News</span>
            </a>
          </Link>
        </div>
      )}
    </div>
  );
};

export default Footer;