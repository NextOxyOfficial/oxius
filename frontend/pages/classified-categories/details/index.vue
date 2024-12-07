<template>
  <UContainer>
    <div class="mx-auto">
      <div class="flex items-center gap-3 ml-7">
        <h2 class="text-2xl">About the Author</h2>
        <div class="h-[1px] max-w-md w-full bg-gray-100 flex-1"></div>
      </div>

      <div class="my-3 flex items-center gap-4">
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
            Hello! My name is Adriana Martins working from Chile. I create some
            Ghost and Wordpress themes for differents markets, also, i offer
            live support via our ticket system.
          </p>

          <div class="flex items-center gap-3 my-3">
            <span>
              <UIcon name="skill-icons:gmail-light" class="w-5 h-5" />
            </span>
            <span> <UIcon name="logos:facebook" class="w-5 h-5" /> </span>
            <span> <UIcon name="logos:whatsapp-icon" class="w-5 h-5" /> </span>
            <span>
              <UIcon name="skill-icons:instagram" class="w-5 h-5" />
            </span>
          </div>
        </div>
      </div>

      <div class="w-full flex flex-col items-center justify-center my-5">
        <h2 class="text-5xl">Service Title</h2>
        <NuxtImg src="/placeholder.jpg" class="max-w-[50%] w-full rounded-md" />
        <p>
          Lorem ipsum dolor, sit amet consectetur adipisicing elit. Molestias
          excepturi tempora harum tenetur! Placeat reprehenderit doloribus
          provident ut tenetur quaerat deserunt, adipisci, aspernatur culpa fuga
          excepturi, nostrum nemo consectetur dignissimos.
        </p>
      </div>
    </div>
  </UContainer>
</template>
