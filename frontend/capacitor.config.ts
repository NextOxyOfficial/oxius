import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.adsyclub.app',
  appName: 'AdsyClub',
  webDir: 'dist',  server: {
    androidScheme: 'https'
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
