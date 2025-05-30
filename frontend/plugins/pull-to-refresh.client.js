import PullToRefreshWrapper from '~/components/common/PullToRefreshWrapper.vue';
import PullToRefreshIndicator from '~/components/common/PullToRefreshIndicator.vue';

export default defineNuxtPlugin((nuxtApp) => {
  // Register pull-to-refresh components globally
  nuxtApp.vueApp.component('PullToRefreshWrapper', PullToRefreshWrapper);
  nuxtApp.vueApp.component('PullToRefreshIndicator', PullToRefreshIndicator);

  // Add global pull-to-refresh functionality
  nuxtApp.provide('pullToRefresh', {
    // Global refresh function that can be called from anywhere
    globalRefresh: async () => {
      const eventBus = useEventBus();
      eventBus.emit('global-refresh');
    },
    
    // Page-specific refresh
    pageRefresh: async (pageName) => {
      const eventBus = useEventBus();
      eventBus.emit('page-refresh', pageName);
    },
    
    // Data refresh
    dataRefresh: async (dataType) => {
      const eventBus = useEventBus();
      eventBus.emit('data-refresh', dataType);
    }
  });

  // Add meta information for mobile app feel
  useHead({
    meta: [
      // Viewport for mobile optimization
      { 
        name: 'viewport', 
        content: 'width=device-width, initial-scale=1.0, user-scalable=no, viewport-fit=cover' 
      },
      
      // Apple mobile web app
      { name: 'apple-mobile-web-app-capable', content: 'yes' },
      { name: 'apple-mobile-web-app-status-bar-style', content: 'default' },
      { name: 'apple-mobile-web-app-title', content: 'AdsyClub' },
      
      // Android Chrome
      { name: 'mobile-web-app-capable', content: 'yes' },
      { name: 'theme-color', content: '#10b981' },
      
      // Microsoft tiles
      { name: 'msapplication-TileColor', content: '#10b981' },
      { name: 'msapplication-tap-highlight', content: 'no' },
      
      // Prevent zooming
      { name: 'format-detection', content: 'telephone=no' },
      
      // Touch icons
      { name: 'apple-touch-icon', content: '/apple-touch-icon.png' },
    ],
    
    // Additional styles for mobile app feel
    style: [
      {
        innerHTML: `
          /* Prevent overscroll bounce on iOS */
          html, body {
            overscroll-behavior: none;
            -webkit-overflow-scrolling: touch;
          }
          
          /* Smooth scrolling */
          html {
            scroll-behavior: smooth;
          }
          
          /* Remove tap highlights */
          * {
            -webkit-tap-highlight-color: transparent;
            -webkit-touch-callout: none;
            -webkit-user-select: none;
            -khtml-user-select: none;
            -moz-user-select: none;
            -ms-user-select: none;
            user-select: none;
          }
          
          /* Allow text selection where needed */
          input, textarea, [contenteditable="true"], .selectable {
            -webkit-user-select: text;
            -khtml-user-select: text;
            -moz-user-select: text;
            -ms-user-select: text;
            user-select: text;
          }
          
          /* iOS safe area support */
          .safe-area-top {
            padding-top: env(safe-area-inset-top);
          }
          
          .safe-area-bottom {
            padding-bottom: env(safe-area-inset-bottom);
          }
          
          .safe-area-left {
            padding-left: env(safe-area-inset-left);
          }
          
          .safe-area-right {
            padding-right: env(safe-area-inset-right);
          }
          
          /* Pull to refresh animations */
          @keyframes pullToRefreshBounce {
            0% { transform: translateY(-10px); opacity: 0; }
            50% { transform: translateY(0px); opacity: 1; }
            100% { transform: translateY(0px); opacity: 1; }
          }
          
          @keyframes pullToRefreshSpin {
            from { transform: rotate(0deg); }
            to { transform: rotate(360deg); }
          }
          
          /* Smooth transitions for app-like feel */
          .page-transition {
            transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          }
          
          /* Loading skeletons */
          @keyframes shimmer {
            0% { background-position: -200px 0; }
            100% { background-position: calc(200px + 100%) 0; }
          }
          
          .skeleton {
            background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
            background-size: 200px 100%;
            animation: shimmer 1.5s infinite;
          }
          
          /* Dark mode skeletons */
          @media (prefers-color-scheme: dark) {
            .skeleton {
              background: linear-gradient(90deg, #374151 25%, #4b5563 50%, #374151 75%);
              background-size: 200px 100%;
            }
          }
        `,
        type: 'text/css'
      }
    ]
  });
});
