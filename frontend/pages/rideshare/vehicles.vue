<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-8 bg-gradient-to-b from-gray-50 to-gray-100">
      <UContainer class="max-w-7xl">
        <div class="mb-6">
          <h1 class="text-2xl font-semibold text-gray-900">Vehicle Management</h1>
          <p class="text-sm text-gray-600 mt-2">Add and manage driver vehicles before going online.</p>
        </div>

        <div class="mb-6">
          <RideshareNav current="vehicles" />
        </div>

        <div v-if="pageError" class="mb-6 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-5 gap-6">
          <div class="xl:col-span-2">
            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100">
                <h2 class="text-lg font-semibold text-gray-900">{{ editingVehicleId ? 'Edit Vehicle' : 'Add Vehicle' }}</h2>
                <p class="text-sm text-gray-500 mt-1">Keep one active default vehicle for dispatch matching.</p>
              </div>

              <form class="p-5 space-y-4" @submit.prevent="submitVehicle">
                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Vehicle Type</label>
                    <USelect v-model="vehicleForm.vehicle_type" :options="vehicleTypeOptions" option-attribute="label" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Seat Capacity</label>
                    <UInput v-model="vehicleForm.seat_capacity" type="number" min="1" />
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Brand</label>
                    <UInput v-model="vehicleForm.brand" placeholder="Honda, Toyota..." />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Model</label>
                    <UInput v-model="vehicleForm.model_name" placeholder="Model name" />
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Color</label>
                    <UInput v-model="vehicleForm.color" placeholder="Vehicle color" />
                  </div>
                  <div>
                    <label class="block text-sm font-medium text-gray-800 mb-2">Registration Number</label>
                    <UInput v-model="vehicleForm.registration_number" placeholder="Registration number" />
                  </div>
                </div>

                <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <label class="flex items-center gap-3 rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-700">
                    <UCheckbox v-model="vehicleForm.is_active" />
                    <span>Active for booking</span>
                  </label>
                  <label class="flex items-center gap-3 rounded-xl border border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-700">
                    <UCheckbox v-model="vehicleForm.is_default" />
                    <span>Set as default</span>
                  </label>
                </div>

                <div class="flex gap-3">
                  <UButton color="emerald" :loading="savingVehicle" type="submit">
                    {{ editingVehicleId ? 'Update Vehicle' : 'Save Vehicle' }}
                  </UButton>
                  <UButton v-if="editingVehicleId" color="gray" variant="soft" @click="resetForm">
                    Cancel
                  </UButton>
                </div>
              </form>
            </div>
          </div>

          <div class="xl:col-span-3">
            <div class="bg-white border border-gray-200 rounded-xl shadow-sm overflow-hidden">
              <div class="px-5 py-4 border-b border-gray-100 flex items-center justify-between gap-4">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900">Your Vehicles</h2>
                  <p class="text-sm text-gray-500 mt-1">Manage active and default vehicle selection.</p>
                </div>
                <UBadge :color="vehicles.length ? 'emerald' : 'gray'" variant="soft">
                  {{ vehicles.length }} vehicle{{ vehicles.length === 1 ? '' : 's' }}
                </UBadge>
              </div>

              <div v-if="loadingVehicles" class="p-6 space-y-3">
                <div v-for="index in 3" :key="index" class="h-20 rounded-xl bg-gray-100 animate-pulse"></div>
              </div>

              <div v-else-if="!vehicles.length" class="p-6">
                <div class="rounded-xl border border-dashed border-gray-200 bg-gray-50 px-4 py-8 text-center text-sm text-gray-500">
                  No vehicles added yet. Add your first vehicle to prepare for driver dispatch.
                </div>
              </div>

              <div v-else class="p-5 space-y-4">
                <div
                  v-for="vehicle in vehicles"
                  :key="vehicle.id"
                  class="rounded-xl border px-4 py-4"
                  :class="vehicle.is_default ? 'border-emerald-200 bg-emerald-50/60' : 'border-gray-200 bg-white'"
                >
                  <div class="flex flex-col md:flex-row md:items-start md:justify-between gap-4">
                    <div class="space-y-2">
                      <div class="flex items-center flex-wrap gap-2">
                        <h3 class="text-base font-semibold text-gray-900">
                          {{ vehicle.brand || 'Vehicle' }} {{ vehicle.model_name || '' }}
                        </h3>
                        <UBadge :color="vehicle.is_active ? 'emerald' : 'gray'" variant="soft">
                          {{ vehicle.is_active ? 'Active' : 'Inactive' }}
                        </UBadge>
                        <UBadge v-if="vehicle.is_default" color="blue" variant="soft">Default</UBadge>
                      </div>
                      <div class="text-sm text-gray-600">{{ vehicle.registration_number }}</div>
                      <div class="grid grid-cols-2 md:grid-cols-4 gap-3 text-sm">
                        <div>
                          <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Type</div>
                          <div class="mt-1 text-gray-900">{{ vehicle.vehicle_type }}</div>
                        </div>
                        <div>
                          <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Seats</div>
                          <div class="mt-1 text-gray-900">{{ vehicle.seat_capacity }}</div>
                        </div>
                        <div>
                          <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Color</div>
                          <div class="mt-1 text-gray-900">{{ vehicle.color || 'N/A' }}</div>
                        </div>
                        <div>
                          <div class="text-xs uppercase tracking-wide text-gray-500 font-semibold">Updated</div>
                          <div class="mt-1 text-gray-900">{{ formatDate(vehicle.updated_at) }}</div>
                        </div>
                      </div>
                    </div>

                    <div class="flex gap-2">
                      <UButton color="gray" variant="soft" @click="editVehicle(vehicle)">Edit</UButton>
                      <UButton color="red" variant="soft" :loading="deletingVehicleId === vehicle.id" @click="removeVehicle(vehicle)">
                        Delete
                      </UButton>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </UContainer>
    </div>
  </PublicSection>
</template>

<script setup>
definePageMeta({
  layout: "dashboard",
});

const toast = useToast();
const {
  listVehicles,
  createVehicle,
  updateVehicle,
  deleteVehicle,
} = useRideshare();

const loadingVehicles = ref(true);
const savingVehicle = ref(false);
const deletingVehicleId = ref(null);
const editingVehicleId = ref("");
const pageError = ref("");
const vehicles = ref([]);

const vehicleTypeOptions = [
  { label: "Bike", value: "bike" },
  { label: "Car", value: "car" },
  { label: "CNG", value: "cng" },
];

const createDefaultForm = () => ({
  vehicle_type: "bike",
  brand: "",
  model_name: "",
  color: "",
  registration_number: "",
  seat_capacity: 1,
  is_active: true,
  is_default: false,
});

const vehicleForm = ref(createDefaultForm());

const formatDate = (value) => {
  return new Date(value).toLocaleDateString(undefined, {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
};

const resetForm = () => {
  editingVehicleId.value = "";
  vehicleForm.value = createDefaultForm();
};

const loadVehicles = async () => {
  loadingVehicles.value = true;
  pageError.value = "";
  const result = await listVehicles();
  if (result.success) {
    vehicles.value = result.data || [];
  } else {
    pageError.value = result.message;
  }
  loadingVehicles.value = false;
};

const submitVehicle = async () => {
  savingVehicle.value = true;
  pageError.value = "";

  const payload = {
    ...vehicleForm.value,
    seat_capacity: Number(vehicleForm.value.seat_capacity || 1),
    vehicle_type: vehicleForm.value.vehicle_type?.value || vehicleForm.value.vehicle_type,
  };

  const result = editingVehicleId.value
    ? await updateVehicle(editingVehicleId.value, payload)
    : await createVehicle(payload);

  if (result.success) {
    toast.add({
      title: editingVehicleId.value ? "Vehicle updated" : "Vehicle added",
      description: result.message,
      color: "green",
    });
    resetForm();
    await loadVehicles();
  } else {
    pageError.value = result.message;
    toast.add({ title: "Vehicle save failed", description: result.message, color: "red" });
  }

  savingVehicle.value = false;
};

const editVehicle = (vehicle) => {
  editingVehicleId.value = vehicle.id;
  vehicleForm.value = {
    vehicle_type: vehicle.vehicle_type,
    brand: vehicle.brand || "",
    model_name: vehicle.model_name || "",
    color: vehicle.color || "",
    registration_number: vehicle.registration_number || "",
    seat_capacity: vehicle.seat_capacity || 1,
    is_active: Boolean(vehicle.is_active),
    is_default: Boolean(vehicle.is_default),
  };
};

const removeVehicle = async (vehicle) => {
  if (!confirm(`Delete ${vehicle.registration_number}?`)) {
    return;
  }

  deletingVehicleId.value = vehicle.id;
  const result = await deleteVehicle(vehicle.id);
  if (result.success) {
    toast.add({ title: "Vehicle deleted", description: result.message, color: "green" });
    if (editingVehicleId.value === vehicle.id) {
      resetForm();
    }
    await loadVehicles();
  } else {
    toast.add({ title: "Delete failed", description: result.message, color: "red" });
  }
  deletingVehicleId.value = null;
};

onMounted(() => {
  loadVehicles();
});
</script>
