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

function isMobileBrowser() {
  if (typeof navigator === 'undefined') {
    return false
  }

  return /android|iphone|ipad|ipod/i.test(navigator.userAgent)
}

function isStandaloneContext() {
  if (typeof window === 'undefined') {
    return false
  }

  return window.matchMedia?.('(display-mode: standalone)').matches === true
}

function buildDeepLink(fullPath: string) {
  const normalizedPath = fullPath.startsWith('/') ? fullPath.slice(1) : fullPath
  return `adsyclub://${normalizedPath}`
}

function tryOpenApp(fullPath: string) {
  if (typeof window === 'undefined' || typeof document === 'undefined') {
    return
  }

  const attemptKey = `app-open-bridge:${fullPath}`
  const lastAttemptAt = Number(sessionStorage.getItem(attemptKey) || '0')
  if (Date.now() - lastAttemptAt < 15000) {
    return
  }

  sessionStorage.setItem(attemptKey, Date.now().toString())

  let completed = false
  const finish = () => {
    if (completed) {
      return
    }
    completed = true
    document.removeEventListener('visibilitychange', onVisibilityChange)
  }

  const onVisibilityChange = () => {
    if (document.hidden) {
      finish()
    }
  }

  document.addEventListener('visibilitychange', onVisibilityChange)

  window.setTimeout(() => {
    if (completed) {
      return
    }

    window.location.href = buildDeepLink(fullPath)

    window.setTimeout(() => {
      finish()
    }, 2500)
  }, 250)
}

export default defineNuxtPlugin(() => {
  if (process.server || typeof window === 'undefined') {
    return
  }

  const router = useRouter()

  const maybeOpenApp = (fullPath: string) => {
    const pathOnly = fullPath.split('?')[0] || '/'
    if (!isSupportedPath(pathOnly)) {
      return
    }

    if (!isMobileBrowser() || isStandaloneContext()) {
      return
    }

    tryOpenApp(fullPath)
  }

  maybeOpenApp(window.location.pathname + window.location.search)

  router.afterEach((to) => {
    maybeOpenApp(to.fullPath)
  })
})