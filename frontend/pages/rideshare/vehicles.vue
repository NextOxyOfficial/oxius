<template>
  <PublicSection>
    <div class="min-h-screen py-4 sm:py-6 bg-gradient-to-br from-slate-50 via-white to-indigo-50/30">
      <UContainer class="max-w-7xl space-y-5">
        <!-- Header -->
        <div class="relative z-50 flex items-center justify-between gap-3 rounded-xl border border-slate-200/80 bg-white px-4 py-3 shadow-xs">
          <div class="flex items-center gap-3">
            <div class="flex h-10 w-10 items-center justify-center rounded-lg bg-gradient-to-br from-indigo-500 to-violet-600 text-white">
              <UIcon name="i-heroicons-truck" class="h-5 w-5" />
            </div>
            <div>
              <h1 class="text-base font-bold text-slate-800">Vehicles</h1>
              <p class="text-[10px] text-slate-500">Add and manage your vehicles</p>
            </div>
          </div>
          <RideshareModeSwitch />
        </div>

        <RideshareNav current="vehicles" />

        <div v-if="pageError" class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div class="grid grid-cols-1 xl:grid-cols-5 gap-4">
          <div class="xl:col-span-2">
            <div class="bg-white/80 backdrop-blur-sm border border-slate-200/80 rounded-xl shadow-sm overflow-hidden">
              <div class="px-4 py-3 border-b border-slate-100 bg-slate-50/50">
                <h2 class="text-sm font-bold text-slate-800">{{ editingVehicleId ? 'Edit Vehicle' : 'Add Vehicle' }}</h2>
                <p class="text-[11px] text-slate-500 mt-0.5">Keep one active default vehicle for dispatch.</p>
              </div>

              <form class="p-4 space-y-3" @submit.prevent="submitVehicle">
                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Vehicle Type</label>
                    <USelect v-model="vehicleForm.vehicle_type" :options="vehicleTypeOptions" option-attribute="label" size="sm" />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Seat Capacity</label>
                    <UInput v-model="vehicleForm.seat_capacity" type="number" min="1" size="sm" />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Brand</label>
                    <UInput v-model="vehicleForm.brand" placeholder="Honda, Toyota..." size="sm" />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Model</label>
                    <UInput v-model="vehicleForm.model_name" placeholder="Model name" size="sm" />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                  <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Color</label>
                    <UInput v-model="vehicleForm.color" placeholder="Vehicle color" size="sm" />
                  </div>
                  <div>
                    <label class="block text-xs font-medium text-slate-700 mb-1.5">Registration</label>
                    <UInput v-model="vehicleForm.registration_number" placeholder="Reg number" size="sm" />
                  </div>
                </div>

                <div class="grid grid-cols-2 gap-3">
                  <label class="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-700">
                    <UCheckbox v-model="vehicleForm.is_active" />
                    <span>Active</span>
                  </label>
                  <label class="flex items-center gap-2 rounded-lg border border-slate-200 bg-slate-50 px-3 py-2 text-xs text-slate-700">
                    <UCheckbox v-model="vehicleForm.is_default" />
                    <span>Default</span>
                  </label>
                </div>

                <div class="flex gap-2 pt-1">
                  <button
                    type="submit"
                    class="flex-1 inline-flex items-center justify-center gap-1.5 rounded-lg bg-gradient-to-r from-indigo-500 to-violet-600 px-3 py-2 text-xs font-semibold text-white shadow-sm transition-all hover:from-indigo-600 hover:to-violet-700 disabled:opacity-50"
                    :disabled="savingVehicle"
                  >
                    <span v-if="savingVehicle" class="h-3 w-3 animate-spin rounded-full border-2 border-white border-t-transparent"></span>
                    {{ editingVehicleId ? 'Update' : 'Save Vehicle' }}
                  </button>
                  <button v-if="editingVehicleId" type="button" class="rounded-lg bg-slate-100 px-3 py-2 text-xs font-medium text-slate-600 hover:bg-slate-200" @click="resetForm">
                    Cancel
                  </button>
                </div>
              </form>
            </div>
          </div>

          <div class="xl:col-span-3">
            <div class="bg-white/80 backdrop-blur-sm border border-slate-200/80 rounded-xl shadow-sm overflow-hidden">
              <div class="px-4 py-3 border-b border-slate-100 bg-slate-50/50 flex items-center justify-between gap-3">
                <div>
                  <h2 class="text-sm font-bold text-slate-800">Your Vehicles</h2>
                  <p class="text-[11px] text-slate-500 mt-0.5">Manage active and default selection.</p>
                </div>
                <span class="rounded-full px-2 py-0.5 text-[10px] font-semibold" :class="vehicles.length ? 'bg-indigo-100 text-indigo-700' : 'bg-slate-100 text-slate-500'">
                  {{ vehicles.length }} vehicle{{ vehicles.length === 1 ? '' : 's' }}
                </span>
              </div>

              <div v-if="loadingVehicles" class="p-4 space-y-2">
                <div v-for="index in 3" :key="index" class="h-16 rounded-lg bg-slate-100 animate-pulse"></div>
              </div>

              <div v-else-if="!vehicles.length" class="p-4">
                <div class="rounded-lg border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center">
                  <div class="flex h-10 w-10 mx-auto items-center justify-center rounded-lg bg-slate-100 text-slate-400 mb-2">
                    <UIcon name="i-heroicons-truck" class="h-5 w-5" />
                  </div>
                  <div class="text-xs font-medium text-slate-600">No vehicles added yet</div>
                  <div class="text-[11px] text-slate-400 mt-0.5">Add your first vehicle to start.</div>
                </div>
              </div>

              <div v-else class="p-3 space-y-2">
                <div
                  v-for="vehicle in vehicles"
                  :key="vehicle.id"
                  class="rounded-lg border px-3 py-3"
                  :class="vehicle.is_default ? 'border-indigo-200 bg-indigo-50/50' : 'border-slate-200 bg-white'"
                >
                  <div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div class="space-y-1.5 min-w-0 flex-1">
                      <div class="flex items-center flex-wrap gap-1.5">
                        <h3 class="text-xs font-semibold text-slate-800">
                          {{ vehicle.brand || 'Vehicle' }} {{ vehicle.model_name || '' }}
                        </h3>
                        <span class="rounded-full px-1.5 py-0.5 text-[9px] font-semibold" :class="vehicle.is_active ? 'bg-emerald-100 text-emerald-700' : 'bg-slate-100 text-slate-500'">
                          {{ vehicle.is_active ? 'Active' : 'Inactive' }}
                        </span>
                        <span v-if="vehicle.is_default" class="rounded-full bg-indigo-100 text-indigo-700 px-1.5 py-0.5 text-[9px] font-semibold">Default</span>
                      </div>
                      <div class="text-[11px] text-slate-500">{{ vehicle.registration_number }}</div>
                      <div class="grid grid-cols-4 gap-2 text-[10px]">
                        <div class="rounded bg-slate-50 px-2 py-1">
                          <div class="text-slate-400 font-medium">Type</div>
                          <div class="text-slate-700 font-semibold capitalize">{{ vehicle.vehicle_type }}</div>
                        </div>
                        <div class="rounded bg-slate-50 px-2 py-1">
                          <div class="text-slate-400 font-medium">Seats</div>
                          <div class="text-slate-700 font-semibold">{{ vehicle.seat_capacity }}</div>
                        </div>
                        <div class="rounded bg-slate-50 px-2 py-1">
                          <div class="text-slate-400 font-medium">Color</div>
                          <div class="text-slate-700 font-semibold">{{ vehicle.color || 'N/A' }}</div>
                        </div>
                        <div class="rounded bg-slate-50 px-2 py-1">
                          <div class="text-slate-400 font-medium">Updated</div>
                          <div class="text-slate-700 font-semibold">{{ formatDate(vehicle.updated_at) }}</div>
                        </div>
                      </div>
                    </div>

                    <div class="flex gap-1.5 flex-shrink-0">
                      <button type="button" class="rounded-lg bg-slate-100 px-2.5 py-1.5 text-[10px] font-medium text-slate-600 hover:bg-slate-200" @click="editVehicle(vehicle)">Edit</button>
                      <button type="button" class="rounded-lg bg-red-50 px-2.5 py-1.5 text-[10px] font-medium text-red-600 hover:bg-red-100" :disabled="deletingVehicleId === vehicle.id" @click="removeVehicle(vehicle)">
                        {{ deletingVehicleId === vehicle.id ? '...' : 'Delete' }}
                      </button>
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
      color: "gray",
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
    toast.add({ title: "Vehicle deleted", description: result.message, color: "gray" });
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
