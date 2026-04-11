const supportedPrefixes = [
  '/deposit-withdraw',
  '/verify-payment',
  '/payment-callback.html',
  '/business-network',
  '/classified-details',
  '/sale',
  '/food-zone',
]

function isSupportedPath(path: string) {
  return supportedPrefixes.some((prefix) => path === prefix || path.startsWith(`${prefix}/`))
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

    if (pathOnly === '/') {
      await tryOpenApp({
        fullPath,
        fallbackToStore: true,
        fallbackDelayMs: 1400,
        cooldownMs: 20000,
      })
      return
    }

    if (!isSupportedPath(pathOnly)) {
      return
    }

    await tryOpenApp({
      fullPath,
      fallbackDelayMs: 2500,
      cooldownMs: 15000,
    })
  }

  void maybeOpenApp(window.location.pathname + window.location.search)

  router.afterEach((to) => {
    void maybeOpenApp(to.fullPath)
  })
})