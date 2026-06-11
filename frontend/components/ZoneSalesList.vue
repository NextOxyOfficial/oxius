<template>
  <div class="divide-y divide-slate-50">
    <div v-for="r in rows" :key="r.label" class="px-5 py-3 flex items-center gap-3">
      <span class="h-8 w-8 rounded-lg bg-slate-50 flex items-center justify-center text-base shrink-0">{{ r.icon }}</span>
      <span class="flex-1 text-sm text-slate-700">{{ r.label }}</span>
      <div class="text-right">
        <p class="text-sm font-bold text-slate-800">৳{{ money(r.amount) }}</p>
        <p class="text-[11px] text-slate-400">{{ r.count }} টি</p>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({ rows: { type: Array, default: () => [] } });
const money = (v) => Number(v || 0).toLocaleString("en-US", { maximumFractionDigits: 0 });
</script>
