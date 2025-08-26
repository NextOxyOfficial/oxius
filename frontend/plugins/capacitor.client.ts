import { StatusBar, Style } from '@capacitor/status-bar'
import { Capacitor } from '@capacitor/core'

export default defineNuxtPlugin(async () => {
  // Only run on mobile platforms
  if (Capacitor.isNativePlatform()) {
    try {
      // DISABLED: Let native Android handle all status bar styling
      // await StatusBar.setStyle({ style: Style.Dark })
      
      // Only set background color and overlay settings
      await StatusBar.setBackgroundColor({ color: '#ffffff' })
      await StatusBar.show()
      await StatusBar.setOverlaysWebView({ overlay: false })
      
    } catch (error) {
      console.error('Error setting up StatusBar:', error)
    }
  }
})
