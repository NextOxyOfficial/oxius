// Deep-link bridge: silently tries to hand off specific in-app flows to the
// native app when the user is already on a supported path.
// NOTE: The home-page "open app / go to store" prompt is handled by the
// SmartAppBanner component (components/common/SmartAppBanner.vue) which
// shows a dismissible UI with a Cancel option. No automatic redirects here.

const deepLinkPrefixes = [
  '/deposit-withdraw',
  '/verify-payment',
  '/payment-callback.html',
]

function isDeepLinkPath(path: string) {
  return deepLinkPrefixes.some(
    (prefix) => path === prefix || path.startsWith(`${prefix}/`)
  )
}

export default defineNuxtPlugin(() => {
  if (process.server || typeof window === 'undefined') {
    return
  }

  const router = useRouter()
  const { isMobileBrowser, isStandaloneContext, tryOpenApp } = useSmartAppLinks()

  const maybeOpenApp = async (fullPath: string) => {
    const pathOnly = fullPath.split('?')[0] || '/'

    if (!isMobileBrowser() || isStandaloneContext()) {
      return
    }

    const queryString = fullPath.split('?')[1] || ''
    const searchParams = new URLSearchParams(queryString)
    if (searchParams.get('web') === '1' || searchParams.get('openApp') === '0') {
      return
    }

    // Only silently bridge deep-linkable flows (no store fallback).
    // The SmartAppBanner handles everything else with a user-visible prompt.
    if (!isDeepLinkPath(pathOnly)) {
      return
    }

    await tryOpenApp({
      fullPath,
      fallbackToStore: false,
      fallbackDelayMs: 2500,
      cooldownMs: 15000,
    })
  }

  void maybeOpenApp(window.location.pathname + window.location.search)

  router.afterEach((to) => {
    void maybeOpenApp(to.fullPath)
  })
})