export default defineAppConfig({
  ui: {
    primary: 'emerald',
    gray: 'slate',
    container: {
      base: "mx-auto",
      padding: "px-1 sm:px-6 lg:px-8",
      constrained: "max-w-7xl",
    },
    card: {
      background: "bg-white dark:bg-white",
    },
    modal: {
      container:
        "flex min-h-full items-center sm:items-center justify-center text-center",
    },
    input: {
      size: {
        "2xs": "text-base sm:text-xs",
        xs: "text-base sm:text-xs",
        sm: "text-base sm:text-sm",
        md: "text-base sm:text-sm",
        lg: "text-base sm:text-sm",
        xl: "text-base sm:text-base",
      },
    },    notifications: {
      wrapper: "fixed flex flex-col justify-end z-[60]",
      position: "bottom-20 sm:bottom-4 end-0",
      width: "w-full sm:w-96",
      container: "px-4 sm:px-6 py-4 space-y-3 overflow-y-auto",
      title: "font-semibold text-gray-900 dark:text-white text-sm",
      description: "mt-1 text-sm leading-5 text-gray-600 dark:text-gray-300",
      background: "bg-white/95 dark:bg-gray-800/95 backdrop-blur-sm",
      border: "border-0",
      ring: "ring-1 ring-gray-200/50 dark:ring-gray-700/50",
      rounded: "rounded-xl",
      shadow: "shadow-xl shadow-gray-200/50 dark:shadow-gray-900/50",
      padding: "p-4",
      gap: "gap-3",
      icon: {
        base: "flex-shrink-0 w-5 h-5",
        color: {
          gray: "text-gray-400 dark:text-gray-500",
          red: "text-red-500 dark:text-red-400", 
          orange: "text-orange-500 dark:text-orange-400",
          amber: "text-amber-500 dark:text-amber-400",
          yellow: "text-yellow-500 dark:text-yellow-400",
          lime: "text-lime-500 dark:text-lime-400",
          green: "text-green-500 dark:text-green-400",
          emerald: "text-white dark:text-white",
          teal: "text-teal-500 dark:text-teal-400",
          cyan: "text-cyan-500 dark:text-cyan-400",
          sky: "text-sky-500 dark:text-sky-400",
          blue: "text-blue-500 dark:text-blue-400",
          indigo: "text-indigo-500 dark:text-indigo-400",
          violet: "text-violet-500 dark:text-violet-400",
          purple: "text-purple-500 dark:text-purple-400",
          fuchsia: "text-fuchsia-500 dark:text-fuchsia-400",
          pink: "text-pink-500 dark:text-pink-400",
          rose: "text-rose-500 dark:text-rose-400",
        }
      },
      default: {
        color: "white",
        icon: "i-heroicons-information-circle",
        timeout: 5000,
        closeButton: {
          icon: "i-heroicons-x-mark-20-solid",
          color: "gray",
          variant: "ghost",
          size: "sm"
        }
      },
      // Enhanced authentication toast variants
      auth: {
        success: {
          color: "green",
          icon: "i-heroicons-sparkles",
          timeout: 6000,
          class: "auth-success-toast",
          animation: "celebration-bounce"
        },
        registration: {
          color: "white", 
          icon: "i-heroicons-trophy",
          timeout: 7000,
          class: "auth-registration-toast",
          animation: "celebration-bounce"
        },
        welcome: {
          color: "blue",
          icon: "i-heroicons-hand-raised", 
          timeout: 5000,
          class: "auth-welcome-toast"
        }
      }
    },
  },
});
