import type { Ref } from "vue";

export function useRideshareSocket() {
  const runtimeConfig = useRuntimeConfig();
  const rideSocket = useState<WebSocket | null>("rideshare-ride-socket", () => null);
  const dispatchSocket = useState<WebSocket | null>("rideshare-dispatch-socket", () => null);
  const rideConnectionState = useState<string>("rideshare-ride-socket-state", () => "idle");
  const dispatchConnectionState = useState<string>("rideshare-dispatch-socket-state", () => "idle");
  const lastRideEvent = useState<any>("rideshare-last-ride-event", () => null);
  const lastDispatchEvent = useState<any>("rideshare-last-dispatch-event", () => null);

  const buildWebSocketUrl = async (path: string) => {
    const baseUrl = runtimeConfig.public.baseURL;
    const wsBaseUrl = baseUrl.startsWith("https://")
      ? baseUrl.replace("https://", "wss://")
      : baseUrl.replace("http://", "ws://");
    const { getValidToken } = useAuth();
    const token = (await getValidToken()) || useCookie("adsyclub-jwt").value;
    if (!token) {
      return null;
    }
    return `${wsBaseUrl}${path}${path.includes("?") ? "&" : "?"}token=${encodeURIComponent(token || "")}`;
  };

  const openSocket = ({
    getUrl,
    socketRef,
    stateRef,
    lastEventRef,
    onMessage,
    maxReconnectAttempts = Number.POSITIVE_INFINITY,
  }: {
    getUrl: () => Promise<string | null>;
    socketRef: Ref<WebSocket | null>;
    stateRef: Ref<string>;
    lastEventRef: Ref<any>;
    onMessage?: (payload: any) => void;
    maxReconnectAttempts?: number;
  }) => {
    if (typeof window === "undefined") {
      return () => {};
    }

    let reconnectAttempts = 0;
    let reconnectTimer: ReturnType<typeof setTimeout> | null = null;
    let shouldReconnect = true;

    const connect = async () => {
      stateRef.value = reconnectAttempts > 0 ? "reconnecting" : "connecting";
      const url = await getUrl();
      if (!url) {
        stateRef.value = "failed";
        return;
      }
      const socket = new WebSocket(url);
      socketRef.value = socket;

      socket.onopen = () => {
        reconnectAttempts = 0;
        stateRef.value = "connected";
      };

      socket.onmessage = (event) => {
        try {
          const payload = JSON.parse(event.data);
          lastEventRef.value = payload;
          onMessage?.(payload);
        } catch (error) {
          console.error("Rideshare socket parse error:", error);
        }
      };

      socket.onerror = () => {
        stateRef.value = "error";
      };

      socket.onclose = (event) => {
        socketRef.value = null;
        if (!shouldReconnect) {
          stateRef.value = "closed";
          return;
        }

        if ([4001, 4003, 4004, 1008].includes(event.code)) {
          stateRef.value = "failed";
          return;
        }

        if (Number.isFinite(maxReconnectAttempts) && reconnectAttempts >= maxReconnectAttempts) {
          stateRef.value = "failed";
          return;
        }

        reconnectAttempts += 1;
        stateRef.value = "reconnecting";
        reconnectTimer = setTimeout(connect, Math.min(1000 * reconnectAttempts, 5000));
      };
    };

    connect();

    return () => {
      shouldReconnect = false;
      if (reconnectTimer) {
        clearTimeout(reconnectTimer);
      }
      socketRef.value?.close();
      socketRef.value = null;
      stateRef.value = "closed";
    };
  };

  const connectRideSocket = (rideId: string, onMessage?: (payload: any) => void) => {
    return openSocket({
      getUrl: () => buildWebSocketUrl(`/ws/rides/${rideId}/`),
      socketRef: rideSocket as Ref<WebSocket | null>,
      stateRef: rideConnectionState as Ref<string>,
      lastEventRef: lastRideEvent as Ref<any>,
      onMessage,
    });
  };

  const connectDriverDispatchSocket = (onMessage?: (payload: any) => void) => {
    return openSocket({
      getUrl: () => buildWebSocketUrl(`/ws/rides/driver/dispatch/`),
      socketRef: dispatchSocket as Ref<WebSocket | null>,
      stateRef: dispatchConnectionState as Ref<string>,
      lastEventRef: lastDispatchEvent as Ref<any>,
      onMessage,
    });
  };

  const sendRideEvent = (payload: Record<string, any>) => {
    if (rideSocket.value?.readyState === WebSocket.OPEN) {
      rideSocket.value.send(JSON.stringify(payload));
    }
  };

  const sendDispatchEvent = (payload: Record<string, any>) => {
    if (dispatchSocket.value?.readyState === WebSocket.OPEN) {
      dispatchSocket.value.send(JSON.stringify(payload));
    }
  };

  const closeRideSocket = () => {
    rideSocket.value?.close();
  };

  const closeDispatchSocket = () => {
    dispatchSocket.value?.close();
  };

  return {
    rideSocket,
    dispatchSocket,
    rideConnectionState,
    dispatchConnectionState,
    lastRideEvent,
    lastDispatchEvent,
    connectRideSocket,
    connectDriverDispatchSocket,
    sendRideEvent,
    sendDispatchEvent,
    closeRideSocket,
    closeDispatchSocket,
  };
}
