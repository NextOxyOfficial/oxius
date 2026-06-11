<template>
  <div class="overflow-x-auto">
    <table class="w-full text-sm whitespace-nowrap">
      <thead>
        <tr class="text-[11px] text-slate-400 border-b border-slate-100">
          <th class="text-left py-2 px-4 font-medium">ফিচার</th>
          <th class="text-right py-2 font-medium">সংখ্যা</th>
          <th class="text-right py-2 px-4 font-medium">পরিমাণ (৳)</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="r in rows" :key="r.label" class="border-b border-slate-50">
          <td class="py-2 px-4 text-slate-700"><span class="mr-1.5">{{ r.icon }}</span>{{ r.label }}</td>
          <td class="py-2 text-right text-slate-500">{{ r.count }}</td>
          <td class="py-2 px-4 text-right font-semibold text-slate-800">৳{{ money(r.amount) }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup>
defineProps({ rows: { type: Array, default: () => [] } });
const money = (v) => Number(v || 0).toLocaleString("en-US", { maximumFractionDigits: 0 });
</script>
