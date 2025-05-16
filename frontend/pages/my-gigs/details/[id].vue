<template>
	<PublicSection>
		<AccountBalance
			v-if="user?.user"
			:user="user"
			:isUser="true"
		/>
		<h1 class="text-center text-4xl my-8">
			{{ submittedTasks[0]?.gig.title }}
		</h1>
		<UContainer>
			<div class="flex justify-between items-center mb-4">
				<UButton
					size="sm"
					color="primary"
					variant="solid"
					label="Approve All Pending"
					:loading="isApproveAllLoading"
					@click="handleApproveAll"
					v-if="hasUnapprovedTasks"
				/>
				<USelect
					color="white"
					size="md"
					:options="filterOptions"
					v-model="selectedFilter"
					placeholder="Search"
					class="w-40 capitalize ml-auto"
				/>
			</div>
			<UTable
				:rows="submittedTasks"
				:columns="columns"
				class="mb-8 mt-3"
			>
				<template #index-data="{ row }">
					<p>
						{{ row.id }}
					</p>
				</template>
				<template #created_at-data="{ row }">
					<p>
						{{ formatDate(row.created_at) }}
					</p>
				</template>

				<template #amount-data="{ row }">
					<p>
						{{ row.gig.price }}
					</p>
				</template>
				<template #title-data="{ row }">
					<p>
						{{ row.gig.title }}
					</p>
				</template>
				<template #user_details-data="{ row }">
					<p>
						{{ row.user_details.name }}
					</p>
				</template>
				<template #auto_approve-data="{ row }">
					<p
						v-if="row.approved"
						class="text-sm text-green-500"
					>
						Approved
					</p>
					<p
						v-if="row.rejected"
						class="text-sm text-red-500"
					>
						Rejected
					</p>

					<p
						v-if="!row.completed"
						class="text-sm"
						:class="{
							'text-red-500':
								getRemainingTime(row.created_at) === 'Auto Approved',
							'text-orange-500': getRemainingTime(row.created_at).includes(
								'remaining'
							),
						}"
					>
						{{ getRemainingTime(row.created_at) }}
					</p>
				</template>
				<template #approve-data="{ row }">
					<div class="flex gap-1.5">
						<UButton
							v-if="row.rejected"
							size="xs"
							class="w-[67px] justify-center"
							color="primary"
							@click="handleOperation(row.id, 'approve')"
							variant="outline"
							:label="'Approve'"
							:loading="isLoading"
						/>
						<UButton
							v-else
							size="xs"
							class="w-[67px] justify-center"
							color="primary"
							@click="handleOperation(row.id, 'approve')"
							variant="outline"
							:label="row.approved ? 'Approved' : 'Approve'"
							:disabled="row.rejected || row.approved"
							:loading="isLoading"
						/>
						<UButton
							v-if="!row.rejected && !row.approved"
							size="xs"
							class="w-[67px] justify-center"
							color="red"
							@click="openModal(row.id, 'reject')"
							variant="outline"
							:label="row.rejected ? 'Rejected' : 'Reject'"
							:disabled="row.rejected || row.approved"
							:loading="isLoading"
						/>

						<UIcon
							name="i-material-symbols:lab-profile-outline-sharp"
							class="text-green-700 text-xl cursor-pointer"
							@click="viewDetails(row.id, 'view')"
						/>
					</div>
				</template>
			</UTable>
		</UContainer>
		<UModal
			v-model="isOpen"
			prevent-close
		>
			<UCard
				:ui="{
					ring: '',
					divide: 'divide-y divide-gray-100 dark:divide-gray-800',
				}"
			>
				<template #header>
					<div class="flex items-center justify-between">
						<h3
							class="text-base font-semibold leading-6 text-gray-900 dark:text-white"
						>
							Rejection Reason
						</h3>
						<UButton
							color="gray"
							variant="ghost"
							icon="i-heroicons-x-mark-20-solid"
							class="-my-1"
							@click="isOpen = false"
						/>
					</div>
				</template>

				<UTextarea
					color="white"
					variant="outline"
					class="w-full"
					resize
					placeholder="Rejection Reason"
					v-model="rejectionReason"
				/>
				<p
					class="text-red-500 text-sm"
					v-if="rejectionFieldMissing"
				>
					{{ rejectionFieldMissing }}
				</p>
				<UButton
					size="md"
					color="primary"
					:loading="isRejectLoading"
					variant="solid"
					label="Submit Rejection"
					class="mt-4"
					@click="submitRejection"
				/>
			</UCard>
		</UModal>
		<UModal v-model="isOpenTaskDetails">
			<div class="p-6 bg-slate-100 border rounded-xl space-y-4">
				<p>
					{{ current_submitted_task_details.approved ? "Approved" : "Pending" }}
					||
					{{ formatDate(current_submitted_task_details.created_at) }}
				</p>
				<div class="bg-slate-50 p-4 rounded-xl space-y-3">
					<div v-html="current_submitted_task_details.submit_details"></div>
					<p>{{ current_submitted_task_details.media }}</p>
				</div>
				<UButton
					size="md"
					color="gray"
					variant="outline"
					label="Close"
					class="max-w-fit"
					@click="isOpenTaskDetails = false"
				/>
			</div>
		</UModal>
	</PublicSection>
</template>

<script setup>
	const isOpen = ref(false);
	const rejectionReason = ref("");
	const selectedTaskId = ref(null);
	const isOpenTaskDetails = ref(false);
	const filterOptions = ["All", "Approved", "Rejected"];

	const selectedFilter = ref("");
	const { get, del, put } = useApi();
	const { formatDate } = useUtils();
	const { user } = useAuth();
	const submittedTasks = ref([]);
	const current_submitted_task_details = ref([]);
	const route = useRoute();
	const isLoading = ref(false);
	const isRejectLoading = ref(false);

	async function getUserGigs() {
		try {
			const res = await get(
				`/task-by-micro-gig-post/${route.params.id}/tasks/`
			);
			console.log(res);
			submittedTasks.value = res.data;
		} catch (error) {
			console.log(error);
		}
	}
	getUserGigs();

	async function handleOperation(taskId, operation) {
		let update = {
			id: taskId,
		};
		if (operation === "approve") {
			update.approved = true;
		} else {
			update.rejected = true;
		}
		const res = await put(
			`/update-task-by-micro-gig-post/${route.params.id}/tasks/`,
			{
				tasks: [update],
			}
		);
		console.log(res);
		if (res.error) {
		} else {
			getUserGigs();
		}
	}

	// Add these with your other refs
	const isApproveAllLoading = ref(false);

	// Add this computed property
	const hasUnapprovedTasks = computed(() => {
		return submittedTasks.value.some(
			(task) => !task.approved && !task.rejected
		);
	});

	// Add this new function to handle approving all tasks
	async function handleApproveAll() {
		isApproveAllLoading.value = true;
		try {
			const unapprovedTasks = submittedTasks.value
				.filter((task) => !task.approved && !task.rejected)
				.map((task) => ({
					id: task.id,
					approved: true,
					rejected: false,
				}));

			if (unapprovedTasks?.length === 0) {
				return;
			}

			const res = await put(
				`/update-task-by-micro-gig-post/${route.params.id}/tasks/`,
				{
					tasks: unapprovedTasks,
				}
			);

			if (res.error) {
				console.error("Error approving all tasks:", res.error);
			} else {
				await getUserGigs(); // Refresh the data
			}
		} catch (error) {
			console.error("Error in handleApproveAll:", error);
		} finally {
			isApproveAllLoading.value = false;
		}
	}

	function openModal(taskId, operation) {
		isOpen.value = true;
		console.log(taskId, operation);
		selectedTaskId.value = taskId;
		rejectionReason.value = "";
	}
	const rejectionFieldMissing = ref("");
	async function submitRejection() {
		if (!selectedTaskId.value || !rejectionReason.value) {
			rejectionFieldMissing.value = "Provide the rejection reason!";
			console.log("Task ID or rejection reason is missing");
			return;
		}
		rejectionFieldMissing.value = "";
		isRejectLoading.value = true;
		try {
			const res = await put(
				`/update-task-by-micro-gig-post/${route.params.id}/tasks/`,
				{
					tasks: [
						{
							id: selectedTaskId.value,
							approved: false,
							rejected: true,
							reason: rejectionReason.value,
						},
					],
				}
			);
			console.log(res);
			if (res.error) {
				console.log("Error:", res.error);
			} else {
				getUserGigs(); // Refresh the data
				isOpen.value = false; // Close the modal
			}
		} catch (error) {
			console.log("Error submitting rejection:", error);
		}
		isRejectLoading.value = false;
	}

	function viewDetails(taskId, operation) {
		console.log(taskId, operation);
		isOpenTaskDetails.value = true;
		current_submitted_task_details.value = submittedTasks.value.find(
			(task) => task.id === taskId
		);
	}

	watch(selectedFilter, () => {
		if (selectedFilter.value === "Approved") {
			submittedTasks.value = submittedTasks.value.filter(
				(task) => task.approved
			);
			console.log("approved");
		} else if (selectedFilter.value === "Rejected") {
			submittedTasks.value = submittedTasks.value.filter(
				(task) => task.rejected
			);
			console.log("rejected");
		}
	});

	function getRemainingTime(createdAt) {
		const created = new Date(createdAt);
		const deadline = new Date(created.getTime() + 48 * 60 * 60 * 1000); // 48 hours in milliseconds
		const now = new Date();
		const remaining = deadline - now;

		if (remaining <= 0) {
			return "Time expired";
		}

		const hours = Math.floor(remaining / (60 * 60 * 1000));
		const minutes = Math.floor((remaining % (60 * 60 * 1000)) / (60 * 1000));

		return `${hours}h ${minutes}m remaining`;
	}

	const columns = [
		{
			key: "index",
			label: "আইডি",
		},

		{
			key: "title",
			label: "নাম",
		},
		{
			key: "user_details",
			label: "ব্যবহারকারীর নাম",
		},
		{
			key: "amount",
			label: "দাম",
		},
		{
			key: "created_at",
			label: "সময়",
		},
		{
			key: "auto_approve",
			label: "Auto Approval",
		},
		{
			key: "approve",
			label: "অ্যাকশন",
		},
		{
			key: "reject",
			label: "",
		},
	];
</script>

<style scoped></style>
