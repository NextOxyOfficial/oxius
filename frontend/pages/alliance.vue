<template>
  <div class="min-h-screen bg-slate-100">
    <!-- ============ LOGIN (Django admin credentials only) ============ -->
    <div v-if="!token" class="min-h-screen flex items-center justify-center px-4">
      <div class="w-full max-w-sm bg-white rounded-2xl border border-slate-200 shadow-sm p-7">
        <div class="flex flex-col items-center mb-6">
          <img src="https://adsyclub.com/static/frontend/images/logo.png" alt="AdsyClub" class="h-10 w-auto mb-3" />
          <h1 class="text-lg font-bold text-slate-900">Alliance Console</h1>
          <p class="text-xs text-slate-500 mt-1">Admin access only — use your Django admin login</p>
        </div>
        <form @submit.prevent="login" class="space-y-3">
          <input v-model="loginForm.username" type="text" required placeholder="Admin email or username"
                 class="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          <input v-model="loginForm.password" type="password" required placeholder="Password"
                 class="w-full rounded-lg border border-slate-300 px-3.5 py-2.5 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          <p v-if="loginError" class="text-xs text-red-600">{{ loginError }}</p>
          <button type="submit" :disabled="loggingIn"
                  class="w-full rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-2.5 text-sm disabled:opacity-60">
            {{ loggingIn ? "Signing in…" : "Sign in" }}
          </button>
        </form>
      </div>
    </div>

    <!-- ============ CONSOLE ============ -->
    <div v-else class="max-w-5xl mx-auto px-3 sm:px-6 py-6">
      <!-- Header -->
      <div class="flex flex-wrap items-center justify-between gap-3 mb-5">
        <div class="flex items-center gap-3">
          <img src="https://adsyclub.com/static/frontend/images/logo.png" alt="AdsyClub" class="h-9 w-auto" />
          <div>
            <h1 class="text-lg font-bold text-slate-900 leading-tight">Alliance Outreach</h1>
            <p class="text-xs text-slate-500">Review · edit · send sponsor &amp; partner emails</p>
          </div>
        </div>
        <div class="flex items-center gap-2">
          <button @click="loadAll" class="rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-50">
            ⟳ Refresh
          </button>
          <button @click="logout" class="rounded-lg border border-slate-300 bg-white px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-50">
            Logout
          </button>
        </div>
      </div>

      <!-- Stats -->
      <div class="grid grid-cols-3 sm:grid-cols-6 gap-2 mb-4">
        <div v-for="s in statChips" :key="s.key"
             class="rounded-xl bg-white border border-slate-200 px-3 py-2.5 text-center">
          <p class="text-lg font-bold" :class="s.color">{{ stats.by_status?.[s.key] ?? (s.key === 'total' ? stats.total ?? 0 : 0) }}</p>
          <p class="text-[10px] uppercase tracking-wide text-slate-400 font-semibold">{{ s.label }}</p>
        </div>
      </div>

      <!-- Filter tabs + bulk actions -->
      <div class="flex flex-wrap items-center justify-between gap-3 mb-4">
        <div class="flex gap-1.5 overflow-x-auto">
          <button v-for="t in tabs" :key="t" @click="filter = t"
                  class="shrink-0 rounded-full px-3.5 py-1.5 text-xs font-semibold border transition-colors"
                  :class="filter === t ? 'bg-emerald-600 border-emerald-600 text-white' : 'bg-white border-slate-200 text-slate-600 hover:bg-slate-50'">
            {{ t === "all" ? "All" : t.charAt(0).toUpperCase() + t.slice(1) }}
          </button>
        </div>
        <div class="flex gap-2">
          <button v-if="selected.size" @click="sendSelected"
                  class="rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white px-4 py-2 text-xs font-bold">
            🚀 Send selected ({{ selected.size }})
          </button>
          <button v-if="sendableCount" @click="sendAll"
                  class="rounded-lg bg-slate-900 hover:bg-slate-800 text-white px-4 py-2 text-xs font-bold">
            Send all sendable ({{ sendableCount }})
          </button>
        </div>
      </div>

      <!-- Empty -->
      <div v-if="!loading && !filtered.length" class="bg-white rounded-2xl border border-slate-200 py-16 text-center">
        <p class="text-3xl mb-2">📭</p>
        <p class="text-slate-600 font-medium">No drafts here</p>
        <p class="text-slate-400 text-sm mt-1">Ask the assistant to prepare a batch — it will appear here for review.</p>
      </div>

      <!-- Draft cards -->
      <div class="space-y-3">
        <div v-for="d in filtered" :key="d.id"
             class="bg-white rounded-2xl border overflow-hidden"
             :class="selected.has(d.id) ? 'border-emerald-400 ring-1 ring-emerald-200' : 'border-slate-200'">
          <!-- Card head -->
          <div class="flex items-center justify-between gap-2 px-4 py-3 border-b border-slate-100 bg-slate-50/60">
            <label class="flex items-center gap-2.5 min-w-0 cursor-pointer">
              <input type="checkbox" :checked="selected.has(d.id)" @change="toggleSelect(d.id)"
                     :disabled="!isSendable(d)" class="h-4 w-4 rounded border-slate-300 text-emerald-600" />
              <span class="font-bold text-slate-800 text-sm truncate">{{ d.company }}</span>
              <span v-if="d.category" class="shrink-0 rounded-full bg-slate-200 text-slate-600 px-2 py-0.5 text-[10px] font-semibold uppercase">{{ d.category }}</span>
            </label>
            <div class="flex items-center gap-2 shrink-0">
              <select v-model="d.language" @change="changeLanguage(d)" :disabled="!isEditable(d)"
                      title="Email & donation page language"
                      class="rounded-md border border-slate-200 bg-white text-[11px] font-bold text-slate-600 px-1.5 py-1 focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:opacity-60">
                <option value="en">🌐 EN</option>
                <option value="bn">🇧🇩 BN</option>
              </select>
              <span class="rounded-full px-2.5 py-1 text-[10px] font-bold uppercase tracking-wide" :class="statusClass(d.status)">
                {{ d.status }}
              </span>
            </div>
          </div>

          <!-- Editable fields -->
          <div class="p-4 space-y-2.5">
            <div class="grid sm:grid-cols-2 gap-2.5">
              <div>
                <label class="text-[10px] font-semibold uppercase text-slate-400">To email</label>
                <input v-model="d.to_email" :disabled="!isEditable(d)"
                       class="mt-0.5 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:bg-slate-50 disabled:text-slate-400" />
              </div>
              <div>
                <label class="text-[10px] font-semibold uppercase text-slate-400">Contact name (optional)</label>
                <input v-model="d.to_name" :disabled="!isEditable(d)"
                       class="mt-0.5 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:bg-slate-50 disabled:text-slate-400" />
              </div>
            </div>
            <div>
              <label class="text-[10px] font-semibold uppercase text-slate-400">Subject</label>
              <input v-model="d.subject" :disabled="!isEditable(d)"
                     class="mt-0.5 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:bg-slate-50 disabled:text-slate-400" />
            </div>
            <div>
              <div class="flex items-center justify-between">
                <label class="text-[10px] font-semibold uppercase text-slate-400">Email body</label>
                <button @click="togglePreview(d)" class="text-[11px] font-semibold text-emerald-600 hover:text-emerald-700">
                  {{ previewing.has(d.id) ? "✎ Edit message" : "👁 Preview full email" }}
                </button>
              </div>
              <div v-if="previewing.has(d.id)" class="mt-0.5">
                <div v-if="previewLoading.has(d.id)" class="rounded-lg border border-slate-200 bg-slate-50 py-10 text-center text-sm text-slate-400">
                  Rendering full email…
                </div>
                <iframe v-else :srcdoc="previewHtml[d.id]" title="Email preview" @load="onFrameLoad" scrolling="no"
                        class="w-full rounded-lg border border-slate-200 bg-white block" style="min-height:200px;overflow:hidden"></iframe>
                <p class="text-[10px] text-slate-400 mt-1">This is exactly how the email will look to the recipient — header, your signature, Donate button &amp; footer included.</p>
              </div>
              <template v-else>
                <textarea v-model="d.body_html" :disabled="!isEditable(d)" rows="7"
                          class="mt-0.5 w-full rounded-lg border border-slate-200 px-3 py-2 text-sm leading-relaxed focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:bg-slate-50 disabled:text-slate-400"></textarea>
                <p class="text-[10px] text-slate-400 mt-1">
                  Signature (ceo@adsyclub.com · WhatsApp), Donate button &amp; footer are added automatically — edit only the message above, then "Preview full email".
                </p>
              </template>
            </div>
            <p v-if="d.notes" class="text-[11px] text-slate-400">📝 {{ d.notes }}</p>
            <p v-if="d.error" class="text-[11px] text-red-500">⚠️ {{ d.error }}</p>

            <!-- Send a test to yourself first -->
            <div class="flex flex-wrap items-center gap-2 pt-1.5 mt-1 border-t border-slate-100">
              <span class="text-[10px] font-semibold uppercase text-slate-400 pt-1">🧪 Test to</span>
              <input v-model="testEmail" type="email" placeholder="your@email.com"
                     class="flex-1 min-w-[150px] rounded-lg border border-slate-200 px-3 py-1.5 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-400" />
              <button @click="sendTest(d)" :disabled="testing.has(d.id)"
                      class="rounded-lg bg-indigo-600 hover:bg-indigo-700 text-white px-3.5 py-1.5 text-xs font-bold disabled:opacity-50">
                {{ testing.has(d.id) ? "Sending…" : "✈ Send test" }}
              </button>
            </div>

            <!-- Card actions -->
            <div class="flex flex-wrap items-center gap-2 pt-1">
              <button v-if="isEditable(d)" @click="saveDraft(d)" :disabled="saving.has(d.id)"
                      class="rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 px-3.5 py-1.5 text-xs font-bold disabled:opacity-50">
                {{ saving.has(d.id) ? "Saving…" : "💾 Save changes" }}
              </button>
              <button v-if="isSendable(d)" @click="sendOne(d)"
                      class="rounded-lg bg-emerald-600 hover:bg-emerald-700 text-white px-3.5 py-1.5 text-xs font-bold">
                🚀 Send this email
              </button>
              <button v-if="isSendable(d)" @click="skipDraft(d)"
                      class="rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-600 px-3.5 py-1.5 text-xs font-semibold">
                Skip
              </button>
              <span v-if="d.sent_at" class="text-[11px] text-slate-400 ml-auto">✅ Sent {{ fmt(d.sent_at) }}</span>
              <span v-else-if="d.scheduled_for && d.status === 'scheduled'" class="text-[11px] text-slate-400 ml-auto">⏱ Scheduled {{ fmt(d.scheduled_for) }}</span>
            </div>
          </div>
        </div>
      </div>

      <p v-if="toast" class="fixed bottom-5 left-1/2 -translate-x-1/2 rounded-full bg-slate-900 text-white text-sm px-5 py-2.5 shadow-lg z-50">{{ toast }}</p>
    </div>
  </div>
</template>

<script setup>
definePageMeta({ layout: false });
useHead({ title: "Alliance Console — AdsyClub" });

const runtimeConfig = useRuntimeConfig();
const API = `${runtimeConfig.public.baseURL}/api/alliance`;

const token = ref(null);
const loginForm = ref({ username: "", password: "" });
const loginError = ref("");
const loggingIn = ref(false);

const drafts = ref([]);
const stats = ref({});
const loading = ref(false);
const filter = ref("all");
const selected = ref(new Set());
const previewing = ref(new Set());
const previewLoading = ref(new Set());
const previewHtml = ref({});
const saving = ref(new Set());
const testing = ref(new Set());
const testEmail = ref("");
const toast = ref("");

const tabs = ["all", "draft", "scheduled", "sent", "failed", "skipped"];
const statChips = [
  { key: "total", label: "Total", color: "text-slate-800" },
  { key: "draft", label: "Draft", color: "text-amber-600" },
  { key: "scheduled", label: "Scheduled", color: "text-blue-600" },
  { key: "sent", label: "Sent", color: "text-emerald-600" },
  { key: "failed", label: "Failed", color: "text-red-600" },
  { key: "skipped", label: "Skipped", color: "text-slate-400" },
];

const isEditable = (d) => ["draft", "approved", "failed"].includes(d.status);
const isSendable = (d) => ["draft", "approved", "failed"].includes(d.status);

const filtered = computed(() =>
  filter.value === "all" ? drafts.value : drafts.value.filter((d) => d.status === filter.value)
);
const sendableCount = computed(() => drafts.value.filter(isSendable).length);

function statusClass(s) {
  return {
    draft: "bg-amber-50 text-amber-700",
    approved: "bg-emerald-50 text-emerald-700",
    scheduled: "bg-blue-50 text-blue-700",
    sending: "bg-blue-50 text-blue-700",
    sent: "bg-emerald-600 text-white",
    failed: "bg-red-50 text-red-600",
    skipped: "bg-slate-100 text-slate-500",
  }[s] || "bg-slate-100 text-slate-500";
}

function fmt(iso) {
  try { return new Date(iso).toLocaleString(); } catch { return iso; }
}

function showToast(msg) {
  toast.value = msg;
  setTimeout(() => (toast.value = ""), 3000);
}

async function api(path, opts = {}) {
  return await $fetch(`${API}${path}`, {
    ...opts,
    headers: { Authorization: `Bearer ${token.value}`, ...(opts.headers || {}) },
  });
}

async function login() {
  loggingIn.value = true;
  loginError.value = "";
  try {
    const res = await $fetch(`${API}/login/`, { method: "POST", body: loginForm.value });
    token.value = res.access;
    if (process.client) localStorage.setItem("alliance_token", res.access);
    await loadAll();
  } catch (e) {
    loginError.value = e?.data?.error || "Login failed. Admin credentials only.";
  } finally {
    loggingIn.value = false;
  }
}

function logout() {
  token.value = null;
  drafts.value = [];
  if (process.client) localStorage.removeItem("alliance_token");
}

// Turn stored HTML body into plain text for the editor (so staff write plainly,
// no <p> tags). Paragraphs -> blank line, <br> -> newline, other tags stripped.
function htmlToPlain(html) {
  if (!html) return "";
  if (!/<[a-z][\s\S]*>/i.test(html)) return html; // already plain
  let t = html
    .replace(/<\/p>\s*<p[^>]*>/gi, "\n\n")
    .replace(/<p[^>]*>/gi, "")
    .replace(/<\/p>/gi, "\n\n")
    .replace(/<br\s*\/?>/gi, "\n")
    .replace(/<\/?(strong|b|em|i|span|div)[^>]*>/gi, "")
    .replace(/<[^>]+>/g, "");
  t = t
    .replace(/&nbsp;/gi, " ")
    .replace(/&amp;/gi, "&")
    .replace(/&lt;/gi, "<")
    .replace(/&gt;/gi, ">")
    .replace(/&#39;/g, "'")
    .replace(/&quot;/gi, '"');
  return t.replace(/\n{3,}/g, "\n\n").trim();
}

async function loadAll() {
  loading.value = true;
  try {
    const [list, st] = await Promise.all([api("/drafts/?page_size=300"), api("/drafts/stats/")]);
    const rows = Array.isArray(list) ? list : list.results || [];
    // Show the body as plain text for editing (no <p> tags). The backend turns
    // plain text back into HTML paragraphs on preview/send (see _body_to_html).
    rows.forEach((d) => {
      d.body_html = htmlToPlain(d.body_html);
    });
    drafts.value = rows;
    stats.value = st || {};
    selected.value = new Set();
    await renderAllPreviews(); // show every email's full design by default
  } catch (e) {
    if (e?.status === 401 || e?.status === 403) return logout();
    showToast("Failed to load drafts");
  } finally {
    loading.value = false;
  }
}

// Render the full email for every draft and open its preview by default.
async function renderAllPreviews() {
  const open = new Set();
  const map = {};
  await Promise.all(
    drafts.value.map(async (d) => {
      try {
        const res = await api("/drafts/preview/", {
          method: "POST",
          body: { subject: d.subject, body_html: d.body_html, to_email: d.to_email, language: d.language },
        });
        map[d.id] = res.html;
        open.add(d.id);
      } catch { /* leave this card in edit mode if render fails */ }
    })
  );
  previewHtml.value = map;
  previewing.value = open;
}

// Auto-size the preview frame to the email's full height — no internal scroll.
function onFrameLoad(e) {
  try {
    const f = e.target;
    const doc = f.contentWindow?.document;
    const h = doc?.body?.scrollHeight || doc?.documentElement?.scrollHeight;
    if (h) f.style.height = h + "px";
  } catch { /* cross-origin guard — srcdoc is same-origin so this normally works */ }
}

function toggleSelect(id) {
  const s = new Set(selected.value);
  s.has(id) ? s.delete(id) : s.add(id);
  selected.value = s;
}

async function togglePreview(d) {
  const open = new Set(previewing.value);
  if (open.has(d.id)) { open.delete(d.id); previewing.value = open; return; }
  // Opening preview: render the FULL email (exact template) for the live values.
  const loading = new Set(previewLoading.value); loading.add(d.id); previewLoading.value = loading;
  open.add(d.id); previewing.value = open;
  try {
    const res = await api("/drafts/preview/", {
      method: "POST",
      body: { subject: d.subject, body_html: d.body_html, to_email: d.to_email, language: d.language },
    });
    previewHtml.value = { ...previewHtml.value, [d.id]: res.html };
  } catch {
    previewHtml.value = { ...previewHtml.value, [d.id]: "<p style='padding:24px;font-family:sans-serif;color:#b91c1c'>Preview failed to render.</p>" };
  } finally {
    const l = new Set(previewLoading.value); l.delete(d.id); previewLoading.value = l;
  }
}

// Persist the current field values (esp. the manually-typed To-email) so that
// "what you see is what gets sent" — no separate Save click required.
async function persistDraft(d) {
  await api(`/drafts/${d.id}/`, {
    method: "PATCH",
    body: { to_email: d.to_email, to_name: d.to_name, subject: d.subject, body_html: d.body_html, language: d.language },
  });
}

async function changeLanguage(d) {
  try {
    await api(`/drafts/${d.id}/`, { method: "PATCH", body: { language: d.language } });
    if (previewing.value.has(d.id)) {
      const res = await api("/drafts/preview/", {
        method: "POST",
        body: { subject: d.subject, body_html: d.body_html, to_email: d.to_email, language: d.language },
      });
      previewHtml.value = { ...previewHtml.value, [d.id]: res.html };
    }
    showToast(d.language === "bn" ? "Language: বাংলা" : "Language: English");
  } catch { showToast("Could not update language"); }
}

async function saveDraft(d) {
  saving.value = new Set([...saving.value, d.id]);
  try {
    await persistDraft(d);
    showToast("Saved ✔");
  } catch {
    showToast("Save failed");
  } finally {
    const s = new Set(saving.value); s.delete(d.id); saving.value = s;
  }
}

async function sendTest(d) {
  const addr = (testEmail.value || "").trim();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(addr)) { showToast("Enter a valid test email"); return; }
  if (process.client) localStorage.setItem("alliance_test_email", addr);
  testing.value = new Set([...testing.value, d.id]);
  try {
    await api("/drafts/send_test/", {
      method: "POST",
      body: { test_email: addr, subject: d.subject, body_html: d.body_html, language: d.language, o: d.id },
    });
    showToast(`Test sent to ${addr} ✔`);
  } catch (e) {
    showToast(e?.data?.error || "Test send failed");
  } finally {
    const s = new Set(testing.value); s.delete(d.id); testing.value = s;
  }
}

async function sendOne(d) {
  if (!confirm(`Send this email to ${d.to_email}?`)) return;
  try {
    await persistDraft(d); // send to whatever is typed in the To-email field
    const res = await api("/drafts/send/", { method: "POST", body: { ids: [d.id] } });
    showToast(`Scheduled ${res.scheduled} email ✔`);
    await loadAll();
  } catch { showToast("Send failed"); }
}

async function sendSelected() {
  const targets = drafts.value.filter((d) => selected.value.has(d.id) && isSendable(d));
  if (!targets.length) return;
  if (!confirm(`Send ${targets.length} selected email(s)? They will go out staggered (~2-3 min apart).`)) return;
  try {
    await Promise.all(targets.map(persistDraft)); // lock in the typed recipients/edits
    const res = await api("/drafts/send/", { method: "POST", body: { ids: targets.map((d) => d.id) } });
    showToast(`Scheduled ${res.scheduled} email(s) ✔`);
    await loadAll();
  } catch { showToast("Send failed"); }
}

async function sendAll() {
  const targets = drafts.value.filter(isSendable);
  if (!targets.length) return;
  if (!confirm(`Send ALL ${targets.length} sendable email(s)? They will go out staggered (~2-3 min apart).`)) return;
  try {
    await Promise.all(targets.map(persistDraft)); // lock in the typed recipients/edits
    const res = await api("/drafts/send/", { method: "POST", body: { ids: targets.map((d) => d.id) } });
    showToast(`Scheduled ${res.scheduled} email(s) ✔`);
    await loadAll();
  } catch { showToast("Send failed"); }
}

async function skipDraft(d) {
  try {
    await api(`/drafts/${d.id}/skip/`, { method: "POST" });
    await loadAll();
  } catch { showToast("Failed"); }
}

onMounted(async () => {
  if (process.client) testEmail.value = localStorage.getItem("alliance_test_email") || "";
  const saved = process.client ? localStorage.getItem("alliance_token") : null;
  if (saved) {
    token.value = saved;
    await loadAll();
  }
});
</script>
