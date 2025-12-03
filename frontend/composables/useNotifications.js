export function useNotifications() {
  const { get, put } = useApi();
  const { user } = useAuth();
  const unreadCount = useState("notificationUnreadCount", () => 0);
  const workspaceUnreadCount = useState("workspaceUnreadCount", () => 0);
  const totalUnreadCount = computed(() => unreadCount.value + workspaceUnreadCount.value);
  const isLoading = ref(false);

  // Function to fetch unread notification count (both BN and workspace)
  async function fetchUnreadCount() {
    // Don't attempt to fetch if user isn't logged in or token not available
    if (!user.value?.user?.id || !user.value?.token) {
      return;
    }

    try {
      isLoading.value = true;
      
      // Fetch both BN notifications and workspace message counts in parallel
      const [bnRes, workspaceRes] = await Promise.all([
        get("/bn/notifications/unread-count/").catch(() => ({ data: { count: 0 } })),
        get("/workspace/orders/unread-counts/").catch(() => ({ data: { total: 0 } }))
      ]);

      if (bnRes.data && typeof bnRes.data.count === "number") {
        unreadCount.value = bnRes.data.count;
      }
      
      if (workspaceRes.data && typeof workspaceRes.data.total === "number") {
        workspaceUnreadCount.value = workspaceRes.data.total;
      }
    } catch (error) {
      // Silently handle - user may not be fully authenticated yet
      unreadCount.value = 0;
      workspaceUnreadCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  // Mark all notifications as read
  async function markAllAsRead() {
    if (!user.value?.user?.id) return;

    try {
      await put("/bn/notifications/mark-all-read/");
      unreadCount.value = 0;
    } catch (error) {
      console.error("Error marking all notifications as read:", error);
    }
  }

  // Update count (after one notification is marked as read)
  function decrementCount() {
    if (unreadCount.value > 0) {
      unreadCount.value--;
    }
  }

  // Decrement workspace count
  function decrementWorkspaceCount() {
    if (workspaceUnreadCount.value > 0) {
      workspaceUnreadCount.value--;
    }
  }

  // Reset workspace count for a specific order
  function clearWorkspaceOrderCount(orderId, count = 0) {
    if (count > 0) {
      workspaceUnreadCount.value = Math.max(0, workspaceUnreadCount.value - count);
    }
  }

  return {
    unreadCount,
    workspaceUnreadCount,
    totalUnreadCount,
    isLoading,
    fetchUnreadCount,
    markAllAsRead,
    decrementCount,
    decrementWorkspaceCount,
    clearWorkspaceOrderCount,
  };
}
