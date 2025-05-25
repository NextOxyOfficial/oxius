/**
 * Composable for handling support tickets and their unread status
 */
export function useTickets() {
  const { get, post } = useApi();
  const { user } = useAuth();
  const unreadTicketCount = useState("ticketUnreadCount", () => 0);
  const isLoading = ref(false);

  /**
   * Fetch unread ticket count
   */
  async function fetchUnreadCount() {
    if (!user.value?.user?.id) {
      console.log("User not logged in, skipping ticket count fetch");
      return;
    }

    try {
      isLoading.value = true;
      const res = await get("/tickets/");
      
      if (res.data && Array.isArray(res.data)) {
        // Count tickets that have is_unread flag set to true
        unreadTicketCount.value = res.data.filter(ticket => ticket.is_unread).length;
      }
    } catch (error) {
      console.error("Error fetching unread ticket count:", error);
      // Reset count on error to ensure we don't show outdated data
      unreadTicketCount.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  /**
   * Mark all tickets as read
   */
  async function markAllAsRead() {
    if (!user.value?.user?.id) return;

    try {
      // Get all unread tickets first
      const res = await get("/tickets/");
      if (res.data && Array.isArray(res.data)) {
        // Mark each unread ticket as read
        const unreadTickets = res.data.filter(ticket => ticket.is_unread);
        for (const ticket of unreadTickets) {
          await post(`/tickets/${ticket.id}/mark-read/`, {});
        }
      }
      unreadTicketCount.value = 0;
    } catch (error) {
      console.error("Error marking all tickets as read:", error);
    }
  }
  /**
   * Decrement the unread count (after one ticket is marked as read)
   */
  function decrementCount() {
    if (unreadTicketCount.value > 0) {
      unreadTicketCount.value--;
    }
  }
  
  /**
   * Mark a specific ticket as read
   */
  async function markTicketAsRead(ticketId) {
    if (!user.value?.user?.id) return false;
    
    try {
      await post(`/tickets/${ticketId}/mark-read/`, {});
      decrementCount();
      return true;
    } catch (error) {
      console.error(`Error marking ticket ${ticketId} as read:`, error);
      return false;
    }
  }

  return {
    unreadTicketCount,
    isLoading,
    fetchUnreadCount,
    markAllAsRead,
    decrementCount,
    markTicketAsRead,
  };
}
