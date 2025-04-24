import { reactive } from "vue";

// Simple event bus implementation
const bus = reactive({
  events: {},
  emit(event, ...args) {
    if (this.events[event]) {
      this.events[event].forEach((callback) => callback(...args));
    }
  },
  on(event, callback) {
    if (!this.events[event]) {
      this.events[event] = [];
    }
    this.events[event].push(callback);
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
});

export function useEventBus() {
  return bus;
}
