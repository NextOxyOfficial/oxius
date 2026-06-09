/**
 * Web Google sign-in via Firebase Auth — mirrors the Flutter app, which signs
 * in with Google through Firebase and posts the resulting Firebase ID token to
 * the backend `/auth/social/` endpoint. We do the same here so one backend flow
 * serves both clients.
 *
 * Firebase is loaded lazily (dynamic import) on the click so it never runs
 * during static prerender and isn't in the initial bundle. These config values
 * are the public Firebase web app config (safe to ship to the browser).
 */
const firebaseConfig = {
  apiKey: 'AIzaSyA37bqGS56Q1XLX8FZdZYCxsURup2zy6SU',
  authDomain: 'adsyclub.firebaseapp.com',
  projectId: 'adsyclub',
  storageBucket: 'adsyclub.firebasestorage.app',
  messagingSenderId: '866607241594',
  appId: '1:866607241594:web:461a92e8b199c0e3a79ec3',
}

export function useFirebaseAuth() {
  /**
   * Opens the Google account picker and returns a fresh Firebase ID token plus
   * basic profile info. Throws on cancel/failure (caller handles).
   */
  const signInWithGoogle = async (): Promise<{
    idToken: string
    email: string | null
    name: string | null
    photo: string | null
  }> => {
    const { initializeApp, getApps, getApp } = await import('firebase/app')
    const { getAuth, GoogleAuthProvider, signInWithPopup } = await import(
      'firebase/auth'
    )

    const app = getApps().length ? getApp() : initializeApp(firebaseConfig)
    const auth = getAuth(app)

    const provider = new GoogleAuthProvider()
    provider.setCustomParameters({ prompt: 'select_account' })

    const result = await signInWithPopup(auth, provider)
    const idToken = await result.user.getIdToken(true)

    return {
      idToken,
      email: result.user.email,
      name: result.user.displayName,
      photo: result.user.photoURL,
    }
  }

  return { signInWithGoogle }
}
