// Deep-link bridge: silently tries to hand off specific in-app flows to the
// native app when the user is already on a supported path.
// NOTE: The home-page "open app / go to store" prompt is handled by the
// SmartAppBanner component (components/common/SmartAppBanner.vue) which
// shows a dismissible UI with a Cancel option. No automatic redirects here.

const deepLinkPrefixes = [
  '/deposit-withdraw',
  '/verify-payment',
  '/payment-callback.html',
  '/payment-cancel.html',
  '/adsy-news',
  '/business-network',
  '/classified-details',
  '/classified-categories',
  '/product-details',
  '/eshop',
  '/order',
  '/my-gigs',
  '/pending-tasks',
  '/post-a-gig',
  '/micro-gigs',
  '/workspace',
  '/workspaces',
  '/seller',
  '/sale',
  '/food-zone',
  '/mobile-recharge',
  '/upgrade-to-pro',
  '/shop-manager',
  '/rideshare',
]

function isDeepLinkPath(path: string) {
  return deepLinkPrefixes.some(
    (prefix) => path === prefix || path.startsWith(`${prefix}/`)
  )
}

function isPaymentPath(path: string) {
  return [
    '/deposit-withdraw',
    '/verify-payment',
    '/payment-callback.html',
    '/payment-cancel.html',
  ].some((prefix) => path === prefix || path.startsWith(`${prefix}/`))
}

export default defineNuxtPlugin(() => {
  if (typeof window === 'undefined') {
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

    // Bridge only URLs that the native router can resolve. If the app is not
    // installed, mobile users land in the correct store instead of a dead page.
    if (!isDeepLinkPath(pathOnly)) {
      return
    }

    await tryOpenApp({
      fullPath,
      fallbackToStore: !isPaymentPath(pathOnly),
      fallbackDelayMs: 2500,
      cooldownMs: 15000,
    })
  }

  void maybeOpenApp(window.location.pathname + window.location.search)

  router.afterEach((to) => {
    void maybeOpenApp(to.fullPath)
  })
})
