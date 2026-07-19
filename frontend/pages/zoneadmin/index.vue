<template>
  <div class="min-h-screen bg-slate-100">
    <!-- ============ LOADING ============ -->
    <div v-if="phase === 'loading'" class="min-h-screen flex items-center justify-center">
      <div class="text-center">
        <div class="animate-spin h-8 w-8 border-3 border-emerald-500 border-t-transparent rounded-full mx-auto mb-3"></div>
        <p class="text-slate-500 text-sm">লোড হচ্ছে...</p>
      </div>
    </div>

    <!-- ============ LOGIN ============ -->
    <div v-else-if="phase === 'login'" class="min-h-screen flex items-center justify-center px-3">
      <div class="w-full max-w-md bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        <div class="px-6 pt-8 pb-6 text-center border-b border-slate-100">
          <img src="/images/logo.png" alt="AdsyClub" class="h-10 mx-auto mb-3" onerror="this.style.display='none'" />
          <h1 class="text-xl font-bold text-slate-800">জোনাল অফিস প্যানেল</h1>
          <p class="text-sm text-slate-500 mt-1">আপনার অফিসার অ্যাকাউন্ট দিয়ে লগইন করুন</p>
        </div>
        <form class="p-6 space-y-4" @submit.prevent="doLogin">
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">ইমেইল</label>
            <input v-model="loginForm.email" type="email" required autocomplete="email"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" placeholder="email@example.com" />
          </div>
          <div>
            <label class="block text-sm font-medium text-slate-700 mb-1">পাসওয়ার্ড</label>
            <input v-model="loginForm.password" type="password" required autocomplete="current-password"
              class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" placeholder="••••••••" />
          </div>
          <p v-if="loginError" class="text-sm text-red-600 bg-red-50 rounded-lg px-3 py-2">{{ loginError }}</p>
          <button type="submit" :disabled="loggingIn"
            class="w-full bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white font-semibold rounded-lg py-2.5 text-sm transition">
            {{ loggingIn ? 'লগইন হচ্ছে...' : 'লগইন' }}
          </button>
        </form>
      </div>
    </div>

    <!-- ============ NOT AN OFFICER ============ -->
    <div v-else-if="phase === 'denied'" class="min-h-screen flex items-center justify-center px-3">
      <div class="w-full max-w-md bg-white rounded-2xl shadow-sm border border-slate-200 p-8 text-center">
        <div class="text-4xl mb-3">🔒</div>
        <h1 class="text-lg font-bold text-slate-800 mb-2">প্রবেশাধিকার নেই</h1>
        <p class="text-sm text-slate-500 mb-5">এই অ্যাকাউন্টটি কোনো জোনাল অফিসের সাথে যুক্ত নয়। অফিসার হিসেবে যুক্ত হতে অ্যাডমিনের সাথে যোগাযোগ করুন।</p>
        <button class="text-sm font-semibold text-emerald-700 hover:underline" @click="doLogout">অন্য অ্যাকাউন্টে লগইন করুন</button>
      </div>
    </div>

    <!-- ============ PANEL (sidebar + content) ============ -->
    <div v-else-if="phase === 'dash'" class="flex min-h-screen">
      <!-- Sidebar (desktop) -->
      <aside class="hidden md:flex flex-col w-60 shrink-0 bg-slate-900 text-slate-200 min-h-screen sticky top-0 max-h-screen">
        <div class="px-5 py-5 border-b border-slate-800">
          <p class="text-[11px] uppercase tracking-wider text-emerald-400 font-bold mb-1">Zonal Office</p>
          <h1 class="text-sm font-bold text-white leading-snug">{{ office?.name }}</h1>
          <p class="text-xs text-slate-400 mt-1">জোন: {{ office?.city }}</p>
        </div>
        <!-- Account balance -->
        <button class="mx-3 mt-3 mb-1 rounded-xl bg-gradient-to-br from-emerald-600 to-emerald-700 px-4 py-3 text-left hover:from-emerald-500 hover:to-emerald-600 transition"
          @click="goSection('payouts')">
          <p class="text-[11px] text-emerald-100 mb-0.5">অ্যাকাউন্ট ব্যালেন্স (পাওনা)</p>
          <p class="text-2xl font-extrabold text-white leading-tight">৳{{ money(balance ? balance.payable_now : 0) }}</p>
          <p class="text-[11px] text-emerald-100 mt-1">চলতি মাসে জমছে: ৳{{ money(balance ? balance.this_month : 0) }}</p>
        </button>
        <nav class="flex-1 px-3 py-4 space-y-1">
          <button v-for="m in menu" :key="m.key" class="w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition"
            :class="section === m.key ? 'bg-emerald-600 text-white' : 'text-slate-300 hover:bg-slate-800'"
            @click="goSection(m.key)">
            <span class="text-base leading-none">{{ m.icon }}</span>
            <span>{{ m.label }}</span>
          </button>
        </nav>
        <div class="px-5 py-4 border-t border-slate-800">
          <p class="text-xs text-slate-400 truncate mb-2">{{ office?.officer }}</p>
          <button class="text-xs font-semibold text-red-400 hover:text-red-300" @click="doLogout">লগআউট</button>
        </div>
      </aside>

      <!-- Main -->
      <div class="flex-1 min-w-0">
        <!-- Mobile top bar -->
        <div class="md:hidden sticky top-0 z-20 bg-slate-900 text-white px-4 py-3 flex items-center justify-between">
          <div>
            <p class="text-[10px] uppercase tracking-wider text-emerald-400 font-bold">Zonal Office</p>
            <h1 class="text-sm font-bold leading-tight">{{ office?.city }}</h1>
          </div>
          <button class="text-xs text-red-300 font-semibold" @click="doLogout">লগআউট</button>
        </div>
        <div class="md:hidden bg-white border-b border-slate-200 px-2 py-2 flex gap-1 overflow-x-auto sticky top-[52px] z-10 [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden">
          <button v-for="m in menu" :key="m.key" class="shrink-0 px-3 py-1.5 rounded-full text-xs font-semibold border"
            :class="section === m.key ? 'bg-emerald-600 text-white border-emerald-600' : 'bg-white text-slate-600 border-slate-200'"
            @click="goSection(m.key)">{{ m.icon }} {{ m.label }}</button>
        </div>

        <main class="p-3 sm:p-6 max-w-5xl">
          <!-- ======== DASHBOARD ======== -->
          <template v-if="section === 'dashboard'">
            <!-- Promotional offer banner (static) -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden mb-5">
              <div class="flex flex-col sm:flex-row">
                <!-- Left: 50% seal -->
                <div class="sm:w-44 shrink-0 bg-emerald-600 text-white flex sm:flex-col items-center justify-center gap-2 sm:gap-0 px-5 py-4 sm:py-6">
                  <span class="text-[11px] font-semibold tracking-wide text-emerald-100 uppercase">অতিরিক্ত</span>
                  <span class="text-4xl sm:text-5xl font-black leading-none">৫০%</span>
                  <span class="text-[12px] font-semibold text-emerald-100 sm:mt-1">কমিশন</span>
                </div>
                <!-- Right: clear message -->
                <div class="flex-1 p-5">
                  <div class="flex items-center gap-2 mb-2">
                    <h2 class="text-[15px] font-bold text-slate-800">বিশেষ অফার 🎉</h2>
                    <span class="ml-auto inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 px-2.5 py-1 rounded-full whitespace-nowrap">
                      <span class="h-1.5 w-1.5 rounded-full bg-emerald-500"></span>৩১ জুলাই পর্যন্ত
                    </span>
                  </div>
                  <p class="text-[13.5px] text-slate-600 leading-relaxed">
                    <span class="font-semibold text-slate-800">৩১ জুলাই</span> পর্যন্ত আপনার জোনে যত
                    <span class="font-semibold text-slate-800">Pro সাবস্ক্রিপশন</span> ও
                    <span class="font-semibold text-slate-800">গোল্ড স্পনসর</span> হবে, তার সবগুলোর
                    কমিশনের উপর <span class="font-bold text-emerald-600">অতিরিক্ত ৫০%</span> পাবেন।
                  </p>
                  <div class="flex flex-wrap items-center gap-2 mt-3">
                    <span class="inline-flex items-center gap-1.5 text-[12px] font-medium text-slate-700 bg-slate-100 px-2.5 py-1 rounded-lg">⭐ Pro সাবস্ক্রিপশন</span>
                    <span class="inline-flex items-center gap-1.5 text-[12px] font-medium text-slate-700 bg-slate-100 px-2.5 py-1 rounded-lg">🥇 গোল্ড স্পনসর</span>
                  </div>
                  <p class="text-[12.5px] text-slate-500 mt-3 pt-3 border-t border-slate-100 flex items-center gap-1.5">
                    <span class="text-emerald-600">📞</span> বিস্তারিত জানতে আপনার অ্যাকাউন্ট ম্যানেজারের সাথে যোগাযোগ করুন।
                  </p>
                </div>
              </div>
            </div>

            <!-- Notices -->
            <div v-if="notices.length" class="space-y-3 mb-5">
              <div v-for="n in notices" :key="n.id" class="bg-white rounded-2xl shadow-sm border border-amber-200 overflow-hidden">
                <img v-if="n.image" :src="n.image" class="w-full max-h-56 object-cover" alt="" />
                <div class="px-4 py-3 flex gap-3">
                  <span class="text-lg leading-none mt-0.5">📢</span>
                  <div class="min-w-0">
                    <p class="text-sm font-bold text-slate-800">{{ n.title }}</p>
                    <p v-if="n.body" class="text-sm text-slate-600 mt-0.5 whitespace-pre-line">{{ n.body }}</p>
                    <p class="text-[11px] text-slate-400 mt-1">{{ n.created_at }}</p>
                  </div>
                </div>
              </div>
            </div>

            <div v-if="loadingReport" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-10 text-center">
              <div class="animate-spin h-7 w-7 border-3 border-emerald-500 border-t-transparent rounded-full mx-auto"></div>
            </div>
            <template v-else-if="report">
              <p class="text-xs text-slate-400 mb-3">রিপোর্টের সময়কাল: {{ report.range.from }} → {{ report.range.to }}</p>

              <!-- Hero stat cards -->
              <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
                <div v-for="h in dashHero" :key="h.label" class="bg-white rounded-2xl shadow-sm border border-slate-200 p-4">
                  <div class="flex items-center gap-2 mb-2">
                    <span class="text-lg leading-none">{{ h.icon }}</span>
                    <span class="text-[11px] text-slate-500">{{ h.label }}</span>
                  </div>
                  <p class="text-2xl font-extrabold tracking-tight" :class="toneText(h.tone)">{{ h.value }}</p>
                  <p v-if="h.sub" class="text-[10px] text-slate-400 mt-1">{{ h.sub }}</p>
                </div>
              </div>

              <div class="grid lg:grid-cols-2 gap-5">
                <!-- Pro subscription health -->
                <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
                  <div class="px-5 py-3.5 border-b border-slate-100">
                    <h2 class="text-sm font-bold text-slate-800">Pro সাবস্ক্রিপশন (এখনকার অবস্থা)</h2>
                  </div>
                  <ZoneSubHealth :s="report.subscriptions" />
                </div>

                <!-- Sales breakdown -->
                <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
                  <div class="px-5 py-3.5 border-b border-slate-100 flex items-center justify-between">
                    <h2 class="text-sm font-bold text-slate-800">সেলস ব্রেকডাউন</h2>
                    <button class="text-xs font-semibold text-emerald-700 hover:underline" @click="goSection('sales')">কমিশন রিপোর্ট →</button>
                  </div>
                  <ZoneSalesList :rows="dashSales" />
                </div>
              </div>
            </template>
          </template>

          <!-- ======== SALES REPORT ======== -->
          <template v-else-if="section === 'sales'">
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-100">
                <h2 class="text-base font-bold text-slate-800">সেলস ও কমিশন রিপোর্ট</h2>
              </div>
              <div class="px-5 py-3 border-b border-slate-100 flex flex-wrap items-center gap-2">
                <button v-for="r in quickRanges" :key="r.days"
                  class="text-xs font-semibold px-3 py-1.5 rounded-full border transition"
                  :class="activeQuick === r.days ? 'bg-emerald-600 text-white border-emerald-600' : 'bg-white text-slate-600 border-slate-200 hover:border-emerald-400'"
                  @click="setQuickRange(r.days)">{{ r.label }}</button>
                <div class="flex items-center gap-1.5 ml-auto">
                  <input v-model="range.from" type="date" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5" />
                  <span class="text-slate-400 text-xs">—</span>
                  <input v-model="range.to" type="date" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5" />
                  <button class="text-xs font-semibold bg-slate-800 text-white px-3 py-1.5 rounded-lg hover:bg-slate-700" @click="applyCustomRange">দেখুন</button>
                </div>
              </div>

              <div v-if="loadingReport" class="p-10 text-center">
                <div class="animate-spin h-7 w-7 border-3 border-emerald-500 border-t-transparent rounded-full mx-auto"></div>
              </div>
              <template v-else-if="report">
                <!-- Pro subscription / renewal analysis -->
                <div class="px-5 pt-4 pb-2"><h3 class="text-sm font-bold text-slate-700">Pro সাবস্ক্রিপশন বিশ্লেষণ</h3></div>
                <div class="mx-5 mb-5 border border-slate-200 rounded-xl overflow-hidden">
                  <ZoneSubHealth :s="report.subscriptions" />
                </div>

                <div class="px-5 pt-4 pb-2 border-t border-slate-100"><h3 class="text-sm font-bold text-slate-700">এলাকা অনুযায়ী রেজিস্ট্রেশন</h3></div>
                <div class="px-5 pb-5">
                  <div v-if="!report.by_area.length" class="text-sm text-slate-400 py-3">এই সময়ে কোনো নতুন রেজিস্ট্রেশন নেই।</div>
                  <div v-else class="grid sm:grid-cols-2 gap-x-8">
                    <div v-for="a in report.by_area" :key="a.upazila" class="flex items-center justify-between py-1.5 border-b border-slate-50 text-sm">
                      <span class="text-slate-700">{{ a.upazila }}</span>
                      <span class="font-semibold text-slate-800">{{ a.n }} জন</span>
                    </div>
                  </div>
                </div>

                <div class="px-5 pt-4 pb-2 border-t border-slate-100"><h3 class="text-sm font-bold text-slate-700">কমিশন হিসাব</h3></div>
                <div class="px-5 pb-5 overflow-x-auto">
                  <table class="w-full text-sm whitespace-nowrap">
                    <thead>
                      <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                        <th class="text-left py-2 font-medium">ফিচার</th>
                        <th class="text-right py-2 font-medium">সংখ্যা</th>
                        <th class="text-right py-2 font-medium">সেলস (৳)</th>
                        <th class="text-right py-2 font-medium">রেট</th>
                        <th class="text-right py-2 font-medium">কমিশন (৳)</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="c in report.commissions" :key="c.feature" class="border-b border-slate-50">
                        <td class="py-2 text-slate-700">{{ featureBn(c.feature) }}</td>
                        <td class="py-2 text-right text-slate-700 font-medium">{{ c.count }} {{ countUnit(c.feature) }}</td>
                        <td class="py-2 text-right text-slate-600">{{ c.type === 'flat' ? '—' : money(c.base_amount) }}</td>
                        <td class="py-2 text-right text-slate-600">{{ rateText(c) }}</td>
                        <td class="py-2 text-right font-semibold text-slate-700">{{ money(c.gross ?? c.earned) }}</td>
                      </tr>
                      <tr class="border-t border-slate-100">
                        <td colspan="4" class="py-2 text-right text-sm text-slate-600">মোট কমিশন (গ্রস)</td>
                        <td class="py-2 text-right text-sm font-semibold text-slate-700">৳{{ money(report.totals.commission_gross) }}</td>
                      </tr>
                      <tr v-if="report.totals.commission_area_managers > 0">
                        <td colspan="4" class="py-2 text-right text-sm text-slate-600">— এরিয়া ম্যানেজারদের অংশ</td>
                        <td class="py-2 text-right text-sm font-semibold text-red-500">−৳{{ money(report.totals.commission_area_managers) }}</td>
                      </tr>
                      <tr>
                        <td colspan="4" class="py-2.5 text-right text-sm font-bold text-slate-800">আপনার নিট কমিশন</td>
                        <td class="py-2.5 text-right text-base font-bold text-emerald-700">৳{{ money(report.totals.commission) }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>

                <!-- Area manager split (who took what out of the zone's cut) -->
                <div v-if="report.area_manager_split && report.area_manager_split.length" class="px-5 pb-5">
                  <p class="text-xs font-semibold text-slate-500 mb-2">এরিয়া ম্যানেজারদের কমিশন (আপনার অংশ থেকে)</p>
                  <div class="border border-slate-200 rounded-xl divide-y divide-slate-100">
                    <div v-for="m in report.area_manager_split" :key="m.name + m.area" class="flex items-center justify-between px-4 py-2.5 text-sm">
                      <span class="text-slate-700">{{ m.name }} <span class="text-slate-400 text-xs">📍 {{ m.area }}</span></span>
                      <span class="font-semibold text-slate-700">৳{{ money(m.from_zone) }}</span>
                    </div>
                  </div>
                </div>

                <div class="px-5 pt-4 pb-2 border-t border-slate-100"><h3 class="text-sm font-bold text-slate-700">দৈনিক অ্যাক্টিভিটি</h3></div>
                <div class="px-5 pb-6 overflow-x-auto">
                  <table class="w-full text-xs sm:text-sm whitespace-nowrap">
                    <thead>
                      <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                        <th class="text-left py-2 font-medium">তারিখ</th>
                        <th class="text-right py-2 font-medium">রেজি.</th>
                        <th class="text-right py-2 font-medium">Pro (৳)</th>
                        <th class="text-right py-2 font-medium">গিগ (৳)</th>
                        <th class="text-right py-2 font-medium">অর্ডার (৳)</th>
                        <th class="text-right py-2 font-medium">রিচার্জ (৳)</th>
                        <th class="text-right py-2 font-medium">গোল্ড (৳)</th>
                        <th class="text-right py-2 font-medium">রাইড (৳)</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="d in report.days" :key="d.date" class="border-b border-slate-50">
                        <td class="py-1.5 text-slate-600">{{ d.date }}</td>
                        <td class="py-1.5 text-right" :class="d.registrations ? 'font-semibold text-slate-800' : 'text-slate-300'">{{ d.registrations }}</td>
                        <td class="py-1.5 text-right" :class="d.pro.n ? 'text-slate-700' : 'text-slate-300'">{{ d.pro.n }} / {{ money(d.pro.s) }}</td>
                        <td class="py-1.5 text-right" :class="d.gigs.n ? 'text-slate-700' : 'text-slate-300'">{{ d.gigs.n }} / {{ money(d.gigs.s) }}</td>
                        <td class="py-1.5 text-right" :class="d.orders.n ? 'text-slate-700' : 'text-slate-300'">{{ d.orders.n }} / {{ money(d.orders.s) }}</td>
                        <td class="py-1.5 text-right" :class="d.recharges.n ? 'text-slate-700' : 'text-slate-300'">{{ d.recharges.n }} / {{ money(d.recharges.s) }}</td>
                        <td class="py-1.5 text-right" :class="d.gold && d.gold.n ? 'text-slate-700' : 'text-slate-300'">{{ d.gold ? d.gold.n : 0 }} / {{ money(d.gold && d.gold.s) }}</td>
                        <td class="py-1.5 text-right" :class="d.rides && d.rides.n ? 'text-slate-700' : 'text-slate-300'">{{ d.rides ? d.rides.n : 0 }} / {{ money(d.rides && d.rides.s) }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </template>
            </div>
          </template>

          <!-- ======== AREA MANAGERS ======== -->
          <template v-else-if="section === 'managers'">
            <!-- Manager profile -->
            <div v-if="managerView === 'profile' && managerReport" class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-100 flex flex-wrap items-center justify-between gap-2">
                <div>
                  <button class="text-xs text-slate-400 hover:text-slate-600 mb-1" @click="managerView = 'list'">← সব ম্যানেজার</button>
                  <h2 class="text-base font-bold text-slate-800">{{ managerReport.manager.name }}</h2>
                  <p class="text-xs text-slate-500">এলাকা: {{ managerReport.manager.area }} <span v-if="managerReport.manager.phone">&bull; {{ managerReport.manager.phone }}</span></p>
                </div>
                <div class="flex items-center gap-2">
                  <button class="text-xs font-semibold text-blue-600 hover:underline" @click="startEditManager(managerReport.manager)">এডিট</button>
                  <button class="text-xs font-semibold text-red-500 hover:underline" @click="deleteManager(managerReport.manager)">ডিলিট</button>
                </div>
              </div>
              <!-- Tabs (scrollable on small screens, scrollbar hidden) -->
              <div class="px-5 pt-3 pb-0 border-b border-slate-100 flex gap-1 overflow-x-auto [scrollbar-width:none] [-ms-overflow-style:none] [&::-webkit-scrollbar]:hidden">
                <button v-for="t in mgrTabs" :key="t.key"
                  class="shrink-0 px-4 py-2.5 text-[13px] font-semibold border-b-2 -mb-px transition"
                  :class="mgrTab === t.key ? 'border-emerald-600 text-emerald-700' : 'border-transparent text-slate-500 hover:text-slate-700'"
                  @click="mgrTab = t.key">{{ t.icon }} {{ t.label }}</button>
              </div>

              <!-- Date range (only where it matters) -->
              <div v-if="mgrTab === 'overview' || mgrTab === 'commission'" class="px-5 py-3 border-b border-slate-100 flex flex-wrap items-center gap-2">
                <button v-for="r in quickRanges" :key="r.days"
                  class="text-xs font-semibold px-3 py-1.5 rounded-full border"
                  :class="mgrQuick === r.days ? 'bg-emerald-600 text-white border-emerald-600' : 'bg-white text-slate-600 border-slate-200'"
                  @click="loadManagerReport(managerReport.manager.id, r.days)">{{ r.label }}</button>
                <div class="flex items-center gap-1.5 ml-auto">
                  <input v-model="mgrRange.from" type="date" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5" />
                  <span class="text-slate-400 text-xs">—</span>
                  <input v-model="mgrRange.to" type="date" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5" />
                  <button class="text-xs font-semibold bg-slate-800 text-white px-3 py-1.5 rounded-lg hover:bg-slate-700"
                    @click="loadManagerReportCustom(managerReport.manager.id)">দেখুন</button>
                </div>
              </div>

              <!-- ===== TAB: overview ===== -->
              <template v-if="mgrTab === 'overview'">
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 p-5 border-b border-slate-100">
                  <div v-for="h in mgrHero" :key="h.label" class="rounded-xl border border-slate-200 p-3.5">
                    <div class="flex items-center gap-1.5 mb-1.5">
                      <span class="text-base leading-none">{{ h.icon }}</span>
                      <span class="text-[11px] text-slate-500">{{ h.label }}</span>
                    </div>
                    <p class="text-xl font-extrabold" :class="toneText(h.tone)">{{ h.value }}</p>
                    <p v-if="h.sub" class="text-[10px] text-slate-400 mt-1">{{ h.sub }}</p>
                  </div>
                </div>
                <div class="px-5 pt-4 pb-2"><h3 class="text-sm font-bold text-slate-700">Pro সাবস্ক্রিপশন (এই এলাকা)</h3></div>
                <div class="mx-5 mb-4 border border-slate-200 rounded-xl overflow-hidden">
                  <ZoneSubHealth :s="managerReport.subscriptions" />
                </div>
                <div class="px-5 pt-2 pb-2 border-t border-slate-100"><h3 class="text-sm font-bold text-slate-700">সেলস ব্রেকডাউন</h3></div>
                <div class="mx-5 mb-5 border border-slate-200 rounded-xl overflow-hidden">
                  <ZoneSalesList :rows="mgrSales" />
                </div>
              </template>

              <!-- ===== TAB: commission ===== -->
              <template v-else-if="mgrTab === 'commission'">
                <div class="px-5 pt-4 pb-2"><h3 class="text-sm font-bold text-slate-700">কমিশন ব্রেকডাউন ({{ managerReport.range.from }} → {{ managerReport.range.to }})</h3></div>
                <div class="px-5 pb-6 overflow-x-auto">
                  <table class="w-full text-sm whitespace-nowrap">
                    <thead>
                      <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                        <th class="text-left py-2 font-medium">ফিচার</th>
                        <th class="text-right py-2 font-medium">সংখ্যা</th>
                        <th class="text-right py-2 font-medium">সেলস (৳)</th>
                        <th class="text-right py-2 font-medium">রেট</th>
                        <th class="text-right py-2 font-medium">কমিশন (৳)</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="c in managerReport.commissions" :key="c.feature" class="border-b border-slate-50">
                        <td class="py-2 text-slate-700">{{ featureBn(c.feature) }}</td>
                        <td class="py-2 text-right text-slate-700 font-medium">{{ c.count }} {{ countUnit(c.feature) }}</td>
                        <td class="py-2 text-right text-slate-600">{{ c.type === 'flat' ? '—' : money(c.base_amount) }}</td>
                        <td class="py-2 text-right text-slate-600">{{ rateText(c) }}</td>
                        <td class="py-2 text-right font-semibold text-emerald-700">{{ money(c.earned) }}</td>
                      </tr>
                      <tr>
                        <td colspan="4" class="py-2.5 text-right text-sm font-bold text-slate-700">মোট কমিশন</td>
                        <td class="py-2.5 text-right text-base font-bold text-emerald-700">৳{{ money(managerReport.totals.commission) }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </template>

              <!-- ===== TAB: services (আমার সেবা) ===== -->
              <template v-else-if="mgrTab === 'services'">
                <div class="px-5 pt-4 pb-2"><h3 class="text-sm font-bold text-slate-700">আমার সেবা — ক্যাটাগরি অনুযায়ী লাইভ পোস্ট</h3></div>
                <div class="mx-5 mb-6">
                  <div v-if="!managerReport.service_categories || !managerReport.service_categories.length" class="text-sm text-slate-400 py-2 px-1">এই এলাকায় এখনো কোনো লাইভ সেবা পোস্ট নেই।</div>
                  <div v-else class="border border-slate-200 rounded-xl overflow-hidden">
                    <table class="w-full text-sm">
                      <thead>
                        <tr class="text-[11px] text-slate-400 border-b border-slate-100 bg-slate-50/60">
                          <th class="text-left py-2 px-4 font-medium">ক্যাটাগরি</th>
                          <th class="text-right py-2 px-4 font-medium">লাইভ পোস্ট</th>
                        </tr>
                      </thead>
                      <tbody>
                        <tr v-for="(s, i) in managerReport.service_categories" :key="s.category"
                          :class="i % 2 ? 'bg-slate-50/40' : ''" class="border-b border-slate-50 last:border-0">
                          <td class="py-2 px-4" :class="s.n ? 'text-slate-700' : 'text-slate-400'">{{ s.category }}</td>
                          <td class="py-2 px-4 text-right" :class="s.n ? 'font-semibold text-slate-800' : 'text-slate-300'">{{ s.n }} টি</td>
                        </tr>
                      </tbody>
                    </table>
                  </div>
                </div>
              </template>

              <!-- ===== TAB: payouts ===== -->
              <template v-else-if="mgrTab === 'payouts'">
                <div class="px-5 pt-4 pb-2"><h3 class="text-sm font-bold text-slate-700">আয় ও পেআউট</h3></div>
                <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 px-5 pb-4">
                  <div class="rounded-xl border border-slate-200 p-3">
                    <p class="text-[11px] text-slate-500 mb-0.5">পাওনা (এখন)</p>
                    <p class="text-lg font-extrabold text-emerald-600">৳{{ money(mgrBalance?.payable_now) }}</p>
                  </div>
                  <div class="rounded-xl border border-slate-200 p-3">
                    <p class="text-[11px] text-slate-500 mb-0.5">চলতি মাসে জমছে</p>
                    <p class="text-lg font-extrabold text-amber-500">৳{{ money(mgrBalance?.this_month) }}</p>
                  </div>
                  <div class="rounded-xl border border-slate-200 p-3">
                    <p class="text-[11px] text-slate-500 mb-0.5">লাইফটাইম আয়</p>
                    <p class="text-lg font-extrabold text-slate-800">৳{{ money(mgrBalance?.lifetime_earned) }}</p>
                  </div>
                  <div class="rounded-xl border border-slate-200 p-3">
                    <p class="text-[11px] text-slate-500 mb-0.5">মোট পরিশোধিত</p>
                    <p class="text-lg font-extrabold text-blue-600">৳{{ money(mgrBalance?.total_paid) }}</p>
                  </div>
                </div>
                <div class="px-5 pb-4">
                  <div class="rounded-xl bg-slate-50 px-4 py-3">
                    <p class="text-[11px] text-slate-500 mb-1">পেআউট তথ্য</p>
                    <p v-if="managerReport.manager.payout_account_number" class="text-sm text-slate-700">
                      {{ payMethodBn(managerReport.manager.payout_method) }} — {{ managerReport.manager.payout_account_number }}
                      <span v-if="managerReport.manager.payout_account_name" class="text-slate-500">({{ managerReport.manager.payout_account_name }})</span>
                    </p>
                    <p v-else class="text-sm text-slate-400">পেআউট তথ্য দেওয়া হয়নি — “এডিট” থেকে যোগ করুন।</p>
                    <p v-if="managerReport.manager.payout_bank_name" class="text-[11px] text-slate-500 mt-0.5">
                      {{ managerReport.manager.payout_bank_name }}<span v-if="managerReport.manager.payout_bank_branch">, {{ managerReport.manager.payout_bank_branch }}</span>
                    </p>
                  </div>
                </div>
                <div class="px-5 pt-2 pb-2 border-t border-slate-100"><h3 class="text-sm font-bold text-slate-700">পেআউট হিস্টোরি (মাসিক ইনভয়েস)</h3></div>
                <div class="px-5 pb-6 overflow-x-auto">
                  <div v-if="!mgrInvoices.length" class="text-sm text-slate-400 py-2">এখনো কোনো ইনভয়েস নেই (মাস শেষে স্বয়ংক্রিয়ভাবে তৈরি হবে)।</div>
                  <table v-else class="w-full text-xs sm:text-sm whitespace-nowrap">
                    <thead>
                      <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                        <th class="text-left py-2 font-medium">মাস</th>
                        <th class="text-right py-2 font-medium">কমিশন (৳)</th>
                        <th class="text-left py-2 font-medium pl-4">স্ট্যাটাস</th>
                        <th class="text-left py-2 font-medium">পরিশোধ</th>
                        <th class="text-left py-2 font-medium">Trx ID</th>
                      </tr>
                    </thead>
                    <tbody>
                      <tr v-for="inv in mgrInvoices" :key="inv.id" class="border-b border-slate-50">
                        <td class="py-2 font-semibold text-slate-700">{{ inv.period }}</td>
                        <td class="py-2 text-right font-bold text-slate-800">{{ money(inv.amount) }}</td>
                        <td class="py-2 pl-4">
                          <span class="text-[11px] font-semibold px-2 py-0.5 rounded-full"
                            :class="inv.status === 'paid' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'">
                            {{ inv.status === 'paid' ? 'পরিশোধিত' : 'বকেয়া' }}
                          </span>
                        </td>
                        <td class="py-2 text-slate-500">{{ inv.paid_at || '—' }}</td>
                        <td class="py-2 text-slate-500">{{ inv.pay_trx_id || '—' }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </template>
            </div>

            <!-- Manager create/edit form -->
            <div v-else-if="managerView === 'form'" class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-100">
                <button class="text-xs text-slate-400 hover:text-slate-600 mb-1" @click="managerView = 'list'">← সব ম্যানেজার</button>
                <h2 class="text-base font-bold text-slate-800">{{ managerForm.id ? 'ম্যানেজার এডিট করুন' : 'নতুন এরিয়া ম্যানেজার' }}</h2>
              </div>
              <form class="p-5 space-y-4" @submit.prevent="saveManager">
                <div class="grid sm:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-slate-700 mb-1">নাম *</label>
                    <input v-model="managerForm.name" required class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="ম্যানেজারের নাম" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-slate-700 mb-1">ফোন</label>
                    <input v-model="managerForm.phone" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="01XXXXXXXXX" />
                  </div>
                </div>
                <div>
                  <label class="block text-sm font-medium text-slate-700 mb-1">এলাকা (উপজেলা) *</label>
                  <select v-model="managerForm.area" required class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm bg-white">
                    <option value="">— এলাকা সিলেক্ট  করুন —</option>
                    <option v-for="a in areas" :key="a" :value="a">{{ a }}</option>
                  </select>
                </div>
                <div>
                  <p class="text-sm font-bold text-slate-700 mb-1">কমিশন স্ট্রাকচার</p>
                  <p class="text-[12px] text-slate-400 mb-2">ম্যানেজারের কমিশন আপনার জোন কমিশন থেকে কাটা যায় — তাই আপনার রেটের বেশি দেওয়া যায় না।</p>
                  <div class="border border-slate-200 rounded-xl divide-y divide-slate-100">
                    <div v-for="row in managerForm.commissions" :key="row.feature" class="flex items-center gap-2 px-3 py-2.5">
                      <div class="flex-1 min-w-0">
                        <p class="text-sm text-slate-700">{{ featureBn(row.feature) }}</p>
                        <p class="text-[11px]" :class="zoneMax(row.feature).value > 0 ? 'text-emerald-600' : 'text-slate-400'">
                          সর্বোচ্চ: {{ zoneMaxText(row.feature) }}
                        </p>
                      </div>
                      <select v-model="row.type" class="text-xs border border-slate-200 rounded-lg px-2 py-1.5 bg-white">
                        <option value="percent">% (পার্সেন্ট)</option>
                        <option value="flat">৳ ফ্ল্যাট/টা</option>
                      </select>
                      <input v-model.number="row.value" type="number" min="0" :max="row.type === zoneMax(row.feature).type ? zoneMax(row.feature).value : undefined" step="0.01"
                        class="w-24 text-right text-sm border rounded-lg px-2 py-1.5"
                        :class="rowOverLimit(row) ? 'border-red-400 bg-red-50 text-red-700' : 'border-slate-200'"
                        placeholder="0" />
                    </div>
                  </div>
                </div>

                <!-- Payout information -->
                <div class="pt-2 border-t border-slate-100">
                  <p class="text-sm font-bold text-slate-700 mb-2">পেআউট তথ্য (ঐচ্ছিক)</p>
                  <div class="grid sm:grid-cols-2 gap-3">
                    <select v-model="managerForm.payout_method" class="rounded-lg border border-slate-300 px-3 py-2 text-sm bg-white">
                      <option value="">— পেমেন্ট মাধ্যম —</option>
                      <option value="bkash">bKash</option>
                      <option value="nagad">Nagad</option>
                      <option value="rocket">Rocket</option>
                      <option value="bank">Bank</option>
                    </select>
                    <input v-model="managerForm.payout_account_name" class="rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="অ্যাকাউন্টের নাম" />
                    <input v-model="managerForm.payout_account_number" class="rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="অ্যাকাউন্ট নম্বর" />
                    <template v-if="managerForm.payout_method === 'bank'">
                      <input v-model="managerForm.payout_bank_name" class="rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="ব্যাংকের নাম" />
                      <input v-model="managerForm.payout_bank_branch" class="rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="ব্রাঞ্চ" />
                    </template>
                  </div>
                </div>

                <p v-if="managerError" class="text-sm text-red-600 bg-red-50 rounded-lg px-3 py-2">{{ managerError }}</p>
                <button type="submit" :disabled="savingManager" class="bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white text-sm font-semibold rounded-lg px-5 py-2.5">
                  {{ savingManager ? 'সেভ হচ্ছে...' : 'সেভ করুন' }}
                </button>
              </form>
            </div>

            <!-- Manager list -->
            <div v-else class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
                <div>
                  <h2 class="text-base font-bold text-slate-800">এরিয়া ম্যানেজার</h2>
                  <p class="text-xs text-slate-500 mt-0.5">এলাকা ধরে এজেন্ট নিয়োগ দিন — তাদের কমিশন আপনাআপনি হিসাব হবে</p>
                </div>
                <button class="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-semibold rounded-lg px-4 py-2" @click="startNewManager">+ নতুন ম্যানেজার</button>
              </div>
              <div v-if="!managers.length" class="p-8 text-center text-sm text-slate-400">এখনো কোনো এরিয়া ম্যানেজার নেই — উপরের বাটন দিয়ে প্রথমজনকে যোগ করুন।</div>
              <div v-else class="divide-y divide-slate-100">
                <button v-for="m in managers" :key="m.id" class="w-full text-left px-5 py-3.5 hover:bg-slate-50 transition flex items-center gap-3" @click="openManager(m)">
                  <div class="h-10 w-10 rounded-full bg-emerald-50 text-emerald-700 font-bold flex items-center justify-center text-sm shrink-0">{{ m.name.charAt(0) }}</div>
                  <div class="min-w-0 flex-1">
                    <p class="text-sm font-semibold text-slate-800 truncate">{{ m.name }}
                      <span v-if="!m.is_active" class="text-[10px] font-semibold text-red-500 ml-1">(ইনএক্টিভ)</span>
                    </p>
                    <p class="text-xs text-slate-500 truncate">📍 {{ m.area }} <span v-if="m.phone">&bull; {{ m.phone }}</span></p>
                  </div>
                  <span class="text-xs text-slate-400">প্রোফাইল →</span>
                </button>
              </div>
            </div>
          </template>

          <!-- ======== PRIMARY NOTES (sticky-note board) ======== -->
          <template v-else-if="section === 'notes'">
            <!-- Composer -->
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden mb-5">
              <div class="px-5 py-4 border-b border-slate-100 flex items-center gap-2">
                <span class="text-lg">📝</span>
                <div>
                  <h2 class="text-base font-bold text-slate-800">{{ noteForm.id ? 'নোট এডিট করুন' : 'নতুন নোট' }}</h2>
                  <p class="text-xs text-slate-500 mt-0.5">জোনের প্রয়োজনীয় নোট লিখে রাখুন — অ্যাডমিনও দেখতে পারবেন</p>
                </div>
              </div>
              <form class="p-5 space-y-3" @submit.prevent="saveNote">
                <input v-model="noteForm.title" required class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-amber-400" placeholder="নোটের শিরোনাম *" />
                <textarea v-model="noteForm.body" rows="3" class="w-full rounded-lg border border-slate-300 px-3 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-amber-400" placeholder="বিস্তারিত (ঐচ্ছিক)"></textarea>
                <div class="flex items-center gap-3">
                  <button type="submit" :disabled="savingNote" class="bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white text-sm font-semibold rounded-lg px-5 py-2.5">
                    {{ noteForm.id ? 'আপডেট করুন' : '+ নোট যোগ করুন' }}
                  </button>
                  <button v-if="noteForm.id" type="button" class="text-sm text-slate-400 hover:text-slate-600" @click="resetNoteForm">বাতিল</button>
                </div>
              </form>
            </div>

            <!-- Sticky-note grid -->
            <div v-if="!notes.length" class="bg-white rounded-2xl border border-dashed border-slate-300 p-10 text-center text-sm text-slate-400">
              এখনো কোনো নোট নেই — উপরে লিখে প্রথম নোটটি যোগ করুন।
            </div>
            <div v-else class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
              <div v-for="(n, i) in notes" :key="n.id"
                class="group relative rounded-xl p-4 shadow-sm border transition hover:shadow-md hover:-translate-y-0.5"
                :class="noteColors[i % noteColors.length]">
                <div class="flex items-start justify-between gap-2">
                  <h3 class="text-sm font-bold text-slate-800 break-words pr-1">{{ n.title }}</h3>
                  <div class="flex items-center gap-1.5 shrink-0 opacity-0 group-hover:opacity-100 transition">
                    <button class="text-slate-400 hover:text-blue-600" title="এডিট" @click="editNote(n)">✏️</button>
                    <button class="text-slate-400 hover:text-red-500" title="ডিলিট" @click="deleteNote(n)">🗑️</button>
                  </div>
                </div>
                <p v-if="n.body" class="text-sm text-slate-700 mt-2 whitespace-pre-line break-words leading-relaxed">{{ n.body }}</p>
                <p class="text-[11px] text-slate-500/80 mt-3 pt-2 border-t border-black/5">{{ n.updated_at }}</p>
              </div>
            </div>
          </template>

          <!-- ======== PAYOUT REPORT (balance + monthly invoices) ======== -->
          <template v-else-if="section === 'payouts'">
            <!-- Balance summary -->
            <div class="grid grid-cols-2 lg:grid-cols-4 gap-3 mb-5">
              <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-4">
                <p class="text-[11px] text-slate-500 mb-1">পাওনা (এখন)</p>
                <p class="text-2xl font-extrabold text-emerald-600">৳{{ money(balance?.payable_now) }}</p>
              </div>
              <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-4">
                <p class="text-[11px] text-slate-500 mb-1">চলতি মাসে জমছে</p>
                <p class="text-2xl font-extrabold text-amber-500">৳{{ money(balance?.this_month) }}</p>
              </div>
              <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-4">
                <p class="text-[11px] text-slate-500 mb-1">মোট আয় (লাইফটাইম)</p>
                <p class="text-2xl font-extrabold text-slate-800">৳{{ money(balance?.lifetime_earned) }}</p>
              </div>
              <div class="bg-white rounded-2xl shadow-sm border border-slate-200 p-4">
                <p class="text-[11px] text-slate-500 mb-1">মোট পরিশোধিত</p>
                <p class="text-2xl font-extrabold text-blue-600">৳{{ money(balance?.total_paid) }}</p>
              </div>
            </div>

            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-100">
                <h2 class="text-base font-bold text-slate-800">মাসিক ইনভয়েস ও পেআউট</h2>
                <p class="text-xs text-slate-500 mt-0.5">প্রতি মাসের কমিশন থেকে ইনভয়েস তৈরি হয়; অ্যাডমিন পরিশোধ করলে এখানে স্ট্যাটাস আপডেট হয়</p>
              </div>
              <div v-if="!invoices.length" class="p-8 text-center text-sm text-slate-400">এখনো কোনো ইনভয়েস তৈরি হয়নি (মাস শেষে স্বয়ংক্রিয়ভাবে তৈরি হবে)।</div>
              <div v-else class="px-5 py-3 overflow-x-auto">
                <table class="w-full text-xs sm:text-sm whitespace-nowrap">
                  <thead>
                    <tr class="text-[11px] text-slate-400 border-b border-slate-100">
                      <th class="text-left py-2 font-medium">মাস</th>
                      <th class="text-right py-2 font-medium">কমিশন (৳)</th>
                      <th class="text-left py-2 font-medium pl-4">স্ট্যাটাস</th>
                      <th class="text-left py-2 font-medium">পরিশোধের তারিখ</th>
                      <th class="text-left py-2 font-medium">মাধ্যম</th>
                      <th class="text-left py-2 font-medium">Trx ID</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="inv in invoices" :key="inv.id" class="border-b border-slate-50">
                      <td class="py-2.5 font-semibold text-slate-700">{{ inv.period }}</td>
                      <td class="py-2.5 text-right font-bold text-slate-800">{{ money(inv.amount) }}</td>
                      <td class="py-2.5 pl-4">
                        <span class="text-[11px] font-semibold px-2 py-0.5 rounded-full"
                          :class="inv.status === 'paid' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'">
                          {{ inv.status === 'paid' ? 'পরিশোধিত' : 'বকেয়া' }}
                        </span>
                      </td>
                      <td class="py-2.5 text-slate-500">{{ inv.paid_at || '—' }}</td>
                      <td class="py-2.5 text-slate-600">{{ payMethodBn(inv.pay_method) }}</td>
                      <td class="py-2.5 text-slate-500">{{ inv.pay_trx_id || '—' }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </template>

          <!-- ======== ZONE SETTINGS ======== -->
          <template v-else-if="section === 'settings'">
            <div class="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
              <div class="px-5 py-4 border-b border-slate-100">
                <h2 class="text-base font-bold text-slate-800">জোন সেটিংস</h2>
                <p class="text-xs text-slate-500 mt-0.5">আপনার প্রোফাইল ও পেআউট তথ্য — কমিশন পাঠাতে অ্যাডমিন এগুলো ব্যবহার করবেন</p>
              </div>
              <div v-if="!settingsData" class="p-10 text-center">
                <div class="animate-spin h-7 w-7 border-3 border-emerald-500 border-t-transparent rounded-full mx-auto"></div>
              </div>
              <template v-else>
                <!-- Officer profile -->
                <div class="px-5 py-4 border-b border-slate-100 flex items-center gap-4">
                  <img v-if="settingsData.officer_photo" :src="settingsData.officer_photo" class="h-16 w-16 rounded-full object-cover border border-slate-200" alt="" />
                  <div v-else class="h-16 w-16 rounded-full bg-emerald-50 text-emerald-700 font-bold flex items-center justify-center text-xl">{{ (settingsData.officer_name || 'A').charAt(0) }}</div>
                  <div class="min-w-0">
                    <p class="text-sm font-bold text-slate-800">{{ settingsData.officer_name }}</p>
                    <p class="text-xs text-slate-500">{{ settingsData.officer_email }} <span v-if="settingsData.officer_phone">&bull; {{ settingsData.officer_phone }}</span></p>
                    <p class="text-xs text-slate-400 mt-0.5">{{ settingsData.office_name }} &bull; জোন: {{ settingsData.city }} &bull; যুক্ত: {{ settingsData.joined }}</p>
                  </div>
                </div>
                <!-- Payout form -->
                <form class="p-5 space-y-4" @submit.prevent="saveSettings">
                  <div class="grid sm:grid-cols-2 gap-4">
                    <div>
                      <label class="block text-sm font-medium text-slate-700 mb-1">যোগাযোগের ফোন</label>
                      <input v-model="settingsForm.contact_phone" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="01XXXXXXXXX" />
                    </div>
                    <div>
                      <label class="block text-sm font-medium text-slate-700 mb-1">NID নম্বর</label>
                      <input v-model="settingsForm.nid_number" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="জাতীয় পরিচয়পত্র নম্বর" />
                    </div>
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-slate-700 mb-1">অফিসের ঠিকানা</label>
                    <input v-model="settingsForm.office_address" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="অফিস/বাসার ঠিকানা" />
                  </div>
                  <div class="pt-2 border-t border-slate-100">
                    <p class="text-sm font-bold text-slate-700 mb-3">পেআউট অ্যাকাউন্ট</p>
                    <div class="grid sm:grid-cols-2 gap-4">
                      <div>
                        <label class="block text-sm font-medium text-slate-700 mb-1">পেমেন্ট মাধ্যম</label>
                        <select v-model="settingsForm.payout_method" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm bg-white">
                          <option value="">— সিলেক্ট  করুন —</option>
                          <option value="bkash">bKash</option>
                          <option value="nagad">Nagad</option>
                          <option value="rocket">Rocket</option>
                          <option value="bank">Bank</option>
                        </select>
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-slate-700 mb-1">অ্যাকাউন্টের নাম</label>
                        <input v-model="settingsForm.payout_account_name" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="অ্যাকাউন্ট হোল্ডারের নাম" />
                      </div>
                      <div>
                        <label class="block text-sm font-medium text-slate-700 mb-1">অ্যাকাউন্ট নম্বর</label>
                        <input v-model="settingsForm.payout_account_number" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" placeholder="নম্বর" />
                      </div>
                      <template v-if="settingsForm.payout_method === 'bank'">
                        <div>
                          <label class="block text-sm font-medium text-slate-700 mb-1">ব্যাংকের নাম</label>
                          <input v-model="settingsForm.payout_bank_name" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" />
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-slate-700 mb-1">ব্রাঞ্চ</label>
                          <input v-model="settingsForm.payout_bank_branch" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" />
                        </div>
                        <div>
                          <label class="block text-sm font-medium text-slate-700 mb-1">রাউটিং নম্বর</label>
                          <input v-model="settingsForm.payout_routing_number" class="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm" />
                        </div>
                      </template>
                    </div>
                  </div>
                  <div class="flex items-center gap-3">
                    <button type="submit" :disabled="savingSettings" class="bg-emerald-600 hover:bg-emerald-700 disabled:opacity-60 text-white text-sm font-semibold rounded-lg px-5 py-2.5">
                      {{ savingSettings ? 'সেভ হচ্ছে...' : 'সেভ করুন' }}
                    </button>
                    <span v-if="settingsSaved" class="text-xs font-semibold text-emerald-600">✓ সেভ হয়েছে</span>
                  </div>
                </form>
              </template>
            </div>
          </template>
        </main>
      </div>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: false });
useHead({ title: "জোনাল অফিস প্যানেল | AdsyClub" });

const { get, post } = useApi();
const auth = useAuth();
const apiBase = useRuntimeConfig().public.baseURL + "/api";

const phase = ref("loading"); // loading | login | denied | dash
const section = ref("dashboard"); // dashboard | sales | managers | notes
const menu = [
  { key: "dashboard", label: "ড্যাশবোর্ড", icon: "📊" },
  { key: "sales", label: "সেলস রিপোর্ট", icon: "📈" },
  { key: "managers", label: "এরিয়া ম্যানেজার", icon: "👥" },
  { key: "payouts", label: "পেআউট রিপোর্ট", icon: "💳" },
  { key: "notes", label: "প্রাইমারি নোট", icon: "📝" },
  { key: "settings", label: "জোন সেটিংস", icon: "⚙️" },
];

const office = ref(null);
const report = ref(null);
const notices = ref([]);
const loadingReport = ref(false);

const loggingIn = ref(false);
const loginError = ref("");
const loginForm = reactive({ email: "", password: "" });
const activeQuick = ref(30);

const today = () => new Date().toISOString().slice(0, 10);
const daysAgo = (n) => new Date(Date.now() - n * 86400000).toISOString().slice(0, 10);
const range = reactive({ from: daysAgo(29), to: today() });

const quickRanges = [
  { label: "আজ", days: 1 },
  { label: "৭ দিন", days: 7 },
  { label: "৩০ দিন", days: 30 },
  { label: "৯০ দিন", days: 90 },
];

const featureLabels = {
  registration: "ইউজার রেজিস্ট্রেশন",
  pro_subscription: "Pro সাবস্ক্রিপশন",
  microgig_post: "মাইক্রোগিগ পোস্ট",
  eshop_order: "eShop অর্ডার",
  mobile_recharge: "মোবাইল রিচার্জ",
  gold_sponsor: "গোল্ড স্পনসর",
  rideshare_driver: "রাইডশেয়ার ড্রাইভার কমিশন",
};
const featureBn = (f) => featureLabels[f] || f;
// Unit word for the count column — "জন" for people-based features, "টি" otherwise.
const countUnits = {
  registration: "জন",
  pro_subscription: "জন",
  rideshare_driver: "টি",
  microgig_post: "টি",
  eshop_order: "টি",
  mobile_recharge: "টি",
  gold_sponsor: "টি",
};
const countUnit = (f) => countUnits[f] || "";
const money = (v) => Number(v || 0).toLocaleString("en-US", { maximumFractionDigits: 0 });
const rateText = (c) => (c.type === "flat" ? `৳${money(c.value)}/টা` : `${c.value}%`);

// Four headline cards — the numbers that matter most, big and colour-coded.
// `sub` clarifies the scope: total users are all-time, the rest are for the
// selected date range.
const heroCards = (t, usersLabel, usersValue, usersSub) => [
  { label: usersLabel, value: (usersValue ?? 0).toLocaleString(), sub: usersSub, icon: "👥", tone: "slate" },
  { label: "নতুন রেজিস্ট্রেশন", value: (t.registrations ?? 0).toLocaleString(), sub: "এই সময়ে নতুন যোগ দিয়েছেন", icon: "📥", tone: "blue" },
  { label: "মোট সেলস", value: `৳${money(t.revenue)}`, sub: "এই সময়ের", icon: "💰", tone: "slate" },
  { label: "মোট কমিশন", value: `৳${money(t.commission)}`, sub: "এই সময়ের", icon: "🏆", tone: "emerald" },
];
const toneText = (tone) =>
  ({ slate: "text-slate-800", blue: "text-blue-600", emerald: "text-emerald-600" }[tone] || "text-slate-800");

// Per-feature sales — one clean row each (icon + label + count + amount).
const salesRows = (t) => [
  { label: "Pro সাবস্ক্রিপশন", icon: "⭐", count: t.pro.count, amount: t.pro.amount },
  { label: "মাইক্রোগিগ পোস্ট", icon: "🧩", count: t.gigs.count, amount: t.gigs.amount },
  { label: "eShop অর্ডার", icon: "🛒", count: t.orders.count, amount: t.orders.amount },
  { label: "মোবাইল রিচার্জ", icon: "📱", count: t.recharges.count, amount: t.recharges.amount },
  { label: "গোল্ড স্পনসর", icon: "🥇", count: t.gold?.count ?? 0, amount: t.gold?.amount ?? 0 },
  { label: "রাইডশেয়ার ফি", icon: "🚗", count: t.rides?.count ?? 0, amount: t.rides?.amount ?? 0 },
];

const dashHero = computed(() =>
  report.value
    ? heroCards(report.value.totals, "জোনের মোট ইউজার", report.value.totals.zone_users, "জোনে সর্বমোট (সব সময়)")
    : []
);
const dashSales = computed(() => (report.value ? salesRows(report.value.totals) : []));

// ---------------- auth + bootstrap ----------------
async function authedFetch(path, options = {}) {
  // For methods useApi doesn't wrap (PATCH/DELETE) — manual $fetch with token.
  const { getValidToken } = useAuth();
  const token = await getValidToken();
  return await $fetch(apiBase + path, {
    ...options,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  });
}

async function loadReport() {
  loadingReport.value = true;
  try {
    const { data, error } = await get(`/zonal/dashboard/?from=${range.from}&to=${range.to}`);
    if (data && !error) {
      report.value = data;
      office.value = data.office;
      phase.value = "dash";
    } else {
      const status = error?.response?.status || error?.statusCode || error?.status;
      phase.value = status === 403 ? "denied" : "login";
    }
  } finally {
    loadingReport.value = false;
  }
}

async function loadNotices() {
  const { data } = await get("/zonal/notices/");
  if (Array.isArray(data)) notices.value = data;
}

function setQuickRange(days) {
  activeQuick.value = days;
  range.from = daysAgo(days - 1);
  range.to = today();
  loadReport();
}
function applyCustomRange() {
  activeQuick.value = 0;
  if (range.from && range.to) loadReport();
}

function goSection(key) {
  section.value = key;
  if (key === "managers" && !managersLoaded.value) loadManagers();
  if (key === "notes" && !notesLoaded.value) loadNotes();
  if (key === "payouts" && !payoutsLoaded.value) loadPayouts();
  if (key === "settings" && !settingsLoaded.value) loadSettings();
}

async function doLogin() {
  loginError.value = "";
  loggingIn.value = true;
  try {
    const res = await auth.login(loginForm.email, loginForm.password);
    if (!res?.loggedIn) {
      loginError.value = res?.message || "ইমেইল বা পাসওয়ার্ড সঠিক নয়।";
      return;
    }
    await loadReport();
    if (phase.value === "dash") loadNotices();
  } catch (e) {
    loginError.value = "লগইন করা যায়নি, আবার চেষ্টা করুন।";
  } finally {
    loggingIn.value = false;
  }
}

async function doLogout() {
  try {
    if (typeof auth.logout === "function") await auth.logout();
  } catch (e) { /* ignore */ }
  report.value = null;
  office.value = null;
  phase.value = "login";
}

// ---------------- area managers ----------------
const managers = ref([]);
const managersLoaded = ref(false);
const areas = ref([]);
const managerView = ref("list"); // list | form | profile
const managerError = ref("");
const savingManager = ref(false);
const managerReport = ref(null);
const mgrQuick = ref(30);
// Manager-profile tabs — everything used to stack on one long page.
const mgrTab = ref("overview");
const mgrTabs = [
  { key: "overview", label: "ওভারভিউ", icon: "📊" },
  { key: "commission", label: "কমিশন", icon: "💰" },
  { key: "services", label: "আমার সেবা", icon: "🛠️" },
  { key: "payouts", label: "পেআউট", icon: "💳" },
];

const emptyCommissions = () =>
  Object.keys(featureLabels).map((f) => ({ feature: f, type: "percent", value: 0 }));

// The zone's own rate per feature — the manager's hard ceiling (their cut is
// carved out of the zone's commission).
const zoneRateMap = computed(() => {
  const map = {};
  (office.value?.commissions || []).forEach((c) => {
    map[c.feature] = { type: c.type, value: Number(c.value || 0) };
  });
  return map;
});
const zoneMax = (feature) => zoneRateMap.value[feature] || { type: "percent", value: 0 };
const zoneMaxText = (feature) => {
  const z = zoneMax(feature);
  if (!z.value) return "আপনার জোন রেট ০ — দেওয়া যাবে না";
  return z.type === "flat" ? `৳${money(z.value)}/টা (আপনার জোন রেট)` : `${z.value}% (আপনার জোন রেট)`;
};
const rowOverLimit = (row) => {
  if (!row.value || row.value <= 0) return false;
  const z = zoneMax(row.feature);
  if (!z.value) return true;             // zone earns nothing here
  if (row.type !== z.type) return true;  // type must match the zone's
  return Number(row.value) > z.value;    // can't exceed the zone's rate
};
const blankPayout = () => ({
  payout_method: "", payout_account_name: "", payout_account_number: "",
  payout_bank_name: "", payout_bank_branch: "",
});
const managerForm = reactive({
  id: null, name: "", phone: "", area: "",
  commissions: emptyCommissions(), ...blankPayout(),
});
const mgrBalance = ref(null);
const mgrInvoices = ref([]);

async function loadManagers() {
  const { data } = await get("/zonal/managers/");
  if (Array.isArray(data)) {
    managers.value = data;
    managersLoaded.value = true;
  }
  if (!areas.value.length) {
    const { data: a } = await get("/zonal/areas/");
    if (Array.isArray(a)) areas.value = a;
  }
}

function startNewManager() {
  Object.assign(managerForm, {
    id: null, name: "", phone: "", area: "",
    commissions: emptyCommissions(), ...blankPayout(),
  });
  managerError.value = "";
  managerView.value = "form";
}

function startEditManager(m) {
  const rows = emptyCommissions();
  (m.commissions || []).forEach((c) => {
    const row = rows.find((r) => r.feature === c.feature);
    if (row) { row.type = c.type; row.value = c.value; }
  });
  Object.assign(managerForm, {
    id: m.id, name: m.name, phone: m.phone, area: m.area, commissions: rows,
    payout_method: m.payout_method || "",
    payout_account_name: m.payout_account_name || "",
    payout_account_number: m.payout_account_number || "",
    payout_bank_name: m.payout_bank_name || "",
    payout_bank_branch: m.payout_bank_branch || "",
  });
  managerError.value = "";
  managerView.value = "form";
}

async function saveManager() {
  managerError.value = "";
  // Client-side ceiling check (server enforces the same rule).
  const bad = managerForm.commissions.find((r) => rowOverLimit(r));
  if (bad) {
    const z = zoneMax(bad.feature);
    managerError.value = z.value
      ? `${featureBn(bad.feature)}-এ সর্বোচ্চ ${z.type === "flat" ? "৳" + money(z.value) + "/টা" : z.value + "%"} দেওয়া যাবে (আপনার জোন রেট${bad.type !== z.type ? ", একই ধরন বেছে নিন" : ""})।`
      : `${featureBn(bad.feature)}-এ আপনার জোন রেট ০ — ম্যানেজারকে কমিশন দেওয়া যাবে না।`;
    return;
  }
  savingManager.value = true;
  try {
    const payload = {
      name: managerForm.name,
      phone: managerForm.phone,
      area: managerForm.area,
      commissions: managerForm.commissions.map((r) => ({ feature: r.feature, type: r.type, value: r.value || 0 })),
      payout_method: managerForm.payout_method,
      payout_account_name: managerForm.payout_account_name,
      payout_account_number: managerForm.payout_account_number,
      payout_bank_name: managerForm.payout_bank_name,
      payout_bank_branch: managerForm.payout_bank_branch,
    };
    if (managerForm.id) {
      await authedFetch(`/zonal/managers/${managerForm.id}/`, { method: "PATCH", body: payload });
    } else {
      const { data, error } = await post("/zonal/managers/", payload);
      if (error || !data) {
        managerError.value = error?.response?._data?.detail || error?.data?.detail || "সেভ করা যায়নি, আবার চেষ্টা করুন।";
        return;
      }
    }
    managersLoaded.value = false;
    await loadManagers();
    managerView.value = "list";
  } catch (e) {
    managerError.value = e?.response?._data?.detail || e?.data?.detail || "সেভ করা যায়নি, আবার চেষ্টা করুন।";
  } finally {
    savingManager.value = false;
  }
}

async function openManager(m) {
  managerView.value = "profile";
  mgrTab.value = "overview";
  managerReport.value = null;
  mgrBalance.value = null;
  mgrInvoices.value = [];
  await loadManagerReport(m.id, 30);
  const { data } = await get(`/zonal/managers/${m.id}/balance/`);
  if (data) {
    mgrBalance.value = data.balance;
    mgrInvoices.value = data.invoices || [];
  }
}

const mgrRange = reactive({ from: daysAgo(29), to: today() });

async function loadManagerReport(id, days) {
  mgrQuick.value = days;
  const from = daysAgo(days - 1);
  const to = today();
  mgrRange.from = from;
  mgrRange.to = to;
  const { data } = await get(`/zonal/managers/${id}/report/?from=${from}&to=${to}`);
  if (data) managerReport.value = data;
}

async function loadManagerReportCustom(id) {
  if (!mgrRange.from || !mgrRange.to) return;
  mgrQuick.value = 0; // custom range active — unhighlight quick chips
  const { data } = await get(
    `/zonal/managers/${id}/report/?from=${mgrRange.from}&to=${mgrRange.to}`
  );
  if (data) managerReport.value = data;
}

const mgrHero = computed(() =>
  managerReport.value
    ? heroCards(managerReport.value.totals, "এলাকার মোট ইউজার", managerReport.value.totals.area_users, "এলাকায় সর্বমোট (সব সময়)")
    : []
);
const mgrSales = computed(() => (managerReport.value ? salesRows(managerReport.value.totals) : []));

async function deleteManager(m) {
  if (!confirm(`"${m.name}" ম্যানেজারকে ডিলিট করবেন?`)) return;
  try {
    await authedFetch(`/zonal/managers/${m.id}/`, { method: "DELETE" });
    managersLoaded.value = false;
    await loadManagers();
    managerView.value = "list";
  } catch (e) { /* keep view */ }
}

// ---------------- primary notes ----------------
const notes = ref([]);
const notesLoaded = ref(false);
const savingNote = ref(false);
const noteForm = reactive({ id: null, title: "", body: "" });
// Soft sticky-note palettes, cycled across the grid.
const noteColors = [
  "bg-amber-50 border-amber-200",
  "bg-emerald-50 border-emerald-200",
  "bg-sky-50 border-sky-200",
  "bg-rose-50 border-rose-200",
  "bg-violet-50 border-violet-200",
  "bg-lime-50 border-lime-200",
];

async function loadNotes() {
  const { data } = await get("/zonal/notes/");
  if (Array.isArray(data)) {
    notes.value = data;
    notesLoaded.value = true;
  }
}
function resetNoteForm() {
  Object.assign(noteForm, { id: null, title: "", body: "" });
}
function editNote(n) {
  Object.assign(noteForm, { id: n.id, title: n.title, body: n.body });
}
async function saveNote() {
  if (!noteForm.title.trim()) return;
  savingNote.value = true;
  try {
    if (noteForm.id) {
      await authedFetch(`/zonal/notes/${noteForm.id}/`, {
        method: "PATCH",
        body: { title: noteForm.title, body: noteForm.body },
      });
    } else {
      await post("/zonal/notes/", { title: noteForm.title, body: noteForm.body });
    }
    resetNoteForm();
    await loadNotes();
  } finally {
    savingNote.value = false;
  }
}
async function deleteNote(n) {
  if (!confirm(`"${n.title}" নোটটি ডিলিট করবেন?`)) return;
  try {
    await authedFetch(`/zonal/notes/${n.id}/`, { method: "DELETE" });
    await loadNotes();
  } catch (e) { /* ignore */ }
}

// ---------------- balance & payouts (invoices) ----------------
const balance = ref(null);
const invoices = ref([]);
const payoutsLoaded = ref(false);

async function loadBalance() {
  const { data } = await get("/zonal/balance/");
  if (data) balance.value = data;
}
async function loadPayouts() {
  await loadBalance();
  const { data } = await get("/zonal/invoices/");
  if (Array.isArray(data)) invoices.value = data;
  payoutsLoaded.value = true;
}
const payMethodBn = (m) =>
  ({ bkash: "bKash", nagad: "Nagad", rocket: "Rocket", bank: "Bank" }[m] || m || "—");

// ---------------- zone settings ----------------
const settingsData = ref(null);
const settingsLoaded = ref(false);
const savingSettings = ref(false);
const settingsSaved = ref(false);
const settingsForm = reactive({
  contact_phone: "", office_address: "", nid_number: "",
  payout_method: "", payout_account_name: "", payout_account_number: "",
  payout_bank_name: "", payout_bank_branch: "", payout_routing_number: "",
});

async function loadSettings() {
  const { data } = await get("/zonal/settings/");
  if (data) {
    settingsData.value = data;
    Object.keys(settingsForm).forEach((k) => {
      settingsForm[k] = data[k] || "";
    });
    settingsLoaded.value = true;
  }
}

async function saveSettings() {
  savingSettings.value = true;
  settingsSaved.value = false;
  try {
    const data = await authedFetch("/zonal/settings/", {
      method: "PATCH",
      body: { ...settingsForm },
    });
    if (data) {
      settingsData.value = data;
      settingsSaved.value = true;
      setTimeout(() => (settingsSaved.value = false), 2500);
    }
  } catch (e) { /* keep form values */ }
  finally {
    savingSettings.value = false;
  }
}

// ---------------- mount ----------------
onMounted(async () => {
  const { data, error } = await get("/zonal/me/");
  if (data && !error) {
    office.value = data;
    await loadReport();
    loadNotices();
    loadBalance(); // sidebar balance card
  } else {
    const status = error?.response?.status || error?.statusCode || error?.status;
    phase.value = status === 403 ? "denied" : "login";
  }
});
</script>
