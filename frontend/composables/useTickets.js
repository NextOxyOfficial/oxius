/**
 * Composable for handling support tickets and their unread status
 */
export function useTickets() {
  const { get, post } = useApi();
  const { user } = useAuth();
  const unreadTicketCount = useState("ticketUnreadCount", () => 0);
  const unreadUpdatesCount = useState("updatesUnreadCount", () => 0);
  const totalUnreadCount = computed(() => unreadTicketCount.value + unreadUpdatesCount.value);
  const isLoading = ref(false);

  /**
   * Fetch unread ticket and updates count
   */
  async function fetchUnreadCount() {
    if (!user.value?.user?.id) {
      console.log("User not logged in, skipping ticket count fetch");
      return;
    }

    try {
      isLoading.value = true;
      
      // Fetch unread tickets
      const ticketsRes = await get("/tickets/");
      if (ticketsRes.data && Array.isArray(ticketsRes.data)) {
        // Count tickets that have is_unread flag set to true
        unreadTicketCount.value = ticketsRes.data.filter(ticket => ticket.is_unread).length;
      }

      // Fetch unread updates (admin notices)
      const updatesRes = await get("/admin-notice/", {
        params: {
          user_specific: true
        }
      });
      if (updatesRes.data && Array.isArray(updatesRes.data)) {
        // Count updates that have is_read flag set to false
        unreadUpdatesCount.value = updatesRes.data.filter(update => !update.is_read).length;
      }
    } catch (error) {
      console.error("Error fetching unread counts:", error);
      // Reset counts on error to ensure we don't show outdated data
      unreadTicketCount.value = 0;
      unreadUpdatesCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }
  /**
   * Mark all tickets and updates as read
   */
  async function markAllAsRead() {
    if (!user.value?.user?.id) return;

    try {
      // Get all unread tickets first
      const ticketsRes = await get("/tickets/");
      if (ticketsRes.data && Array.isArray(ticketsRes.data)) {
        // Mark each unread ticket as read
        const unreadTickets = ticketsRes.data.filter(ticket => ticket.is_unread);
        for (const ticket of unreadTickets) {
          await post(`/tickets/${ticket.id}/mark-read/`, {});
        }
      }

      // Get all unread updates and mark them as read
      const updatesRes = await get("/admin-notice/", {
        params: {
          user_specific: true
        }
      });
      if (updatesRes.data && Array.isArray(updatesRes.data)) {
        const unreadUpdates = updatesRes.data.filter(update => !update.is_read);
        for (const update of unreadUpdates) {
          await post(`/admin-notice/${update.id}/mark-read/`, {});
        }
      }

      unreadTicketCount.value = 0;
      unreadUpdatesCount.value = 0;
    } catch (error) {
      console.error("Error marking all items as read:", error);
    }
  }

  /**
   * Decrement the unread ticket count (after one ticket is marked as read)
   */
  function decrementTicketCount() {
    if (unreadTicketCount.value > 0) {
      unreadTicketCount.value--;
    }
  }

  /**
   * Decrement the unread updates count (after one update is marked as read)
   */
  function decrementUpdatesCount() {
    if (unreadUpdatesCount.value > 0) {
      unreadUpdatesCount.value--;
    }
  }
    /**
   * Mark a specific ticket as read
   */
  async function markTicketAsRead(ticketId) {
    if (!user.value?.user?.id) return false;
    
    try {
      await post(`/tickets/${ticketId}/mark-read/`, {});
      decrementTicketCount();
      return true;
    } catch (error) {
      console.error(`Error marking ticket ${ticketId} as read:`, error);
      return false;
    }
  }

  /**
   * Mark a specific update as read
   */
  async function markUpdateAsRead(updateId) {
    if (!user.value?.user?.id) return false;
    
    try {
      await post(`/admin-notice/${updateId}/mark-read/`, {});
      decrementUpdatesCount();
      return true;
    } catch (error) {
      console.error(`Error marking update ${updateId} as read:`, error);
      return false;
    }
  }

  return {
    unreadTicketCount,
    unreadUpdatesCount,
    totalUnreadCount,
    isLoading,
    fetchUnreadCount,
    markAllAsRead,
    decrementTicketCount,
    decrementUpdatesCount,
    markTicketAsRead,
    markUpdateAsRead,
  };
}
