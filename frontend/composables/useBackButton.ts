import { App } from '@capacitor/app'
import { useRouter } from 'vue-router'

export const useBackButton = () => {
  const router = useRouter()

  if (process.client) {
    // Listen for the hardware back button on mobile devices
    App.addListener('backButton', ({ canGoBack }) => {
      console.log('Back button pressed, canGoBack:', canGoBack)
      
      const currentRoute = router.currentRoute.value
      console.log('Current route:', currentRoute.path)
      
      // Define your main/home routes
      const homeRoutes = ['/', '/home', '/dashboard', '/main']
      
      // Check if we can go back in the browser history
      if (canGoBack && window.history.length > 1) {
        // Go back to the previous page in the app
        router.back()
      } else if (!homeRoutes.includes(currentRoute.path)) {
        // If we can't go back but we're not on home, navigate to home
        router.push('/')
      } else {
        // If we're already on a home page and can't go back, show exit confirmation
        showExitConfirmation()
      }
    })
  }
}

const showExitConfirmation = async () => {
  try {
    // For better UX, you might want to use a native dialog
    // But for now, using confirm as fallback
    const shouldExit = confirm('Are you sure you want to exit the app?')
    
    if (shouldExit) {
      App.exitApp()
    }
  } catch (error) {
    console.error('Error showing exit confirmation:', error)
    // Fallback: just exit
    App.exitApp()
  }
}
