export default defineAppConfig({
  ui: {
    container: {
      base: "mx-auto",
      padding: "px-2 sm:px-6 lg:px-8",
      constrained: "max-w-7xl",
    },
    card: {
      background: "bg-white dark:bg-white",
    },
    modal: {
      container: "items-center sm:items-center",
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
  },
});
