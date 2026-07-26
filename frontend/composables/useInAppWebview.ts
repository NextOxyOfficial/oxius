// Detects that this page is running INSIDE the AdsyClub app's own WebView
// (e.g. the ads panel opened from the "বিজ্ঞাপন দিন" button) rather than in a
// normal mobile browser.
//
// Why this exists: inside the app WebView every "open the app" affordance is
// not just useless but actively breaking.
//   * Android WebView cannot resolve custom schemes, so navigating to
//     `adsyclub://open?url=...` replaces the panel with a
//     net::ERR_UNKNOWN_URL_SCHEME error page. (iOS silently ignores it, which
//     is why this only ever showed up on Android.)
//   * The store fallback would yank the user out to Google Play mid-task.
//   * "Download the app" banners are nonsense to someone already in the app.
//
// The app appends `?app=1` when it opens a web page. That flag is remembered
// for the rest of the session so in-panel navigation (which drops the query
// string) stays correctly marked. A module-scoped copy backs up sessionStorage
// in case storage is unavailable.

const FLAG_KEY = 'adsy-in-app-webview'

let stickyInApp = false

export function useInAppWebview() {
  /// True for ANY Android WebView (the `; wv` UA marker), not just ours.
  ///
  /// Kept separate from `isInAppWebview` on purpose. Every such WebView fails
  /// custom-scheme navigation the same way, so the deep-link/store handoff has
  /// to be suppressed for all of them — including app builds that predate the
  /// `app=1` flag, which is what makes the ads panel usable for users who have
  /// not updated yet. App-download banners stay keyed to `isInAppWebview()`
  /// alone, so a third-party in-app browser still gets the install prompt.
  const isEmbeddedWebviewUA = (): boolean => {
    if (typeof navigator === 'undefined') {
      return false
    }

    return /;\s*wv[;)]/.test(navigator.userAgent)
  }

  const isInAppWebview = (): boolean => {
    if (typeof window === 'undefined') {
      return false
    }

    if (stickyInApp) {
      return true
    }

    let flagged = false

    try {
      const params = new URLSearchParams(window.location.search)
      // `app=1` is what the native app appends; `inapp=1` kept as an alias so
      // an older build's links keep working.
      flagged = params.get('app') === '1' || params.get('inapp') === '1'

      // The app enters through /auth/app-login?token=..&redirect=<target>, and
      // the flag lives on that encoded target. Read it here so we are already
      // marked on the FIRST page load, before the hop into the real page —
      // otherwise the bridge could fire during that navigation.
      if (!flagged) {
        const redirect = params.get('redirect')
        if (redirect) {
          const redirectQuery = redirect.split('?')[1]
          if (redirectQuery) {
            const nested = new URLSearchParams(redirectQuery)
            flagged = nested.get('app') === '1' || nested.get('inapp') === '1'
          }
        }
      }
    } catch {
      flagged = false
    }

    if (!flagged) {
      try {
        flagged = window.sessionStorage.getItem(FLAG_KEY) === '1'
      } catch {
        flagged = false
      }
    }

    if (flagged) {
      stickyInApp = true
      try {
        window.sessionStorage.setItem(FLAG_KEY, '1')
      } catch {
        // Storage blocked — stickyInApp still carries it for this session.
      }
    }

    return flagged
  }

  return { isInAppWebview, isEmbeddedWebviewUA }
}
