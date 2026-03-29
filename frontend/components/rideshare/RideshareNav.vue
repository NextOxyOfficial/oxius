<template>
  <div class="w-full bg-white border border-gray-200 rounded-xl p-2 shadow-sm">
    <div class="grid grid-cols-2 sm:grid-cols-5 gap-2">
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
});

const items = computed(() => [
  {
    label: "Book Ride",
    to: "/rideshare",
    icon: "i-heroicons-map",
    key: "booking",
    disabled: false,
  },
  {
    label: "Vehicles",
    to: "/rideshare/vehicles",
    icon: "i-heroicons-truck",
    key: "vehicles",
    disabled: false,
  },
  {
    label: "Driver",
    to: "/rideshare/driver",
    icon: "i-heroicons-identification",
    key: "driver",
    disabled: false,
  },
  {
    label: "Active Trip",
    to: "/rideshare/active",
    icon: "i-heroicons-bolt",
    key: "active",
    disabled: false,
  },
  {
    label: "History",
    to: "/rideshare/history",
    icon: "i-heroicons-clock",
    key: "history",
    disabled: false,
  },
]);

const itemClass = (item) => {
  const isActive = props.current === item.key || (!item.disabled && route.path === item.to);

  if (item.disabled) {
    return "bg-gray-100 text-gray-400 cursor-not-allowed border border-gray-200";
  }

  if (isActive) {
    return "bg-emerald-600 text-white shadow-sm";
  }

  return "bg-gray-100 text-gray-700 hover:bg-gray-200 hover:text-gray-900 border border-gray-200";
};
</script>
