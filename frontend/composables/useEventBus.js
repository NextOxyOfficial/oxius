import { reactive } from "vue";

// Simple event bus implementation with enhanced functionality
const bus = reactive({
  events: {},
  emit(event, ...args) {
    if (this.events[event]) {
      this.events[event].forEach((callback) => {
        try {
          callback(...args);
        } catch (error) {
          console.error(`Error in event listener for "${event}":`, error);
        }
      });
    }
  },
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = [];
    }
    this.events[event].push(callback);

    // Return unsubscribe function
    return () => this.off(event, callback);
  },
  off(event, callback) {
    if (this.events[event]) {
      if (callback) {
        this.events[event] = this.events[event].filter((cb) => cb !== callback);
      } else {
        delete this.events[event];
      }
    }
  },
  hasListeners(event) {
    return !!(this.events[event] && this.events[event].length > 0);
  },
  removeAllListeners(event) {
    if (event) {
      delete this.events[event];
    } else {
      this.events = {};
    }
  },
  getEvents() {
    return Object.keys(this.events);
  },
});

export function useEventBus() {
  return bus;
}

// Pre-defined event types for better consistency
export const EventTypes = {
  GLOBAL_REFRESH: "global-refresh",
  PAGE_REFRESH: "page-refresh",
  DATA_REFRESH: "data-refresh",
  PULL_TO_REFRESH_START: "pull-to-refresh-start",
  PULL_TO_REFRESH_END: "pull-to-refresh-end",
  AUTO_REFRESH_TRIGGERED: "auto-refresh-triggered",
  CONTENT_UPDATED: "content-updated",
  POST_CREATED: "post-created",
  POST_UPDATED: "post-updated",
  POST_DELETED: "post-deleted",
  USER_PROFILE_UPDATED: "user-profile-updated",
  NOTIFICATION_RECEIVED: "notification-received",
  CONNECTION_STATUS_CHANGED: "connection-status-changed",
  THEME_CHANGED: "theme-changed",
  NETWORK_STATUS_CHANGED: "network-status-changed",
  REFRESH_REQUESTED: "refresh-requested",
};

// Enhanced event bus with refresh coordination
export function useRefreshCoordinator() {
  const eventBus = useEventBus();
  
  // Coordinate global refresh across components
  const triggerGlobalRefresh = async () => {
    eventBus.emit(EventTypes.GLOBAL_REFRESH);
    eventBus.emit(EventTypes.PULL_TO_REFRESH_START);
    
    // Wait a bit for components to respond
    await new Promise(resolve => setTimeout(resolve, 100));
    
    eventBus.emit(EventTypes.PULL_TO_REFRESH_END);
  };
  
  // Trigger page-specific refresh
  const triggerPageRefresh = async (pageType = null) => {
    eventBus.emit(EventTypes.PAGE_REFRESH, pageType);
  };
  
  // Trigger data refresh for specific components
  const triggerDataRefresh = async (component = null, data = null) => {
    eventBus.emit(EventTypes.DATA_REFRESH, { component, data });
  };
  
  // Register refresh handler
  const onRefresh = (callback, eventType = EventTypes.GLOBAL_REFRESH) => {
    return eventBus.on(eventType, callback);
  };
  
  // Auto refresh functionality
  const setupAutoRefresh = (callback, interval = 300000) => { // 5 minutes default
    const autoRefreshTimer = setInterval(() => {
      if (!document.hidden) {
        eventBus.emit(EventTypes.AUTO_REFRESH_TRIGGERED);
        callback();
      }
    }, interval);
    
    // Pause auto refresh when page is hidden
    const handleVisibilityChange = () => {
      if (document.hidden) {
        // Page is hidden, auto refresh will be skipped
      } else {
        // Page is visible, auto refresh can continue
        eventBus.emit(EventTypes.AUTO_REFRESH_TRIGGERED);
        callback();
      }
    };
    
    document.addEventListener('visibilitychange', handleVisibilityChange);
    
    // Return cleanup function
    return () => {
      clearInterval(autoRefreshTimer);
      document.removeEventListener('visibilitychange', handleVisibilityChange);
    };
  };
  
  return {
    triggerGlobalRefresh,
    triggerPageRefresh,
    triggerDataRefresh,
    onRefresh,
    setupAutoRefresh,
    eventBus
  };
}
