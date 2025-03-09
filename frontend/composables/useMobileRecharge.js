import { useApi } from "~/composables/useApi";

export function useMobileRecharge() {
  const { get, post } = useApi();

  const operators = ref([]);
  const packages = ref([]);
  const isLoading = ref(false);
  const searchQuery = ref("");
  const activeFilter = ref("all");
  const selectedOperator = ref(null);
  const error = ref(null);

  // Fetch all operators
  async function fetchOperators() {
    isLoading.value = true;
    error.value = null;

    try {
      const response = await get("/mobile-recharge/operators/");
      operators.value = response.data;
      if (operators.value.length > 0) {
        selectedOperator.value = operators.value[0].id;
      }
    } catch (err) {
      error.value = "Failed to load operators";
      console.error(err);
    } finally {
      isLoading.value = false;
    }
  }

  // Fetch packages with filters
  async function fetchPackages() {
    isLoading.value = true;
    error.value = null;

    try {
      let url = "/mobile-recharge/packages/?";

      if (selectedOperator.value) {
        url += `operator=${selectedOperator.value}&`;
      }

      if (activeFilter.value !== "all") {
        url += `type=${activeFilter.value}&`;
      }

      if (searchQuery.value) {
        url += `search=${encodeURIComponent(searchQuery.value)}&`;
      }

      const response = await get(url);
      packages.value = response.data;
    } catch (err) {
      error.value = "Failed to load packages";
      console.error(err);
    } finally {
      isLoading.value = false;
    }
  }

  // Process recharge
  async function processRecharge(packageId, phoneNumber) {
    isLoading.value = true;
    error.value = null;

    try {
      const selectedPackage = packages.value.find((p) => p.id === packageId);

      if (!selectedPackage) {
        throw new Error("Package not found");
      }

      const response = await post("/mobile-recharge/recharges/", {
        package: packageId,
        phone_number: phoneNumber,
        amount: parseFloat(selectedPackage.price.replace("$", "")),
      });

      return response.data;
    } catch (err) {
      error.value = err.response?.data?.message || "Failed to process recharge";
      console.error(err);
      throw error.value;
    } finally {
      isLoading.value = false;
    }
  }

  // Computed properties
  const popularPackages = computed(() => {
    return packages.value.filter((pack) => pack.popular);
  });

  const filteredPackages = computed(() => {
    return packages.value.filter((pack) => {
      // Type filter is handled by API, this is just for client-side updates
      return activeFilter.value === "all" || pack.type === activeFilter.value;
    });
  });

  // Watch for filter changes
  watch([selectedOperator, activeFilter, searchQuery], fetchPackages);

  return {
    operators,
    packages,
    popularPackages,
    filteredPackages,
    isLoading,
    error,
    searchQuery,
    activeFilter,
    selectedOperator,
    fetchOperators,
    fetchPackages,
    processRecharge,
  };
}
