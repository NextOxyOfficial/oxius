<template>
  <Transition name="banner-slide">
    <div
      v-if="visible"
      class="smart-app-banner"
      :style="{ top: bannerTop + 'px' }"
      role="banner"
      aria-label="Open in AdsyClub app"
    >
      <!-- Dismiss button -->
      <button
        class="banner-close"
        aria-label="Close banner"
        @click="dismiss"
      >
        <svg width="14" height="14" viewBox="0 0 14 14" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M1 1L13 13M13 1L1 13" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
        </svg>
      </button>

      <!-- App icon -->
      <img
        :src="'/favicon.png'"
        alt="AdsyClub"
        class="banner-icon"
        width="52"
        height="52"
      />

      <!-- App info -->
      <div class="banner-info">
        <p class="banner-name">AdsyClub</p>
        <p class="banner-tagline">{{ tagline }}</p>
      </div>

      <!-- Open CTA -->
      <button
        class="banner-open-btn"
        :disabled="opening"
        @click="openApp"
      >
        <span v-if="!opening">Open</span>
        <span v-else class="btn-spinner" />
      </button>
    </div>
  </Transition>
</template>

<script setup lang="ts">
import { useSmartAppLinks } from '~/composables/useSmartAppLinks'
import { useScrollDirection } from '~/composables/useScrollDirection'

const DISMISS_KEY = 'smart-banner-dismissed-at'
const COOLDOWN_MS = 24 * 60 * 60 * 1000 // 24 hours

const { getPlatform, isMobileBrowser, isStandaloneContext, tryOpenApp } = useSmartAppLinks()
const { isScrollingDown } = useScrollDirection()

const visible = ref(false)
const opening = ref(false)
const headerHeight = ref(56)

const platform = computed(() => getPlatform())

const tagline = computed(() =>
  platform.value === 'ios'
    ? 'Free · On the App Store'
    : 'Free · On Google Play'
)

const bannerTop = computed(() => isScrollingDown.value ? 0 : headerHeight.value)

function shouldShow(): boolean {
  if (!import.meta.client) return false
  if (!isMobileBrowser() || isStandaloneContext()) return false

  // Respect user dismissal for 24 h
  const dismissedAt = Number(localStorage.getItem(DISMISS_KEY) || '0')
  if (dismissedAt && Date.now() - dismissedAt < COOLDOWN_MS) return false

  // Don't show if user explicitly chose web mode
  const search = new URLSearchParams(window.location.search)
  if (search.get('web') === '1') return false

  return true
}

function dismiss() {
  visible.value = false
  localStorage.setItem(DISMISS_KEY, Date.now().toString())
}

async function openApp() {
  opening.value = true
  try {
    await tryOpenApp({
      fullPath: window.location.pathname + window.location.search,
      fallbackToStore: true,
      fallbackDelayMs: 1600,
      cooldownMs: 0, // banner already has its own cooldown
      force: true,
    })
  } finally {
    opening.value = false
    // Dismiss banner after attempting to open (whether opened or went to store)
    visible.value = false
    localStorage.setItem(DISMISS_KEY, Date.now().toString())
  }
}

onMounted(() => {
  const measureHeader = () => {
    const container = document.getElementById('header-container')
    if (container) {
      const headerEl = container.firstElementChild as HTMLElement | null
      if (headerEl) headerHeight.value = headerEl.offsetHeight
    }
  }
  measureHeader()
  window.addEventListener('resize', measureHeader)
  // Small delay so it doesn't flash before the page is ready
  setTimeout(() => {
    visible.value = shouldShow()
  }, 800)
})
</script>

<style scoped>
.smart-app-banner {
  position: fixed;
  left: 0;
  right: 0;
  z-index: 99999998;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 12px;
  background: rgba(248, 250, 252, 0.97);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border-bottom: 1px solid rgba(0, 0, 0, 0.08);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
  transition: top 0.5s cubic-bezier(0.4, 0, 0.2, 1);
}

/* Dismiss */
.banner-close {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  width: 26px;
  height: 26px;
  border: none;
  background: none;
  color: #94a3b8;
  cursor: pointer;
  border-radius: 50%;
  transition: background 0.15s, color 0.15s;
}
.banner-close:hover {
  background: #f1f5f9;
  color: #64748b;
}

/* App icon */
.banner-icon {
  flex-shrink: 0;
  width: 52px;
  height: 52px;
  border-radius: 14px;
  object-fit: cover;
  box-shadow: 0 1px 4px rgba(0,0,0,0.12);
}

/* Info block */
.banner-info {
  flex: 1;
  min-width: 0;
}
.banner-name {
  font-size: 14px;
  font-weight: 700;
  color: #0f172a;
  margin: 0 0 1px;
  line-height: 1.2;
}
.banner-tagline {
  font-size: 11px;
  color: #64748b;
  margin: 0 0 3px;
  line-height: 1.3;
}
/* Open button */
.banner-open-btn {
  flex-shrink: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  min-width: 68px;
  height: 34px;
  padding: 0 16px;
  border: none;
  border-radius: 20px;
  background: #0ea5e9;
  color: #fff;
  font-size: 13px;
  font-weight: 700;
  cursor: pointer;
  transition: background 0.15s, transform 0.1s;
}
.banner-open-btn:hover {
  background: #0284c7;
}
.banner-open-btn:active {
  transform: scale(0.97);
}
.banner-open-btn:disabled {
  opacity: 0.7;
  cursor: default;
}

/* Spinner */
.btn-spinner {
  display: inline-block;
  width: 14px;
  height: 14px;
  border: 2px solid rgba(255,255,255,0.4);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}
@keyframes spin {
  to { transform: rotate(360deg); }
}

/* Slide-down / slide-up transition */
.banner-slide-enter-active,
.banner-slide-leave-active {
  transition: opacity 0.25s ease, max-height 0.28s cubic-bezier(0.4, 0, 0.2, 1);
  overflow: hidden;
}
.banner-slide-enter-from,
.banner-slide-leave-to {
  max-height: 0;
  opacity: 0;
}
.banner-slide-enter-to,
.banner-slide-leave-from {
  max-height: 80px;
}
</style>
