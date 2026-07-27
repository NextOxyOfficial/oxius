<template>
  <!-- Renders nothing at all when no ad is available, so the list doesn't keep
       a dead gap where the old dashed placeholder used to sit. -->
  <a
    v-if="ad"
    ref="root"
    :href="ctaHref"
    :target="ctaTarget"
    rel="noopener sponsored"
    class="group flex items-center gap-3 w-full rounded-xl border border-gray-200 bg-white px-2.5 py-2 hover:border-gray-300 hover:bg-gray-50 transition-colors"
    @click="onClick"
  >
    <!-- Thumb -->
    <div class="shrink-0 w-11 h-11 rounded-lg overflow-hidden bg-gray-100">
      <img
        v-if="thumb"
        :src="thumb"
        :alt="ad.title"
        class="w-full h-full object-cover"
        loading="lazy"
      />
      <div v-else class="w-full h-full flex items-center justify-center">
        <UIcon name="i-heroicons-megaphone" class="w-5 h-5 text-gray-400" />
      </div>
    </div>

    <!-- Title takes the full width; the CTA sits on the sponsored line so a
         long title isn't squeezed into a clump on narrow screens. -->
    <div class="flex-1 min-w-0">
      <p class="text-[13px] font-semibold text-gray-900 leading-snug line-clamp-2">
        {{ ad.title }}
      </p>
      <div class="flex items-center mt-0.5">
        <span class="text-[10.5px] font-semibold text-gray-400">স্পনসর্ড</span>
        <!-- Borderless icon + label: a quiet action, labelled and iconed from
             the ad's own type as configured in the ads panel. -->
        <span
          class="ml-auto shrink-0 inline-flex items-center gap-1 text-[10.5px] font-bold text-blue-600"
        >
          <img
            v-if="ad.ad_type === 'message_on_adsyconnect'"
            src="/images/chat_icon.png"
            alt=""
            class="w-3.5 h-3.5 object-contain"
          />
          <UIcon v-else :name="ctaIcon" class="w-3.5 h-3.5" />
          {{ ctaLabel }}
        </span>
      </div>
    </div>
  </a>
</template>

<script setup>
/**
 * Compact list-row ad — the web counterpart of the app's strip under post
 * media. Replaces the old SaleAdSlot, which reserved 112–144px of dashed
 * placeholder and never actually served an ad.
 *
 * Serves a real ad from the ads panel for [placement], bills an impression
 * only once it has genuinely been seen, and tracks the click.
 */
const props = defineProps({
  placement: { type: String, required: true },
});

const { get, post, staticURL } = useApi();

const ad = ref(null);
const root = ref(null);
let observer = null;
let visibleTimer = null;
let impressionSent = false;

const thumb = computed(() => {
  const a = ad.value;
  if (!a) return "";
  const raw =
    (Array.isArray(a.images) && a.images.length ? a.images[0] : "") ||
    a.companion_banner ||
    "";
  if (!raw) return "";
  return /^https?:\/\//i.test(raw) ? raw : `${staticURL || ""}${raw}`;
});

const ctaLabel = computed(
  () =>
    ({
      message_on_adsyconnect: "মেসেজ করুন",
      click_to_website: "ভিজিট করুন",
      call_on_whatsapp: "হোয়াটসঅ্যাপ",
      call_on_phone: "কল করুন",
      email_us: "ইমেইল",
    }[ad.value?.ad_type] || "দেখুন")
);

// Same icon per ad type as the ads-panel preview, so what the advertiser
// sees while creating the ad is what runs in the feed.
const ctaIcon = computed(
  () =>
    ({
      message_on_adsyconnect: "i-heroicons-chat-bubble-oval-left-ellipsis",
      click_to_website: "i-heroicons-arrow-top-right-on-square",
      call_on_whatsapp: "i-heroicons-chat-bubble-left-right",
      call_on_phone: "i-heroicons-phone",
      email_us: "i-heroicons-envelope",
    }[ad.value?.ad_type] || "i-heroicons-arrow-top-right-on-square")
);

const ctaHref = computed(() => {
  const a = ad.value;
  if (!a) return "#";
  // AdsyConnect message: the advertiser is the destination, so there is no
  // detail to read — open the inbox on a thread with them.
  if (a.ad_type === "message_on_adsyconnect") {
    return a.advertiser_id ? `/inbox?chat_with=${a.advertiser_id}` : "#";
  }
  const v = (a.ad_type_details || "").trim();
  if (!v) return "#";
  switch (a.ad_type) {
    case "call_on_whatsapp":
      return `https://wa.me/${v.replace(/[^0-9]/g, "")}`;
    case "call_on_phone":
      return `tel:${v}`;
    case "email_us":
      return `mailto:${v}`;
    default:
      return /^https?:\/\//i.test(v) ? v : `https://${v}`;
  }
});

const ctaTarget = computed(() =>
  ad.value?.ad_type === "click_to_website" ? "_blank" : "_self"
);

function track(eventType) {
  // Fire-and-forget: a failed beacon must never break the page.
  //
  // track_ad_events reads request.data["events"] and, per event, the ad id
  // under the key "ad". The old flat {event_type, placement, ad_id} body
  // produced an empty events list, so every web list-ad impression and click
  // was dropped: advertisers were never billed and creators never earned for
  // them. platform is tagged "web" so reporting can tell the surfaces apart.
  try {
    post("/bn/ads/track/", {
      events: [
        {
          ad: ad.value?.id,
          source: "panel",
          event_type: eventType,
          placement: props.placement,
          platform: "web",
        },
      ],
    });
  } catch (_) {
    /* ignore */
  }
}

function onClick() {
  if (ad.value) track("cta_click");
}

/**
 * Bills an impression only after the row has been >=50% visible for 1s —
 * matching the app's rule, so advertisers aren't charged for rows that merely
 * exist further down the document.
 */
function watchVisibility() {
  if (!root.value || typeof IntersectionObserver === "undefined") return;
  observer = new IntersectionObserver(
    (entries) => {
      const visible = entries.some((e) => e.isIntersecting && e.intersectionRatio >= 0.5);
      if (visible && !impressionSent) {
        visibleTimer = setTimeout(() => {
          if (impressionSent) return;
          impressionSent = true;
          track("impression");
          cleanup();
        }, 1000);
      } else if (!visible && visibleTimer) {
        clearTimeout(visibleTimer);
        visibleTimer = null;
      }
    },
    { threshold: [0, 0.5, 1] }
  );
  observer.observe(root.value);
}

function cleanup() {
  if (visibleTimer) {
    clearTimeout(visibleTimer);
    visibleTimer = null;
  }
  if (observer) {
    observer.disconnect();
    observer = null;
  }
}

onMounted(async () => {
  try {
    const res = await get(`/bn/ads/serve/?placement=${encodeURIComponent(props.placement)}`);
    const body = res?.data;
    // serve_ad answers { source: 'panel', ad: {...} } — the creative is NESTED.
    // Reading body.id instead of body.ad.id meant the guard never passed and
    // this component silently rendered nothing on every page that used it.
    const d = body?.ad;
    // { fallback: 'admob' } means no house ad matched — render nothing.
    if (body && !body.fallback && d && d.id) {
      ad.value = d;
      await nextTick();
      watchVisibility();
    }
  } catch (_) {
    /* no ad — stay hidden */
  }
});

onBeforeUnmount(cleanup);
</script>
