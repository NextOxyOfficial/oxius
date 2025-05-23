export default defineAppConfig({
  ui: {
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
    },
    notifications: {
      wrapper: "fixed flex flex-col justify-end z-[55]",
      position: "bottom-10 sm:bottom-0 end-0",
      width: "w-full sm:w-96",
      container: "px-4 sm:px-6 py-6 space-y-3 overflow-y-auto",
    },
  },
});
