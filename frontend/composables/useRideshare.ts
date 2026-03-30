type RideshareApiResult<T> = {
  success: boolean;
  message: string;
  data: T | null;
  errors?: any;
};

type RidePoint = {
  name: string;
  latitude: number;
  longitude: number;
  address?: Record<string, any>;
};

function parseSuccessEnvelope<T>(payload: any): RideshareApiResult<T> {
  if (
    payload &&
    typeof payload === "object" &&
    Object.prototype.hasOwnProperty.call(payload, "success") &&
    Object.prototype.hasOwnProperty.call(payload, "message")
  ) {
    return {
      success: Boolean(payload.success),
      message: payload.message || "Success",
      data: (payload.data ?? null) as T | null,
      errors: payload.errors,
    };
  }

  return {
    success: true,
    message: "Success",
    data: payload as T,
  };
}

function parseErrorEnvelope<T>(error: any): RideshareApiResult<T> {
  const payload =
    error?.data ||
    error?.response?._data ||
    error?.response?.data ||
    error?.originalError?.data ||
    null;

  return {
    success: false,
    message:
      payload?.message ||
      payload?.detail ||
      error?.message ||
      error?.statusMessage ||
      "Request failed.",
    data: null,
    errors: payload?.errors || payload || error,
  };
}

export function useRideshare() {
  const { get, post, put, patch, del } = useApi();

  const request = async <T>(executor: () => Promise<{ data: any; error: any }>) => {
    const response = await executor();
    if (response.error) {
      return parseErrorEnvelope<T>(response.error);
    }
    return parseSuccessEnvelope<T>(response.data);
  };

  const normalizePoint = (item: any): RidePoint | null => {
    if (!item) {
      return null;
    }

    const name = item.name || item.display_name || item.pickup_address || item.drop_address || "Selected location";
    const latitude = Number(item.latitude ?? item.lat ?? item.pickup_latitude ?? item.drop_latitude);
    const longitude = Number(item.longitude ?? item.lon ?? item.pickup_longitude ?? item.drop_longitude);

    if (Number.isNaN(latitude) || Number.isNaN(longitude)) {
      return null;
    }

    return {
      name,
      latitude,
      longitude,
      address: item.address || {},
    };
  };

  const estimateRide = async (payload: Record<string, any>) => {
    return request<any>(() => post("/rides/estimate/", payload));
  };

  const createRide = async (payload: Record<string, any>) => {
    return request<any>(() => post("/rides/create/", payload));
  };

  const listRides = async (params: Record<string, any> = {}) => {
    return request<any[]>(() => get("/rides/", { params }));
  };

  const getRide = async (rideId: string) => {
    return request<any>(() => get(`/rides/${rideId}/`));
  };

  const getActiveRide = async () => {
    return request<any>(() => get("/rides/active/"));
  };

  const acceptRide = async (rideId: string) => {
    return request<any>(() => post(`/rides/${rideId}/accept/`, {}));
  };

  const cancelRide = async (rideId: string, reason = "") => {
    return request<any>(() => post(`/rides/${rideId}/cancel/`, { reason }));
  };

  const updateRideStatus = async (rideId: string, status: string, finalFare?: string | number) => {
    const payload: Record<string, any> = { status };
    if (finalFare !== undefined && finalFare !== null && finalFare !== "") {
      payload.final_fare = finalFare;
    }
    return request<any>(() => post(`/rides/${rideId}/status/`, payload));
  };

  const searchLocations = async (query: string, limit = 5) => {
    return request<any[]>(() => get("/rides/location/search/", { params: { q: query, limit } }));
  };

  const reverseGeocode = async (latitude: number, longitude: number) => {
    return request<any>(() => get("/rides/location/reverse/", { params: { lat: latitude, lng: longitude } }));
  };

  const getNearbyDrivers = async (latitude: number, longitude: number, vehicleType = "bike") => {
    return request<any[]>(() => get("/rides/location/nearby-drivers/", {
      params: {
        lat: latitude,
        lng: longitude,
        vehicle_type: vehicleType,
      },
    }));
  };

  const getDriverProfile = async () => {
    return request<any>(() => get("/rides/drivers/profile/"));
  };

  const updateDriverProfile = async (payload: Record<string, any>) => {
    return request<any>(() => put("/rides/drivers/profile/", payload));
  };

  const toggleDriverOnline = async (isOnline: boolean) => {
    return request<any>(() => post("/rides/drivers/toggle-online/", { is_online: isOnline }));
  };

  const updateDriverLocation = async (payload: Record<string, any>) => {
    return request<any>(() => post("/rides/drivers/location/update/", payload));
  };

  const getDriverEarningsSummary = async () => {
    return request<any>(() => get("/rides/drivers/earnings-summary/"));
  };

  const listVehicles = async () => {
    return request<any[]>(() => get("/rides/drivers/vehicles/"));
  };

  const createVehicle = async (payload: Record<string, any>) => {
    return request<any>(() => post("/rides/drivers/vehicles/", payload));
  };

  const updateVehicle = async (vehicleId: string, payload: Record<string, any>) => {
    return request<any>(() => patch(`/rides/drivers/vehicles/${vehicleId}/`, payload));
  };

  const deleteVehicle = async (vehicleId: string) => {
    return request<any>(() => del(`/rides/drivers/vehicles/${vehicleId}/`));
  };

  const listAvailableRideRequests = async () => {
    return request<any[]>(() => get("/rides/driver/available/"));
  };

  return {
    normalizePoint,
    estimateRide,
    createRide,
    listRides,
    getRide,
    getActiveRide,
    acceptRide,
    cancelRide,
    updateRideStatus,
    searchLocations,
    reverseGeocode,
    getNearbyDrivers,
    getDriverProfile,
    updateDriverProfile,
    toggleDriverOnline,
    updateDriverLocation,
    getDriverEarningsSummary,
    listVehicles,
    createVehicle,
    updateVehicle,
    deleteVehicle,
    listAvailableRideRequests,
  };
}
