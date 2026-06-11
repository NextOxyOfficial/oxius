<template>
  <div>
    <!-- Three at-a-glance numbers -->
    <div class="grid grid-cols-3 divide-x divide-slate-100">
      <div class="p-4 text-center">
        <p class="text-2xl font-extrabold text-emerald-600">{{ s.active }}</p>
        <p class="text-[11px] text-slate-500 mt-0.5">চালু আছে</p>
      </div>
      <div class="p-4 text-center">
        <p class="text-2xl font-extrabold text-red-500">{{ s.lapsed }}</p>
        <p class="text-[11px] text-slate-500 mt-0.5">রিনিউ করেনি</p>
      </div>
      <div class="p-4 text-center">
        <p class="text-2xl font-extrabold text-amber-500">{{ s.expiring_soon }}</p>
        <p class="text-[11px] text-slate-500 mt-0.5">৭ দিনে শেষ হবে</p>
      </div>
    </div>
    <div class="px-4 pb-2 flex items-center justify-between text-[11px] text-slate-400 border-t border-slate-100 pt-2">
      <span>মোট কখনো Pro: <b class="text-slate-600">{{ s.ever_pro }}</b></span>
      <span>অটো-রিনিউ চালু: <b class="text-slate-600">{{ s.auto_renew_on }}</b></span>
    </div>

    <!-- Lapsed (did not renew) follow-up list -->
    <div v-if="s.lapsed_users && s.lapsed_users.length" class="border-t border-slate-100">
      <button class="w-full px-4 py-2.5 flex items-center justify-between text-left" @click="open = !open">
        <span class="text-xs font-semibold text-red-600">রিনিউ করেনি — ফলো-আপ তালিকা ({{ s.lapsed }})</span>
        <span class="text-slate-400 text-xs">{{ open ? '▲' : '▼' }}</span>
      </button>
      <div v-if="open" class="max-h-72 overflow-y-auto divide-y divide-slate-50">
        <div v-for="(u, i) in s.lapsed_users" :key="i" class="px-4 py-2 flex items-center justify-between gap-2">
          <div class="min-w-0">
            <p class="text-sm text-slate-700 truncate">{{ u.name }}</p>
            <p class="text-[11px] text-slate-400 truncate">
              📍 {{ u.area || '—' }}<span v-if="u.phone"> &bull; {{ u.phone }}</span>
            </p>
          </div>
          <div class="text-right shrink-0">
            <p class="text-[11px] text-slate-500">শেষ: {{ u.expired_on }}</p>
            <p v-if="u.auto_renew" class="text-[10px] text-amber-600">অটো-রিনিউ চালু</p>
          </div>
        </div>
      </div>
    </div>
    <div v-else class="px-4 py-3 text-center text-xs text-slate-400 border-t border-slate-100">
      রিনিউ না-করা কোনো ইউজার নেই 🎉
    </div>
  </div>
</template>

<script setup>
defineProps({ s: { type: Object, required: true } });
const open = ref(false);
</script>
