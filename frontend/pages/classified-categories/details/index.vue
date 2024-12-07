<template>
  <UContainer class="mb-16">
    <div class="mx-auto">
      <div class="flex items-center justify-between">
        <p class="mb-3 mt-16">
          <ULink
            to="/"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            >Home</ULink
          >
          >
          <ULink
            to="/classified-categories"
            active-class="text-primary"
            inactive-class="text-gray-500 dark:text-gray-400"
            >Category Name</ULink
          >
          > Details
        </p>

        <UButton label="Go Back" color="gray" class="self-end">
          <template #trailing>
            <UIcon name="i-heroicons-arrow-left-20-solid" class="w-5 h-5" />
          </template>
        </UButton>
      </div>

      <div class="w-full flex flex-col justify-center">
        <h2 class="text-3xl font-bold">Service Title</h2>
        <NuxtImg
          src="/placeholder.jpg"
          class="max-w-[60%] w-full rounded-md self-center my-10"
        />

        <p class="">
          Lorem ipsum dolor, sit amet consectetur adipisicing elit. Molestias
          excepturi tempora harum tenetur! Placeat reprehenderit doloribus
          provident ut tenetur quaerat deserunt, adipisci, aspernatur culpa fuga
          excepturi, nostrum nemo consectetur dignissimos.
        </p>
        <div class="my-3 flex items-center gap-4 mt-8">
          <div>
            <NuxtImg src="/avatar.png" class="h-56 w-56 rounded-full" />
          </div>
          <div class="flex-1 max-w-md w-full">
            <div class="flex flex-col gap-1 w-full my-3">
              <div class="flex items-center">
                <h3 class="text-2xl">Author Name</h3>
                <UIcon
                  name="mdi:check-decagram"
                  class="w-5 h-5 text-blue-600 mt-1"
                />
              </div>
              <div class="flex items-center gap-1">
                <UBadge class="" color="gray" variant="solid"
                  >Badge hfghfhgfh</UBadge
                >
                <UBadge class="" color="gray" variant="solid"
                  >Badge hfghfhgfh</UBadge
                >
              </div>
            </div>
            <p class="w-full">
              Hello! My name is Adriana Martins working from Chile. I create
              some Ghost and Wordpress themes for differents markets, also, i
              offer live support via our ticket system.
            </p>

            <div class="flex items-center gap-3 my-3">
              <span> <UIcon name="logos:facebook" class="w-5 h-5" /> </span>
              <span>
                <UIcon name="skill-icons:instagram" class="w-5 h-5" />
              </span>
              <span>
                <UIcon name="skill-icons:gmail-light" class="w-5 h-5" />
              </span>
              <span>
                <UIcon name="logos:whatsapp-icon" class="w-5 h-5" />
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </UContainer>
</template>
