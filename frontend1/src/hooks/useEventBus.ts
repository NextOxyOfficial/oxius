import { useRef } from 'react';

// Simple event bus implementation as a singleton
const events = {};

export function useEventBus() {
  const bus = useRef({
    emit(event, ...args) {
      if (events[event]) {
        events[event].forEach((callback) => callback(...args));
      }
    },
    on(event, callback) {
      if (!events[event]) {
        events[event] = [];
      }
      events[event].push(callback);
    },
    off(event, callback) {
      if (events[event]) {
        if (callback) {
          events[event] = events[event].filter((cb) => cb !== callback);
        } else {
          delete events[event];
        }
      }
    },
  }).current;

  return bus;
}