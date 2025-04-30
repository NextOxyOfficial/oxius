<template>
  <div class="min-h-screen bg-slate-50 dark:bg-slate-900">
    <!-- Loading State -->
    <div v-if="isLoading" class="min-h-screen flex items-center justify-center">
      <div class="flex flex-col items-center">
        <div class="w-16 h-16 relative">
          <div
            class="absolute inset-0 rounded-full border-4 border-t-emerald-500 border-slate-200 dark:border-slate-700 animate-spin"
          ></div>
        </div>
        <p class="mt-4 text-slate-600 dark:text-slate-400">
          Verifying credentials...
        </p>
      </div>
    </div>

    <!-- Admin Login (shown to non-admins) -->
    <div
      v-else-if="!isAdmin"
      class="min-h-screen flex items-center justify-center p-4"
    >
      <div
        class="max-w-md w-full bg-white dark:bg-slate-800 rounded-xl shadow-lg border border-slate-200 dark:border-slate-700 overflow-hidden"
      >
        <div class="p-8">
          <div class="text-center mb-6">
            <UIcon
              name="i-heroicons-shield-check"
              class="w-12 h-12 mx-auto text-emerald-500 dark:text-emerald-400"
            />
            <h2 class="mt-4 text-2xl font-bold text-slate-900 dark:text-white">
              Admin Control Center
            </h2>
            <p class="mt-2 text-slate-600 dark:text-slate-400">
              Please sign in with admin credentials
            </p>
          </div>

          <div
            v-if="authError"
            class="mb-6 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800/20 rounded-lg"
          >
            <div class="flex">
              <UIcon
                name="i-heroicons-exclamation-triangle"
                class="h-5 w-5 text-red-500 dark:text-red-400 mr-3"
              />
              <p class="text-sm text-red-600 dark:text-red-400">
                {{ authError }}
              </p>
            </div>
          </div>

          <form @submit.prevent="handleAdminLogin" class="space-y-6">
            <div>
              <label
                for="username"
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
              >
                Username
              </label>
              <input
                v-model="adminLoginForm.username"
                id="username"
                type="text"
                class="block w-full rounded-md border border-slate-300 dark:border-slate-600 py-2 px-3 shadow-sm placeholder-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500 dark:bg-slate-700 dark:text-white"
                placeholder="Enter your username"
              />
            </div>

            <div>
              <label
                for="password"
                class="block text-sm font-medium text-slate-700 dark:text-slate-300 mb-1"
              >
                Password
              </label>
              <input
                v-model="adminLoginForm.password"
                id="password"
                type="password"
                class="block w-full rounded-md border border-slate-300 dark:border-slate-600 py-2 px-3 shadow-sm placeholder-slate-400 focus:border-emerald-500 focus:outline-none focus:ring-1 focus:ring-emerald-500 dark:bg-slate-700 dark:text-white"
                placeholder="Enter your password"
              />
            </div>

            <div>
              <UButton
                type="submit"
                color="emerald"
                block
                :loading="isLoginLoading"
              >
                Sign in as Admin
              </UButton>
            </div>
          </form>

          <div class="mt-6 text-center">
            <NuxtLink
              to="/"
              class="text-sm text-emerald-600 dark:text-emerald-400 hover:underline"
            >
              Return to Home
            </NuxtLink>
          </div>
        </div>

        <div class="bg-slate-50 dark:bg-slate-700/30 px-8 py-4">
          <p class="text-xs text-slate-500 dark:text-slate-400">
            This area is restricted to administrative personnel only.
            Unauthorized access attempts are monitored and logged.
          </p>
        </div>
      </div>
    </div>

    <!-- Admin Dashboard with Sidebar (only shown to admins) -->
    <div v-else class="flex h-screen overflow-hidden">
      <!-- Sidebar -->
      <div
        class="sidebar-container fixed z-20 inset-y-0 left-0 w-64 transform transition-transform duration-300 ease-in-out lg:static lg:translate-x-0 bg-white dark:bg-slate-800 border-r border-slate-200 dark:border-slate-700 flex flex-col"
        :class="{ '-translate-x-full': !sidebarOpen }"
      >
        <!-- Sidebar Header -->
        <div
          class="flex justify-between items-center h-16 px-4 border-b border-slate-200 dark:border-slate-700"
        >
          <div class="flex items-center space-x-3">
            <UIcon
              name="i-heroicons-rectangle-stack"
              class="w-7 h-7 text-emerald-500"
            />
            <span class="text-lg font-semibold text-slate-900 dark:text-white"
              >Admin Center</span
            >
          </div>
          <button
            class="lg:hidden text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300"
            @click="sidebarOpen = !sidebarOpen"
          >
            <UIcon name="i-heroicons-x-mark" class="w-6 h-6" />
          </button>
        </div>

        <!-- Sidebar User -->
        <div class="p-4 border-b border-slate-200 dark:border-slate-700">
          <div class="flex items-center">
            <UAvatar
              :src="user?.user?.image"
              :alt="user?.user?.username || 'Admin'"
              size="md"
              class="mr-3"
            />
            <div>
              <div class="font-medium text-slate-900 dark:text-white">
                {{ user?.user?.first_name || user?.user?.username || "Admin" }}
              </div>
              <div class="text-xs text-slate-500 dark:text-slate-400">
                {{ user?.user?.email || "admin@example.com" }}
              </div>
            </div>
          </div>
        </div>

        <!-- Sidebar Navigation -->
        <div class="flex-grow overflow-y-auto">
          <nav class="mt-4 px-2">
            <div
              class="mb-2 px-3 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase"
            >
              Management
            </div>

            <div
              v-for="(item, index) in sidebarItems"
              :key="`menu-${index}`"
              class="mb-1"
            >
              <button
                class="w-full flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-colors"
                :class="
                  selectedMenu === item.id
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                    : 'text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-700/30'
                "
                @click="selectMenu(item.id)"
              >
                <UIcon :name="item.icon" class="w-5 h-5 mr-3" />
                <span>{{ item.label }}</span>

                <!-- Badge for items with count -->
                <div v-if="item.count" class="ml-auto">
                  <UBadge
                    :color="selectedMenu === item.id ? 'emerald' : 'gray'"
                    size="sm"
                  >
                    {{ item.count }}
                  </UBadge>
                </div>
              </button>
            </div>

            <div
              class="my-4 border-t border-slate-200 dark:border-slate-700"
            ></div>

            <div
              class="mb-2 px-3 text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase"
            >
              System
            </div>

            <div
              v-for="(item, index) in systemItems"
              :key="`system-${index}`"
              class="mb-1"
            >
              <button
                class="w-full flex items-center px-3 py-2 rounded-lg text-sm font-medium transition-colors"
                :class="
                  selectedMenu === item.id
                    ? 'bg-emerald-50 text-emerald-700 dark:bg-emerald-900/20 dark:text-emerald-400'
                    : 'text-slate-700 hover:bg-slate-100 dark:text-slate-300 dark:hover:bg-slate-700/30'
                "
                @click="selectMenu(item.id)"
              >
                <UIcon :name="item.icon" class="w-5 h-5 mr-3" />
                <span>{{ item.label }}</span>
              </button>
            </div>
          </nav>
        </div>

        <!-- Sidebar Footer -->
        <div class="p-4 border-t border-slate-200 dark:border-slate-700">
          <UButton
            color="red"
            variant="ghost"
            block
            @click="handleLogout"
            icon="i-heroicons-arrow-right-on-rectangle"
          >
            Sign Out
          </UButton>
        </div>
      </div>

      <!-- Main Content -->
      <div class="flex-1 flex flex-col overflow-hidden">
        <!-- Top Header -->
        <header
          class="bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 h-16 flex items-center"
        >
          <div class="flex items-center justify-between w-full px-4">
            <div class="flex items-center">
              <!-- Mobile menu button -->
              <button
                class="lg:hidden text-slate-500 hover:text-slate-600 dark:text-slate-400 dark:hover:text-slate-300 mr-3"
                @click="sidebarOpen = !sidebarOpen"
              >
                <UIcon name="i-heroicons-bars-3" class="w-6 h-6" />
              </button>

              <h1 class="text-lg font-medium text-slate-900 dark:text-white">
                {{ currentMenuTitle }}
              </h1>
            </div>

            <div class="flex items-center space-x-3">
              <UButton
                color="gray"
                variant="ghost"
                icon="i-heroicons-arrow-path"
                :loading="isRefreshing"
                @click="refreshData"
              >
                Refresh
              </UButton>

              <div class="relative">
                <UButton
                  color="gray"
                  variant="ghost"
                  icon="i-heroicons-bell"
                  :ui="{ rounded: 'rounded-full' }"
                  class="relative"
                >
                  <span
                    class="absolute -top-1 -right-1 h-4 w-4 rounded-full bg-red-500 flex items-center justify-center text-white text-xs"
                  >
                    3
                  </span>
                </UButton>
              </div>

              <UThemeToggle />
            </div>
          </div>
        </header>

        <!-- Main Content Area -->
        <main class="flex-1 overflow-y-auto bg-slate-50 dark:bg-slate-900 p-4">
          <!-- Dashboard (Dynamic Content Based on Selected Menu) -->
          <div v-if="selectedMenu === 'dashboard'" class="space-y-6">
            <!-- Dashboard Stats -->
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div
                class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 p-4"
              >
                <div class="flex items-center">
                  <div
                    class="p-3 rounded-lg bg-emerald-100 dark:bg-emerald-900/30 text-emerald-600 dark:text-emerald-400 mr-4"
                  >
                    <UIcon name="i-heroicons-users" class="w-6 h-6" />
                  </div>
                  <div>
                    <p class="text-sm text-slate-500 dark:text-slate-400">
                      Total Users
                    </p>
                    <p
                      class="text-2xl font-bold text-slate-900 dark:text-white"
                    >
                      {{ dashboardStats.totalUsers }}
                    </p>
                  </div>
                </div>
              </div>

              <div
                class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 p-4"
              >
                <div class="flex items-center">
                  <div
                    class="p-3 rounded-lg bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 mr-4"
                  >
                    <UIcon name="i-heroicons-shopping-cart" class="w-6 h-6" />
                  </div>
                  <div>
                    <p class="text-sm text-slate-500 dark:text-slate-400">
                      Total Orders
                    </p>
                    <p
                      class="text-2xl font-bold text-slate-900 dark:text-white"
                    >
                      {{ dashboardStats.totalOrders }}
                    </p>
                  </div>
                </div>
              </div>

              <div
                class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 p-4"
              >
                <div class="flex items-center">
                  <div
                    class="p-3 rounded-lg bg-purple-100 dark:bg-purple-900/30 text-purple-600 dark:text-purple-400 mr-4"
                  >
                    <UIcon name="i-heroicons-banknotes" class="w-6 h-6" />
                  </div>
                  <div>
                    <p class="text-sm text-slate-500 dark:text-slate-400">
                      Revenue
                    </p>
                    <p
                      class="text-2xl font-bold text-slate-900 dark:text-white"
                    >
                      ${{ dashboardStats.totalRevenue.toFixed(2) }}
                    </p>
                  </div>
                </div>
              </div>

              <div
                class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 p-4"
              >
                <div class="flex items-center">
                  <div
                    class="p-3 rounded-lg bg-amber-100 dark:bg-amber-900/30 text-amber-600 dark:text-amber-400 mr-4"
                  >
                    <UIcon name="i-heroicons-tag" class="w-6 h-6" />
                  </div>
                  <div>
                    <p class="text-sm text-slate-500 dark:text-slate-400">
                      Products
                    </p>
                    <p
                      class="text-2xl font-bold text-slate-900 dark:text-white"
                    >
                      {{ dashboardStats.totalProducts }}
                    </p>
                  </div>
                </div>
              </div>
            </div>

            <!-- Recent Activity -->
            <div
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
            >
              <div
                class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center"
              >
                <h2 class="font-medium text-slate-900 dark:text-white">
                  Recent Activity
                </h2>
                <UButton color="gray" variant="ghost" size="sm"
                  >View all</UButton
                >
              </div>

              <div class="overflow-x-auto">
                <table
                  class="min-w-full divide-y divide-slate-200 dark:divide-slate-700"
                >
                  <thead>
                    <tr>
                      <th
                        class="px-6 py-3 bg-slate-50 dark:bg-slate-800/50 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"
                      >
                        User
                      </th>
                      <th
                        class="px-6 py-3 bg-slate-50 dark:bg-slate-800/50 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"
                      >
                        Action
                      </th>
                      <th
                        class="px-6 py-3 bg-slate-50 dark:bg-slate-800/50 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"
                      >
                        Date
                      </th>
                      <th
                        class="px-6 py-3 bg-slate-50 dark:bg-slate-800/50 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider"
                      >
                        Status
                      </th>
                    </tr>
                  </thead>
                  <tbody
                    class="bg-white dark:bg-slate-800 divide-y divide-slate-200 dark:divide-slate-700"
                  >
                    <tr
                      v-for="(activity, index) in recentActivity"
                      :key="index"
                      class="hover:bg-slate-50 dark:hover:bg-slate-700/20"
                    >
                      <td class="px-6 py-4 whitespace-nowrap">
                        <div class="flex items-center">
                          <UAvatar
                            :src="
                              activity.user.image ||
                              '/static/frontend/avatar.png'
                            "
                            size="sm"
                            class="mr-3"
                          />
                          <div>
                            <div
                              class="text-sm font-medium text-slate-900 dark:text-white"
                            >
                              {{ activity.user.name }}
                            </div>
                            <div
                              class="text-xs text-slate-500 dark:text-slate-400"
                            >
                              {{ activity.user.email }}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-slate-700 dark:text-slate-300"
                      >
                        {{ activity.action }}
                      </td>
                      <td
                        class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400"
                      >
                        {{ activity.date }}
                      </td>
                      <td class="px-6 py-4 whitespace-nowrap">
                        <UBadge
                          :color="activity.statusColor"
                          variant="soft"
                          size="sm"
                        >
                          {{ activity.status }}
                        </UBadge>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <!-- Users Management -->
          <div v-else-if="selectedMenu === 'users'" class="space-y-6">
            <div
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
            >
              <div
                class="px-6 py-4 border-b border-slate-200 dark:border-slate-700 flex justify-between items-center flex-wrap gap-4"
              >
                <h2 class="font-medium text-slate-900 dark:text-white">
                  User Management
                </h2>

                <div class="flex space-x-2">
                  <UInput
                    icon="i-heroicons-magnifying-glass"
                    placeholder="Search users..."
                    size="sm"
                    class="w-64"
                  />
                  <UButton color="emerald" icon="i-heroicons-plus" size="sm">
                    Add User
                  </UButton>
                </div>
              </div>

              <div class="p-6">
                <p class="text-slate-600 dark:text-slate-400">
                  User management content will be displayed here.
                </p>
              </div>
            </div>
          </div>

          <!-- Orders Management -->
          <div v-else-if="selectedMenu === 'orders'" class="space-y-6">
            <div
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
            >
              <div
                class="px-6 py-4 border-b border-slate-200 dark:border-slate-700"
              >
                <h2 class="font-medium text-slate-900 dark:text-white">
                  Orders Management
                </h2>
              </div>
              <div class="p-6">
                <p class="text-slate-600 dark:text-slate-400">
                  Orders management content will be displayed here.
                </p>
              </div>
            </div>
          </div>

          <!-- Products Management -->
          <div v-else-if="selectedMenu === 'products'" class="space-y-6">
            <div
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
            >
              <div
                class="px-6 py-4 border-b border-slate-200 dark:border-slate-700"
              >
                <h2 class="font-medium text-slate-900 dark:text-white">
                  Products Management
                </h2>
              </div>
              <div class="p-6">
                <p class="text-slate-600 dark:text-slate-400">
                  Products management content will be displayed here.
                </p>
              </div>
            </div>
          </div>

          <!-- Settings -->
          <div v-else-if="selectedMenu === 'settings'" class="space-y-6">
            <div
              class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 overflow-hidden"
            >
              <div
                class="px-6 py-4 border-b border-slate-200 dark:border-slate-700"
              >
                <h2 class="font-medium text-slate-900 dark:text-white">
                  System Settings
                </h2>
              </div>
              <div class="p-6">
                <p class="text-slate-600 dark:text-slate-400">
                  System settings content will be displayed here.
                </p>
              </div>
            </div>
          </div>

          <!-- Placeholder for other content -->
          <div
            v-else
            class="bg-white dark:bg-slate-800 rounded-xl shadow-sm border border-slate-200 dark:border-slate-700 p-6"
          >
            <p class="text-slate-600 dark:text-slate-400">
              Select an option from the sidebar to view content.
            </p>
          </div>
        </main>
      </div>
    </div>

    <!-- Mobile Backdrop -->
    <div
      v-if="sidebarOpen"
      class="fixed inset-0 bg-black bg-opacity-50 z-10 lg:hidden"
      @click="sidebarOpen = false"
    ></div>
  </div>
</template>

<script setup>
const { user, login, jwtLogin, logout } = useAuth();
const router = useRouter();
const toast = useToast();

// State management
const isLoading = ref(true);
const isRefreshing = ref(false);
const isLoginLoading = ref(false);
const authError = ref("");
const sidebarOpen = ref(false);
const selectedMenu = ref("dashboard");

const adminLoginForm = ref({
  username: "",
  password: "",
});

// Sidebar navigation items
const sidebarItems = ref([
  {
    id: "dashboard",
    label: "Dashboard",
    icon: "i-heroicons-home",
  },
  {
    id: "users",
    label: "Users",
    icon: "i-heroicons-users",
    count: 12,
  },
  {
    id: "orders",
    label: "Orders",
    icon: "i-heroicons-shopping-cart",
    count: 8,
  },
  {
    id: "products",
    label: "Products",
    icon: "i-heroicons-tag",
  },
]);

const systemItems = ref([
  {
    id: "settings",
    label: "Settings",
    icon: "i-heroicons-cog-6-tooth",
  },
  {
    id: "logs",
    label: "System Logs",
    icon: "i-heroicons-document-text",
  },
]);

// Dashboard data
const dashboardStats = ref({
  totalUsers: 0,
  totalOrders: 0,
  totalRevenue: 0,
  totalProducts: 0,
});

const recentActivity = ref([]);

// Get current menu title
const currentMenuTitle = computed(() => {
  const allItems = [...sidebarItems.value, ...systemItems.value];
  const currentItem = allItems.find((item) => item.id === selectedMenu.value);
  return currentItem ? currentItem.label : "Dashboard";
});

// Check if the current user is an admin
const isAdmin = computed(() => {
  return (
    user.value?.user?.is_superuser === true ||
    user.value?.user?.user_type === "admin"
  );
});

// Initialize on component mount
onMounted(async () => {
  try {
    // Verify the user's authentication status
    await jwtLogin();

    // If user is admin, load dashboard data
    if (isAdmin.value) {
      loadDashboardData();
    }
  } catch (error) {
    console.error("Authentication error:", error);
  } finally {
    isLoading.value = false;
  }
});

// Handle menu selection
function selectMenu(menuId) {
  selectedMenu.value = menuId;
  // On mobile, close the sidebar after selection
  if (window.innerWidth < 1024) {
    sidebarOpen.value = false;
  }
}

// Load dashboard data (mock data for demonstration)
async function loadDashboardData() {
  try {
    isRefreshing.value = true;
    // In a real implementation, you would fetch data from your API
    dashboardStats.value = {
      totalUsers: 1248,
      totalOrders: 864,
      totalRevenue: 28650.75,
      totalProducts: 352,
    };

    // Mock recent activity data
    recentActivity.value = [
      {
        user: {
          name: "John Smith",
          email: "john@example.com",
          image: "https://i.pravatar.cc/150?img=1",
        },
        action: "Created a new product",
        date: "2 hours ago",
        status: "Completed",
        statusColor: "emerald",
      },
      {
        user: {
          name: "Sarah Johnson",
          email: "sarah@example.com",
          image: "https://i.pravatar.cc/150?img=5",
        },
        action: "Updated inventory",
        date: "4 hours ago",
        status: "Completed",
        statusColor: "emerald",
      },
      {
        user: {
          name: "Michael Brown",
          email: "michael@example.com",
          image: "https://i.pravatar.cc/150?img=8",
        },
        action: "Processed refund",
        date: "Yesterday",
        status: "Pending",
        statusColor: "amber",
      },
      {
        user: {
          name: "Emily Wilson",
          email: "emily@example.com",
          image: "https://i.pravatar.cc/150?img=9",
        },
        action: "Customer support ticket",
        date: "2 days ago",
        status: "Resolved",
        statusColor: "blue",
      },
      {
        user: {
          name: "Robert Davis",
          email: "robert@example.com",
          image: "https://i.pravatar.cc/150?img=3",
        },
        action: "Deleted product",
        date: "3 days ago",
        status: "Cancelled",
        statusColor: "red",
      },
    ];
  } catch (error) {
    console.error("Error loading dashboard data:", error);
    toast.add({
      title: "Error",
      description: "Failed to load dashboard data",
      color: "red",
    });
  } finally {
    isRefreshing.value = false;
  }
}

// Refresh dashboard data
async function refreshData() {
  await loadDashboardData();
  toast.add({
    title: "Data Refreshed",
    description: "Dashboard data has been updated",
    color: "emerald",
  });
}

// Handle admin login
async function handleAdminLogin() {
  // Reset error message
  authError.value = "";

  // Validate form
  if (!adminLoginForm.value.username || !adminLoginForm.value.password) {
    authError.value = "Please enter both username and password";
    return;
  }

  isLoginLoading.value = true;

  try {
    // Attempt login
    const credentials = {
      username: adminLoginForm.value.username,
      password: adminLoginForm.value.password,
    };

    const response = await login(credentials);

    // Check if the user is an admin
    if (response?.user?.is_superuser || response?.user?.user_type === "admin") {
      // Login successful as admin
      await jwtLogin(); // Refresh JWT token
      loadDashboardData();

      toast.add({
        title: "Logged In",
        description: "Welcome to the Admin Control Center",
        color: "emerald",
      });
    } else {
      // User is not an admin
      authError.value = "Access denied. Admin privileges required.";
      await logout(); // Logout non-admin user
    }
  } catch (error) {
    console.error("Login error:", error);
    authError.value = error?.response?.data?.message || "Invalid credentials";
  } finally {
    isLoginLoading.value = false;
  }
}

// Handle logout
async function handleLogout() {
  try {
    await logout();
    router.push("/");

    toast.add({
      title: "Logged Out",
      description: "You have been successfully logged out",
      color: "blue",
    });
  } catch (error) {
    console.error("Logout error:", error);
  }
}
</script>

<style scoped>
/* Add any custom styles here */
.slide-enter-active,
.slide-leave-active {
  transition: all 0.3s;
}
.slide-enter-from,
.slide-leave-to {
  opacity: 0;
  transform: translateX(-20px);
}

@media (max-width: 1023px) {
  .sidebar-container {
    box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
  }
}
</style>
