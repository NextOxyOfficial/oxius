// Global video state management for Business Network
const globalVideoMuted = ref(true); // Start muted by default

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
