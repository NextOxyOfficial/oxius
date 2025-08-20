export function useScrollDirection() {
  const isScrollingDown = ref(false);
  const isScrollingUp = ref(false);
  const lastScrollY = ref(0);
  const scrollY = ref(0);

  const updateScrollDirection = () => {
    scrollY.value = window.scrollY;

    if (scrollY.value > lastScrollY.value && scrollY.value > 100) {
      // Scrolling down
      isScrollingDown.value = true;
      isScrollingUp.value = false;
    } else if (scrollY.value < lastScrollY.value) {
      // Scrolling up
      isScrollingDown.value = false;
      isScrollingUp.value = true;
    }

    lastScrollY.value = scrollY.value;
  };

  onMounted(() => {
    window.addEventListener("scroll", updateScrollDirection, { passive: true });
    lastScrollY.value = window.scrollY;
  });

  onUnmounted(() => {
    window.removeEventListener("scroll", updateScrollDirection);
  });

  return {
    isScrollingDown,
    isScrollingUp,
    scrollY,
  };
}
