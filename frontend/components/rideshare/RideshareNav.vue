<template>
  <div class="w-full bg-white border border-slate-200/80 rounded-xl p-1.5 shadow-xs">
    <div class="flex flex-wrap gap-2">
      <NuxtLink
        v-for="item in items"
        :key="item.label"
        v-bind="item.disabled ? {} : { to: item.to }"
        class="flex-1 min-w-[90px] min-h-[44px] inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all text-center"
        :class="itemClass(item)"
      >
        <UIcon :name="item.icon" class="w-4 h-4" />
        <span class="hidden sm:inline">{{ item.label }}</span>
        <span class="sm:hidden">{{ item.shortLabel || item.label }}</span>
      </NuxtLink>
    </div>
  </div>
</template>

<script setup>
const route = useRoute();

const props = defineProps({
  current: {
    type: String,
    default: "booking",
  },
  mode: {
    type: String,
    default: null,
  },
});

// Use global cookie for consistent mode across all pages
const modeCookie = useCookie("rideshare-mode", {
  default: () => "passenger",
  maxAge: 60 * 60 * 24 * 30,
});

// Use prop mode if provided, otherwise use cookie
const currentMode = computed(() => {
  if (props.mode) {
    return props.mode;
  }
  return modeCookie.value === "driver" ? "driver" : "passenger";
});

const allItems = [
  // Passenger tabs - Book Ride includes active trip view
  {
    label: "Book Ride",
    shortLabel: "Book",
    to: "/rideshare",
    icon: "i-heroicons-map",
    key: "booking",
    disabled: false,
    modes: ["passenger"],
  },
  // Driver tabs - Driver first (default)
  {
    label: "Dashboard",
    shortLabel: "Dashboard",
    to: "/rideshare/driver",
    icon: "i-heroicons-identification",
    key: "driver",
    disabled: false,
    modes: ["driver"],
  },
  {
    label: "Vehicles",
    shortLabel: "Vehicles",
    to: "/rideshare/vehicles",
    icon: "i-heroicons-truck",
    key: "vehicles",
    disabled: false,
    modes: ["driver"],
  },
  // Shared tab
  {
    label: "History",
    shortLabel: "History",
    to: "/rideshare/history",
    icon: "i-heroicons-clock",
    key: "history",
    disabled: false,
    modes: ["passenger", "driver"],
  },
];

const items = computed(() => {
  return allItems.filter((item) => item.modes.includes(currentMode.value));
});

const itemClass = (item) => {
  const isActive = props.current === item.key || (!item.disabled && route.path === item.to);

  if (item.disabled) {
    return "bg-slate-100 text-slate-400 cursor-not-allowed";
  }

  if (isActive) {
    return "bg-gradient-to-r from-indigo-500 to-violet-600 text-white shadow-sm";
  }

  return "bg-slate-100/80 text-slate-600 hover:bg-slate-200 hover:text-slate-800";
};
</script>
