import { StatusBar, Style } from '@capacitor/status-bar'
import { Capacitor } from '@capacitor/core'

export default defineNuxtPlugin(async () => {
  // Only run on mobile platforms
  if (Capacitor.isNativePlatform()) {
    try {
      // Set the status bar style for dark content on white background
      await StatusBar.setStyle({ style: Style.Light })
      
      // Set the status bar background color
      await StatusBar.setBackgroundColor({ color: '#ffffff' })
      
      // Make sure the status bar is visible and content doesn't overlay
      await StatusBar.show()
      
      // Ensure the web view doesn't overlay the status bar
      await StatusBar.setOverlaysWebView({ overlay: false })
      
    } catch (error) {
      console.error('Error setting up StatusBar:', error)
    }
  }
})
