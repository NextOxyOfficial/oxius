import React from "react";
import { useRouter } from "next/router";
import { useAuth } from "@/hooks/useAuth"; // Replace with your actual auth hook
import { useToast } from "@/hooks/useToast"; // Replace with your actual toast hook
import Link from "next/link";
import {
  CurrencyDollar,
  Eye,
  List,
  PlusCircle,
  UserGroup,
  Copy,
  CheckCircle,
} from "lucide-react";

const Balance: React.FC = () => {
  const { user } = useAuth();
  const toast = useToast();
  const router = useRouter();

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    toast.add({
      title: "Link copied",
      color: "emerald",
      icon: <CheckCircle className="h-5 w-5" />,
    });
  };

  if (!user?.user) return null;

  return (
    <div className="md:max-w-4xl mx-auto mb-4 sm:mb-8 overflow-hidden transition-all duration-500 hover:shadow-sm bg-gradient-to-br from-green-100 to-teal-100/60 border border-dashed border-emerald-400/70 rounded-2xl">
      {/* Decorative Elements */}
      <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-100/30 rounded-full blur-2xl -z-10"></div>
      <div className="absolute bottom-0 left-0 w-40 h-40 bg-teal-300/10 rounded-full blur-2xl -z-10"></div>

      {/* Header with Balance Info */}
      <div className="relative p-4 sm:p-6 overflow-hidden">
        <div className="flex flex-col md:flex-row justify-between gap-4 sm:gap-6">
          {/* Main Balance */}
          <div className="balance-container group bg-white rounded-xl p-4 shadow-md hover:shadow-md transition-all duration-300 border border-emerald-300">
            <div className="flex items-center gap-3">
              <div className="flex-shrink-0 w-12 h-12 rounded-full bg-gradient-to-br from-emerald-500 to-teal-500 flex items-center justify-center shadow-md">
                <CurrencyDollar className="text-white text-xl" />
              </div>
              <div>
                <p className="text-sm text-emerald-700 font-medium">Balance</p>
                <h3 className="text-2xl font-bold text-emerald-900 flex items-center gap-1 group-hover:scale-105 transition-transform duration-300">
                  <CurrencyDollar className="text-2xl text-emerald-600" />
                  <span className="balance-value">{user.user.balance}</span>
                </h3>
              </div>
            </div>
          </div>

          {/* Pending Tasks */}
          <div className="pending-container group bg-white rounded-xl p-4 shadow-md hover:shadow-md transition-all duration-300 border border-amber-200">
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="flex-shrink-0 w-12 h-12 rounded-full bg-gradient-to-br from-amber-400 to-orange-400 flex items-center justify-center shadow-md">
                  <Eye className="text-white text-xl" />
                </div>
                <div>
                  <p className="text-sm text-amber-700 font-medium">
                    Pending Tasks
                  </p>
                  <h3 className="text-2xl font-bold text-amber-900 flex items-center gap-1 group-hover:scale-105 transition-transform duration-300">
                    <CurrencyDollar className="text-2xl text-amber-600" />
                    <span className="pending-value">
                      {user.user.pending_balance}
                    </span>
                  </h3>
                </div>
              </div>
              <Link href={`/pending-tasks/${user.user.id}`}>
                <a className="ml-2 hover:scale-105 transition-transform duration-300 text-amber-600">
                  <Eye className="h-5 w-5" />
                </a>
              </Link>
            </div>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3 mt-6">
          <Link href="/deposit-withdraw/">
            <a className="action-button justify-center py-3 rounded-xl shadow-md hover:shadow-md transition-all duration-300 hover:scale-102 bg-gradient-to-r from-emerald-500/10 to-emerald-500/5 text-emerald-700 font-medium flex items-center gap-2">
              <CurrencyDollar className="h-5 w-5" />
              Deposit/Withdraw
            </a>
          </Link>
          <Link href="/inbox/">
            <a className="action-button justify-center py-3 rounded-xl shadow-md hover:shadow-md transition-all duration-300 hover:scale-102 bg-gradient-to-r from-blue-500/10 to-blue-500/5 text-blue-700 font-medium flex items-center gap-2">
              <Eye className="h-5 w-5" />
              Inbox
            </a>
          </Link>
          <Link href={`/my-gigs/${user.user.id}`}>
            <a className="action-button justify-center py-3 rounded-xl shadow-md hover:shadow-md transition-all duration-300 hover:scale-102 bg-gradient-to-r from-violet-500/10 to-violet-500/5 text-violet-700 font-medium flex items-center gap-2">
              <List className="h-5 w-5" />
              My Gigs
            </a>
          </Link>
          <Link href="/post-a-gig">
            <a className="action-button justify-center py-3 rounded-xl shadow-md hover:shadow-md transition-all duration-300 hover:scale-102 bg-gradient-to-r from-slate-500/10 to-slate-500/5 text-slate-700 font-medium flex items-center gap-2">
              <PlusCircle className="h-5 w-5" />
              Post Gigs
            </a>
          </Link>
        </div>
      </div>

      {/* Referral Section */}
      <div className="p-4 sm:p-6 bg-gradient-to-br from-white/50 to-emerald-50/50">
        <div className="flex flex-col gap-4">
          <div className="text-center w-full flex flex-col items-center gap-3">
            <h3 className="text-xl font-bold text-emerald-800 flex items-center gap-2">
              <UserGroup className="text-emerald-600" />
              Refer
            </h3>
            <div className="relative w-full max-w-md mx-auto group">
              <div className="absolute -inset-0.5 bg-gradient-to-r from-emerald-500 to-teal-500 rounded-lg blur opacity-30 group-hover:opacity-70 transition duration-1000 group-hover:duration-200"></div>
              <div className="relative flex items-center bg-white rounded-lg overflow-hidden shadow-md">
                <input
                  type="text"
                  className="text-sm py-3 px-4 w-full bg-transparent border-0 focus:ring-0 focus:outline-none text-slate-700"
                  readOnly
                  value={`https://adsyclub.com/auth/register/?ref=${user.user.referral_code}`}
                />
                <button
                  onClick={() =>
                    copyToClipboard(
                      `https://adsyclub.com/auth/register/?ref=${user.user.referral_code}`
                    )
                  }
                  className="m-1 hover:scale-105 transition-transform duration-300 text-emerald-600"
                >
                  <Copy className="h-5 w-5" />
                </button>
              </div>
            </div>
          </div>

          {/* Referral Stats */}
          <div className="flex gap-6 justify-center items-center bg-white/80 rounded-xl p-3 shadow-xs">
            <div className="flex flex-col items-center">
              <p className="text-sm text-slate-500">Referred Users</p>
              <p className="text-xl font-bold text-emerald-700">
                {user.user.refer_count}
              </p>
            </div>
            <div className="h-10 w-px bg-slate-200"></div>
            <div className="flex flex-col items-center">
              <p className="text-sm text-slate-500">Earnings</p>
              <p className="text-xl font-bold text-emerald-700 flex items-center">
                <CurrencyDollar className="text-lg" />
                {user.user.commission_earned}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Balance;