import { ref, readonly } from "vue";

// Global shared state - defined OUTSIDE the composable so it persists across all component instances
const globalVideoMuted = ref(true);

export const useGlobalVideoState = () => {
  const setGlobalMute = (muted) => {
    globalVideoMuted.value = muted;
  };

  const toggleGlobalMute = () => {
    globalVideoMuted.value = !globalVideoMuted.value;
    return globalVideoMuted.value;
  };

  return {
    globalVideoMuted: readonly(globalVideoMuted),
    setGlobalMute,
    toggleGlobalMute
  };
};
