<template>
  <div>
    <!-- <form
      @submit.prevent="handleSubmit"
      class="bg-white rounded-xl md:px-8 pt-6 pb-6 md:pb-8 mb-4 px-2 sm:px-8"
    >
      <h1 class="font-bold text-center mb-4 text-2xl">REGISTER</h1>
      <UDivider label="" />
      <div class="my-4">
        <label class="block text-gray-700 text-md font-medium mb-2" for="email">
          Email
        </label>
        <input
          v-model="email"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="email"
          type="email"
          placeholder="Email"
        />
        <p
          v-if="error.email"
          class="text-red-500 text-sm first-letter:uppercase"
        >
          {{ error.email[0] }}
        </p>
      </div>
      <div class="mb-4">
        <label class="block text-gray-700 text-md font-medium mb-2" for="phone">
          Phone
        </label>
        <div class="flex">
          <div>
            <UButton
              size="md"
              variant="solid"
              disabled
              label="+88"
              :ui="{
                rounded: 'rounded-s-md rounded-e-none',
                size: {
                  lg: 'text-base',
                },
              }"
            />
          </div>
          <input
            v-model="phone"
            class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md rounded-s-none"
            id="phone"
            type="phone"
            placeholder="017XXXXXXXX"
          />
        </div>
        <p
          v-if="error.phone"
          class="text-red-500 text-sm first-letter:uppercase"
        >
          {{ error.phone[0] }}
        </p>
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          Password
        </label>
        <input
          v-model="password"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="password"
          type="password"
          placeholder="********"
        />
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="confirm-password"
        >
          Confirm Password
        </label>
        <input
          v-model="confirmPassword"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md mb-3"
          id="confirm-password"
          type="password"
          placeholder="********"
        />
        <p v-if="passwordMismatch" class="text-red-500 text-sm">
          Passwords do not match
        </p>
      </div>
      <div class="mb-4">
        <label
          class="block text-gray-700 text-md font-medium mb-2"
          for="password"
        >
          Referral Code
        </label>
        <input
          v-model="refer"
          class="w-full py-1.5 px-3 text-sm text-gray-700 bg-[#D9D9D9] rounded-md"
          id="password"
          type="text"
          placeholder="********"
          readonly
        />
        <p v-if="inValidRefer" class="text-red-500 text-sm">
          Refer Code Is Invalid
        </p>
      </div>
      <div class="text-center !mt-8">
        <button
          class="bg-orange-500 py-1 text-base text-white px-6 capitalize rounded-md"
        >
          Register
        </button>
      </div>
    </form> -->
    <div class="bg-white rounded-2xl shadow-sm p-4 sm:p-8">
      <transition name="fade" mode="out-in">
        <form @submit.prevent="handleSubmit" class="space-y-6">
          <div class="space-y-2">
            <h2 class="text-2xl font-semibold text-gray-900">Create account</h2>
            <p class="text-gray-600">Enter your details to register</p>
          </div>

          <div class="space-y-4">
            <div class="grid grid-cols-2 gap-4">
              <div>
                <input
                  type="text"
                  placeholder="First name"
                  v-model="form.first_name"
                  class="px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                />
                <p v-if="error.first_name" class="text-red-500 text-sm">
                  {{ error.first_name }}
                </p>
              </div>
              <div>
                <input
                  type="text"
                  placeholder="Last name"
                  v-model="form.last_name"
                  class="px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400"
                />
                <p v-if="error.last_name" class="text-red-500 text-sm">
                  {{ error.last_name }}
                </p>
              </div>
            </div>

            <div>
              <input
                type="email"
                placeholder="Email address"
                v-model="form.email"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              />
              <p v-if="error.email" class="text-red-500 text-sm">
                {{ error.email }}
              </p>
            </div>

            <div>
              <input
                type="text"
                placeholder="Phone number"
                v-model="form.phone"
                class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
              />
              <p v-if="error.phone" class="text-red-500 text-sm">
                {{ error.phone }}
              </p>
            </div>
            <div>
              <div class="relative">
                <input
                  :type="isPassword ? 'password' : 'text'"
                  placeholder="Password"
                  v-model="form.password"
                  class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
                />
                <div
                  class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                  @click="isPassword = !isPassword"
                >
                  <UIcon
                    name="i-heroicons-solid-eye"
                    class="w-5 h-5 text-gray-400"
                    v-if="isPassword"
                  />
                  <UIcon
                    name="i-heroicons-solid-eye-off"
                    class="w-5 h-5 text-gray-400"
                    v-else
                  />
                </div>
              </div>

              <p v-if="error.password" class="text-red-500 text-sm">
                {{ error.password }}
              </p>
            </div>
            <div>
              <div class="relative">
                <input
                  :type="isPassword ? 'password' : 'text'"
                  placeholder="Confirm password"
                  v-model="form.confirmPassword"
                  class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
                />
                <!-- <div
                  class="absolute inset-y-0 right-0 flex items-center pr-3 cursor-pointer"
                  @click="isPassword = !isPassword"
                >
                  <UIcon
                    name="i-heroicons-solid-eye"
                    class="w-5 h-5 text-gray-400"
                    v-if="isPassword"
                  />
                  <UIcon
                    name="i-heroicons-solid-eye-off"
                    class="w-5 h-5 text-gray-400"
                    v-else
                  />
                </div> -->
              </div>

              <p v-if="error.confirmPassword" class="text-red-500 text-sm">
                {{ error.confirmPassword }}
              </p>
            </div>
            <!-- <div class="col-span-2">
              <label for="file" class="text-base block mb-3 font-semibold"
                >Profile Image</label
              >
              <div class="flex flex-wrap gap-5">
                <div
                  class="relative max-w-[200px] max-h-[200px]"
                  v-if="userProfile.image"
                >
                  <img
                    :src="userProfile.image"
                    :alt="`Uploaded profile image`"
                    class="rounded-full size-[100px] object-cover"
                  />
                  <div
                    class="absolute top-2 right-2 rounded-sm bg-white cursor-pointer"
                    @click="deleteUpload(i)"
                  >
                    <UIcon
                      name="i-heroicons-trash-solid"
                      class="text-red-500"
                    />
                  </div>
                </div>

                <div
                  class="w-full h-full flex items-center justify-center max-w-[200px] max-h-[200px] relative pt-7"
                >
                  <input
                    type="file"
                    name=""
                    id=""
                    class="h-full w-full absolute left-0 top-0 z-10 cursor-pointer opacity-0"
                    @change="handleFileUpload($event, 'image')"
                  />
                  <UIcon
                  name="i-material-symbols:drive-folder-upload-outline"
                  size="66"
                />
                  <UInput
                    type="file"
                    size="xs"
                    class="pointer-events-none"
                    icon="i-heroicons-folder"
                  />
                </div>
              </div>
            </div> -->
            <div class="grid gap-4">
              <div class="col-span-2 md:col-auto">
                <UFormGroup
                  label=""
                  :ui="{
                    label: {
                      base: 'block font-medium text-gray-700 dark:text-slate-700',
                    },
                  }"
                >
                  <UInput
                    type="text"
                    size="md"
                    color="white"
                    placeholder="City"
                    v-model="form.city"
                    :ui="{
                      placeholder:
                        'placeholder-gray-400 dark:placeholder-gray-200',
                    }"
                  />
                </UFormGroup>
              </div>
              <div class="col-span-2 md:col-auto">
                <UFormGroup
                  label=""
                  :ui="{
                    label: {
                      base: 'block font-medium text-gray-700 dark:text-slate-700',
                    },
                  }"
                >
                  <UInput
                    type="text"
                    size="md"
                    color="white"
                    placeholder="State"
                    v-model="form.state"
                    :ui="{
                      placeholder:
                        'placeholder-gray-400 dark:placeholder-gray-200',
                    }"
                  />
                </UFormGroup>
              </div>
              <div class="col-span-2 md:col-auto">
                <UFormGroup
                  label=""
                  :ui="{
                    label: {
                      base: 'block font-medium text-gray-700 dark:text-slate-700',
                    },
                  }"
                >
                  <UInput
                    type="text"
                    size="md"
                    color="white"
                    placeholder="Zip"
                    v-model="form.zip"
                    :ui="{
                      placeholder:
                        'placeholder-gray-400 dark:placeholder-gray-200',
                    }"
                  />
                </UFormGroup>
              </div>
              <div class="col-span-2">
                <UFormGroup
                  label=""
                  :ui="{
                    label: {
                      base: 'block font-medium text-gray-700 dark:text-slate-700',
                    },
                  }"
                >
                  <UInput
                    color="white"
                    variant="outline"
                    class="w-full"
                    resize
                    placeholder="Address"
                    v-model="form.address"
                    :ui="{
                      placeholder:
                        'placeholder-gray-400 dark:placeholder-gray-200',
                    }"
                  />
                </UFormGroup>
              </div>
            </div>
            <input
              type="text"
              placeholder="Referral code (optional)"
              v-model="form.refer"
              class="w-full px-3 py-2 border border-gray-200 rounded-lg focus:outline-none focus:border-gray-400 text-base md:text-sm"
            />
            <p v-if="submitError" class="text-red-500 text-sm">
              {{ submitError }}
            </p>
          </div>

          <UButton
            :loading="isLoading"
            type="submit"
            class="w-full py-3 font-semibold text-sm px-4 bg-gray-900 text-white rounded-lg hover:bg-gray-800 transition-colors justify-center"
          >
            Create account
          </UButton>

          <div class="text-center">
            <NuxtLink
              to="/auth/login/"
              class="text-purple-600 hover:text-purple-500 text-sm font-semibold"
            >
              Already have an account? Sign in
            </NuxtLink>
          </div>
        </form>
      </transition>
    </div>
  </div>
</template>

<script setup>
const Api = useApi();
const { login } = useAuth();
const isPassword = ref(true);
const isLoading = ref(false);

const form = ref({
  first_name: "",
  last_name: "",
  email: "",
  phone: "",
  password: "",
  confirmPassword: "",
  refer: "",
});

const userProfile = ref({});

const error = ref("");
const submitError = ref("");

const route = useRoute();
if (route.query.ref) {
  form.value.refer = route.query.ref;
}

const toast = useToast();

// Handle form submission
async function handleSubmit() {
  isLoading.value = true;

  // Reset errors
  error.value = {
    first_name: "",
    last_name: "",
    email: "",
    phone: "",
    password: "",
    confirmPassword: "",
  };

  // Validate fields
  if (!form.value.first_name) error.value.first_name = "First name is required";
  if (!form.value.last_name) error.value.last_name = "Last name is required";
  if (!form.value.email) error.value.email = "Email is required";
  if (!form.value.phone) error.value.phone = "Phone number is required";
  if (!form.value.password) error.value.password = "Password is required";
  if (!form.value.confirmPassword)
    error.value.confirmPassword = "Confirm password is required";
  if (form.value.password !== form.value.confirmPassword) {
    error.value.confirmPassword = "Passwords do not match";
  }

  // If any error exists, stop submission
  if (Object.values(error.value).some((err) => err)) {
    isLoading.value = false;
    return;
  }

  const formData = {
    first_name: form.value.first_name,
    last_name: form.value.last_name,
    name: form.value.first_name + " " + form.value.last_name,
    email: form.value.email,
    password: form.value.password,
    username: form.value.email,
    phone: form.value.phone,
    refer: form.value.refer,
    // image: userProfile.value.image,
    city: form.value.city,
    state: form.value.state,
    zip: form.value.zip,
    address: form.value.address,
  };

  try {
    const res = await Api.post("/auth/register/", formData);
    console.log(res);

    if (res?.data?.message) {
      error.value = "";
      const res2 = await login(form.value.email, form.value.password);
      if (res2) {
        const res = await Api.post(`/send-sms/?phone=${form.value.phone}`);
        toast.add({ title: "Login successful!" });
        navigateTo("/");
      }
    } else {
      submitError.value = res.error.data.error || "An error occurred";
    }
  } catch (err) {
    if (err.response?.status === 444) {
      error.value.refer = "Invalid referral code";
    } else {
      console.error("Error submitting the form:", err);
    }
  }
  isLoading.value = false;
}

function handleFileUpload(event, field) {
  const files = Array.from(event.target.files);
  const reader = new FileReader();

  // Event listener for successful read
  reader.onload = () => {
    userProfile.value.image = reader.result;
  };

  // Event listener for errors
  reader.onerror = (error) => reject(error);

  // Read the file as a data URL (Base64 string)
  reader.readAsDataURL(files[0]);
}

function deleteUpload(ind) {
  userProfile.value.image = null;
}
</script>
