<template>
  <div class="w-full bg-white border border-gray-200 rounded-xl p-2 shadow-sm">
    <div class="grid gap-2" :class="gridClass">
      <NuxtLink
        v-for="item in items"
        :key="item.label"
        v-bind="item.disabled ? {} : { to: item.to }"
        class="min-h-[42px] w-full inline-flex items-center justify-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all text-center"
        :class="itemClass(item)"
      >
        <UIcon :name="item.icon" class="w-4 h-4" />
        <span>{{ item.label }}</span>
        <UBadge v-if="item.badge" color="gray" variant="soft" size="xs">
          {{ item.badge }}
        </UBadge>
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

const allItems = [
  {
    label: "Book Ride",
    to: "/rideshare",
    icon: "i-heroicons-map",
    key: "booking",
    disabled: false,
    modes: ["passenger"],
  },
  {
    label: "Vehicles",
    to: "/rideshare/vehicles",
    icon: "i-heroicons-truck",
    key: "vehicles",
    disabled: false,
    modes: ["driver"],
  },
  {
    label: "Driver",
    to: "/rideshare/driver",
    icon: "i-heroicons-identification",
    key: "driver",
    disabled: false,
    modes: ["driver"],
  },
  {
    label: "Active Trip",
    to: "/rideshare/active",
    icon: "i-heroicons-bolt",
    key: "active",
    disabled: false,
    modes: ["passenger", "driver"],
  },
  {
    label: "History",
    to: "/rideshare/history",
    icon: "i-heroicons-clock",
    key: "history",
    disabled: false,
    modes: ["passenger", "driver"],
  },
];

const items = computed(() => {
  if (!props.mode) {
    return allItems;
  }
  return allItems.filter((item) => item.modes.includes(props.mode));
});

const gridClass = computed(() => {
  const count = items.value.length;
  if (count <= 2) return "grid-cols-2";
  if (count === 3) return "grid-cols-2 sm:grid-cols-3";
  if (count === 4) return "grid-cols-2 sm:grid-cols-4";
  return "grid-cols-2 sm:grid-cols-5";
});

const itemClass = (item) => {
  const isActive = props.current === item.key || (!item.disabled && route.path === item.to);

  if (item.disabled) {
    return "bg-gray-100 text-gray-400 cursor-not-allowed border border-gray-200";
  }

  if (isActive) {
    return "bg-gray-950 text-white shadow-sm border border-gray-950";
  }

  return "bg-gray-100 text-gray-700 hover:bg-gray-200 hover:text-gray-900 border border-gray-200";
};
</script>
