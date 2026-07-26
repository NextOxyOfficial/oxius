type AppPlatform = 'android' | 'ios' | 'desktop'

type OpenAppResult = 'opened' | 'fallback' | 'ignored' | 'throttled' | 'unavailable'

interface OpenAppOptions {
  fullPath?: string
  fallbackToStore?: boolean
  fallbackDelayMs?: number
  cooldownMs?: number
  force?: boolean
  fallbackUrl?: string | null
}

export function useSmartAppLinks() {
  const runtimeConfig = useRuntimeConfig()
  const { isInAppWebview, isEmbeddedWebviewUA } = useInAppWebview()

  const deepLinkScheme = runtimeConfig.public.deepLinkScheme || 'adsyclub'
  const androidStoreUrl =
    runtimeConfig.public.androidStoreUrl ||
    `https://play.google.com/store/apps/details?id=${runtimeConfig.public.androidAppPackage || 'com.oxius.app'}`
  const iosStoreUrl = runtimeConfig.public.iosStoreUrl || 'https://apps.apple.com/'
  const appDownloadFallbackPath =
    runtimeConfig.public.appDownloadFallbackPath || '/download'

  const getPlatform = (): AppPlatform => {
    if (typeof navigator === 'undefined') {
      return 'desktop'
    }

    const userAgent = navigator.userAgent.toLowerCase()

    if (/android/.test(userAgent)) {
      return 'android'
    }

    if (/iphone|ipad|ipod/.test(userAgent)) {
      return 'ios'
    }

    return 'desktop'
  }

  const isMobileBrowser = () => getPlatform() !== 'desktop'

  const isStandaloneContext = () => {
    if (typeof window === 'undefined') {
      return false
    }

    const nav = window.navigator as Navigator & { standalone?: boolean }
    return (
      window.matchMedia?.('(display-mode: standalone)').matches === true ||
      nav.standalone === true
    )
  }

  const buildDeepLink = (fullPath = '/') => {
    const parsedUrl = new URL(fullPath, 'https://adsyclub.com')
    const absoluteUrl = `${parsedUrl.origin}${parsedUrl.pathname}${parsedUrl.search}${parsedUrl.hash}`

    return `${deepLinkScheme}://open?url=${encodeURIComponent(absoluteUrl)}`
  }

  const getStoreUrl = (platform = getPlatform()) => {
    if (platform === 'android') {
      return androidStoreUrl
    }

    if (platform === 'ios') {
      return iosStoreUrl
    }

    return null
  }

  const redirectToUrl = (targetUrl: string, replace = true) => {
    if (typeof window === 'undefined') {
      return false
    }

    if (replace) {
      window.location.replace(targetUrl)
    } else {
      window.location.href = targetUrl
    }

    return true
  }

  const redirectToStore = (
    platform = getPlatform(),
    options: { replace?: boolean; fallbackToDownload?: boolean } = {}
  ) => {
    const { replace = true, fallbackToDownload = true } = options

    // Already inside an app's WebView — bouncing to the store would abandon
    // whatever the user is doing in the panel.
    if (isInAppWebview() || isEmbeddedWebviewUA()) {
      return false
    }

    const storeUrl = getStoreUrl(platform)

    if (storeUrl) {
      return redirectToUrl(storeUrl, replace)
    }

    if (fallbackToDownload && platform !== 'desktop') {
      return redirectToUrl(`${appDownloadFallbackPath}?platform=${platform}`, replace)
    }

    return false
  }

  const tryOpenApp = ({
    fullPath = '/',
    fallbackToStore = false,
    fallbackDelayMs = 1500,
    cooldownMs = 15000,
    force = false,
    fallbackUrl = null,
  }: OpenAppOptions = {}): Promise<OpenAppResult> => {
    if (
      typeof window === 'undefined' ||
      typeof document === 'undefined' ||
      !isMobileBrowser() ||
      isStandaloneContext() ||
      // Single choke point: inside a WebView the deep-link navigation below is
      // what produces Android's ERR_UNKNOWN_URL_SCHEME error page. Guarding
      // here covers every caller (bridge plugin, smart banner, /download)
      // rather than trusting each one to check. The UA arm also covers app
      // builds released before the `app=1` flag existed, so users who have not
      // updated get a working panel from this web deploy alone.
      isInAppWebview() ||
      isEmbeddedWebviewUA()
    ) {
      return Promise.resolve('ignored')
    }

    const attemptKey = `smart-app-open:${fullPath}:${fallbackToStore ? 'store' : 'app'}`
    if (!force) {
      const lastAttemptAt = Number(sessionStorage.getItem(attemptKey) || '0')
      if (Date.now() - lastAttemptAt < cooldownMs) {
        return Promise.resolve('throttled')
      }
    }

    sessionStorage.setItem(attemptKey, Date.now().toString())

    return new Promise((resolve) => {
      let settled = false

      const finish = (result: OpenAppResult) => {
        if (settled) {
          return
        }

        settled = true
        document.removeEventListener('visibilitychange', handleVisibilityChange)
        window.removeEventListener('pagehide', handlePageHide)
        window.removeEventListener('blur', handleBlur)
        window.clearTimeout(fallbackTimer)
        resolve(result)
      }

      const handleVisibilityChange = () => {
        if (document.hidden) {
          finish('opened')
        }
      }

      const handlePageHide = () => {
        finish('opened')
      }

      const handleBlur = () => {
        window.setTimeout(() => {
          if (document.hidden) {
            finish('opened')
          }
        }, 100)
      }

      document.addEventListener('visibilitychange', handleVisibilityChange)
      window.addEventListener('pagehide', handlePageHide)
      window.addEventListener('blur', handleBlur)

      const fallbackTimer = window.setTimeout(() => {
        if (document.hidden) {
          finish('opened')
          return
        }

        if (!fallbackToStore) {
          finish('unavailable')
          return
        }

        const didRedirect = fallbackUrl
          ? redirectToUrl(fallbackUrl)
          : redirectToStore(getPlatform(), { fallbackToDownload: false })

        finish(didRedirect ? 'fallback' : 'unavailable')
      }, fallbackDelayMs)

      window.location.href = buildDeepLink(fullPath)
    })
  }

  return {
    buildDeepLink,
    getPlatform,
    getStoreUrl,
    isMobileBrowser,
    isStandaloneContext,
    redirectToStore,
    tryOpenApp,
  }
}
