import { useState, useEffect, useMemo } from 'react';
import { useApi } from './useApi';

// Define types for operators and packages
interface Operator {
  id: number;
  name: string;
}

interface Package {
  id: number;
  price: string;
  type: string;
  popular: boolean;
}

export function useMobileRecharge() {
  const { get, post } = useApi();

  const [operators, setOperators] = useState<Operator[]>([]);
  const [packages, setPackages] = useState<Package[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState<string>("");
  const [activeFilter, setActiveFilter] = useState<string>("all");
  const [selectedOperator, setSelectedOperator] = useState<number | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Fetch all operators
  async function fetchOperators() {
    setIsLoading(true);
    setError(null);

    try {
      const response = await get<{ data: Operator[] } | null>("/mobile-recharge/operators/");
      if (response && response.data) {
        setOperators(response.data); // Use response.data directly as an array
        if (response.data.length > 0) {
          setSelectedOperator(response.data[0].id);
        }
      } else {
        setError("Failed to load operators");
      }
    } catch (err) {
      setError("Failed to load operators");
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  }

  // Fetch packages with filters
  async function fetchPackages() {
    setIsLoading(true);
    setError(null);

    try {
      let url = "/mobile-recharge/packages/?";

      if (selectedOperator) {
        url += `operator=${selectedOperator}&`;
      }

      if (activeFilter !== "all") {
        url += `type=${activeFilter}&`;
      }

      if (searchQuery) {
        url += `search=${encodeURIComponent(searchQuery)}&`;
      }

      const response = await get<{ data: Package[] } | null>(url);
      if (response && response.data) {
        setPackages(response.data); // Use response.data directly as an array
      } else {
        setError("Failed to load packages");
      }
    } catch (err) {
      setError("Failed to load packages");
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  }

  // Process recharge
  async function processRecharge(packageId: number, phoneNumber: string) {
    setIsLoading(true);
    setError(null);

    try {
      const selectedPackage = packages.find((p) => p.id === packageId);

      if (!selectedPackage) {
        throw new Error("Package not found");
      }

      const response = await post("/mobile-recharge/recharges/", {
        package: packageId,
        phone_number: phoneNumber,
        amount: parseFloat(selectedPackage.price.replace("$", "")),
      });

      return response.data;
    } catch (err: any) {
      const errorMsg = err.response?.data?.message || "Failed to process recharge";
      setError(errorMsg);
      console.error(err);
      throw errorMsg;
    } finally {
      setIsLoading(false);
    }
  }

  // Computed properties as useMemo
  const popularPackages = useMemo(() => {
    return packages.filter((pack) => pack.popular);
  }, [packages]);

  const filteredPackages = useMemo(() => {
    return packages.filter((pack) => {
      // Type filter is handled by API, this is just for client-side updates
      return activeFilter === "all" || pack.type === activeFilter;
    });
  }, [packages, activeFilter]);

  // Watch for filter changes with useEffect
  useEffect(() => {
    fetchPackages();
  }, [selectedOperator, activeFilter, searchQuery]);

  return {
    operators,
    packages,
    popularPackages,
    filteredPackages,
    isLoading,
    error,
    searchQuery,
    setSearchQuery,
    activeFilter,
    setActiveFilter,
    selectedOperator,
    setSelectedOperator,
    fetchOperators,
    fetchPackages,
    processRecharge,
  };
}