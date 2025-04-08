import type { Config } from "tailwindcss";

export default <Partial<Config>>{
  theme: {
    extend: {
      fontFamily: {
        AnekBangla: '"Anek Bangla", serif',
      },
      aspectRatio: {
        auto: "auto",
        square: "1 / 1",
        video: "16 / 9",
      },
      animation: {
        "spin-clockwise":
          "spin-clockwise 1.8s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite",
        "spin-counter":
          "spin-counter 2.4s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite",
        "text-glow": "text-glow 2s ease-in-out infinite alternate",
        "fade-in": "fade-in 0.5s ease-out forwards",
        "bounce-delay-1": "bounce 1.4s infinite ease-in-out both -0.32s",
        "bounce-delay-2": "bounce 1.4s infinite ease-in-out both -0.16s",
        "bounce-delay-3": "bounce 1.4s infinite ease-in-out both",
      },
      keyframes: {
        "spin-clockwise": {
          from: { transform: "rotate(0deg)" },
          to: { transform: "rotate(360deg)" },
        },
        "spin-counter": {
          from: { transform: "rotate(360deg)" },
          to: { transform: "rotate(0deg)" },
        },
        "text-glow": {
          "0%": {
            filter: "brightness(1)",
            textShadow: "0 0 0 rgba(59, 130, 246, 0)",
          },
          "100%": {
            filter: "brightness(1.2)",
            textShadow: "0 0 8px rgba(59, 130, 246, 0.5)",
          },
        },
        "fade-in": {
          from: { opacity: "0", transform: "translateY(10px)" },
          to: { opacity: "1", transform: "translateY(0)" },
        },
        bounce: {
          "0%, 80%, 100%": { transform: "scale(0.8)", opacity: "0.5" },
          "40%": { transform: "scale(1.2)", opacity: "1" },
        },
      },
    },
  },
};
