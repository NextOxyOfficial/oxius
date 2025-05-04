export function useNotifications() {
  const { get, put } = useApi();
  const { user } = useAuth();
  const unreadCount = useState("notificationUnreadCount", () => 0);
  const isLoading = ref(false);

  // Function to fetch unread notification count
  async function fetchUnreadCount() {
    // Don't attempt to fetch if user isn't logged in
    if (!user.value?.user?.id) {
      console.log("User not logged in, skipping notification count fetch");
      return;
    }

    try {
      isLoading.value = true;
      const res = await get("/bn/notifications/unread-count/");

      if (res.data && typeof res.data.count === "number") {
        unreadCount.value = res.data.count;
      }
    } catch (error) {
      console.error("Error fetching unread notification count:", error);
      // Reset count on error to ensure we don't show outdated data
      unreadCount.value = 0;
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

  return {
    unreadCount,
    isLoading,
    fetchUnreadCount,
    markAllAsRead,
    decrementCount,
  };
}
