import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.adsyclub.app',
  appName: 'AdsyClub',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
    cleartext: true,
    allowNavigation: ['adsyclub.com', 'localhost', '127.0.0.1'],
    url: 'https://adsyclub.com', // Add this for production builds
    iosScheme: 'adsyclub',
    hostname: 'adsyclub.com'
  },  plugins: {
    SplashScreen: {
      launchShowDuration: 0,
      launchAutoHide: true,
      showSpinner: false,
      androidSplashResourceName: "splash",
      splashFullScreen: false,
      splashImmersive: false
    },
    Camera: {
      permissions: ['camera', 'photos']
    },
    StatusBar: {
      style: 'dark',
      backgroundColor: '#ffffff',
      overlaysWebView: false
    }
  }
};

export default config;
