<template>
    <div>
          <button
            @click="selectedArticle = null"
            class="mb-6 flex items-center text-gray-700 hover:text-primary transition-colors"
          >
            <ArrowLeftIcon class="h-5 w-5 mr-1" />
            Back to all news
          </button>
  
          <article class="bg-white rounded-xl shadow-lg overflow-hidden">
            <div class="relative h-[400px]">
              <img
                :src="selectedArticle.image"
                :alt="selectedArticle.title"
                class="w-full h-full object-cover"
              />
              <div
                class="absolute inset-0 bg-gradient-to-t from-black/70 to-transparent"
              ></div>
              <div class="absolute bottom-0 left-0 right-0 p-6 sm:p-8 text-white">
                <div class="flex items-center mb-4">
                  <span
                    class="bg-primary text-white text-xs font-bold px-3 py-1 rounded-full"
                  >
                    {{ getCategoryName(selectedArticle.categoryId) }}
                  </span>
                  <span class="ml-3 text-sm opacity-80">{{
                    selectedArticle.date
                  }}</span>
                  <span class="ml-3 text-sm opacity-80 flex items-center">
                    <ClockIcon class="h-4 w-4 mr-1" />
                    {{ selectedArticle.readTime }} min read
                  </span>
                </div>
                <h1 class="text-3xl sm:text-4xl font-bold mb-4 leading-tight">
                  {{ selectedArticle.title }}
                </h1>
              </div>
            </div>
  
            <div class="p-6 sm:p-8">
              <div class="flex items-center mb-8 border-b border-gray-200 pb-6">
                <img
                  :src="selectedArticle.authorImage"
                  :alt="selectedArticle.author"
                  class="h-12 w-12 rounded-full mr-4 border-2 border-primary"
                />
                <div>
                  <p class="font-medium text-gray-900">
                    Posted by:
                    <span class="text-primary">{{ selectedArticle.author }}</span>
                  </p>
                  <p class="text-sm text-gray-500">
                    {{ selectedArticle.authorTitle }}
                  </p>
                </div>
                <div class="ml-auto flex space-x-3">
                  <button
                    class="p-2 bg-blue-500 text-white rounded-full hover:bg-blue-600 transition-colors"
                  >
                    <TwitterIcon class="h-4 w-4" />
                  </button>
                  <button
                    class="p-2 bg-blue-700 text-white rounded-full hover:bg-blue-800 transition-colors"
                  >
                    <FacebookIcon class="h-4 w-4" />
                  </button>
                  <button
                    class="p-2 bg-green-600 text-white rounded-full hover:bg-green-700 transition-colors"
                  >
                    <LinkIcon class="h-4 w-4" />
                  </button>
                </div>
              </div>
  
              <div
                class="prose max-w-none mb-10"
                v-html="selectedArticle.content"
              ></div>
  
              <div class="flex flex-wrap gap-2 mb-10">
                <span
                  v-for="(tag, index) in selectedArticle.tags"
                  :key="index"
                  class="px-3 py-1 bg-gray-100 text-gray-700 rounded-full text-sm hover:bg-gray-200 cursor-pointer transition-colors"
                >
                  #{{ tag }}
                </span>
              </div>
  
              <!-- Comments Section -->
              <div class="border-t border-gray-200 pt-8">
                <h2 class="text-2xl font-bold mb-6 text-gray-900">
                  Comments ({{ selectedArticle.comments.length }})
                </h2>
  
                <form @submit.prevent="addComment" class="mb-8">
                  <div class="space-y-4">
                    <div class="flex-1">
                      <input
                        v-model="newComment.text"
                        rows="3"
                        placeholder="Write your name..."
                        required
                        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary bg-white text-gray-900"
                      />
                    </div>
                    <div class="flex-1">
                      <textarea
                        v-model="newComment.text"
                        rows="3"
                        placeholder="Write a comment..."
                        required
                        class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-primary focus:border-primary bg-white text-gray-900"
                      ></textarea>
                      <div class="mt-3 flex justify-end">
                        <button
                          type="submit"
                          class="px-4 py-2 bg-primary text-white rounded-lg hover:bg-primary-dark focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-primary transition-colors"
                        >
                          Post Comment
                        </button>
                      </div>
                    </div>
                  </div>
                </form>
  
                <div class="space-y-6">
                  <transition-group name="comment-list">
                    <div
                      v-for="(comment, index) in selectedArticle.comments"
                      :key="index"
                      class="bg-gray-50 p-4 rounded-lg border border-gray-200"
                    >
                      <div class="flex items-start space-x-4">
                        
                        <div class="flex-1">
                          <div class="flex justify-between mb-2">
                            <h3 class="font-bold text-gray-900">
                              {{ comment.name }}
                            </h3>
                            <span class="text-sm text-gray-500">{{
                              comment.date
                            }}</span>
                          </div>
                          <p class="text-gray-700">{{ comment.text }}</p>
                        </div>
                      </div>
                    </div>
                  </transition-group>
                  <div
                    v-if="selectedArticle.comments.length === 0"
                    class="text-center py-8 text-gray-500"
                  >
                    No comments yet. Be the first to comment!
                  </div>
                </div>
              </div>
  
              <!-- Related Articles -->
              <div class="mt-12 border-t border-gray-200 pt-8">
                <h2 class="text-2xl font-bold mb-6 text-gray-900">
                  Related Articles
                </h2>
                <div class="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                  <div
                    v-for="article in relatedArticles"
                    :key="article.id"
                    class="bg-gray-50 rounded-lg overflow-hidden shadow-md hover:shadow-lg transition-all duration-300"
                  >
                    <div class="relative h-40 overflow-hidden">
                      <img
                        :src="article.image"
                        :alt="article.title"
                        class="w-full h-full object-cover transition-transform duration-500 hover:scale-110"
                      />
                    </div>
                    <div class="p-4">
                      <h3
                        @click="selectArticle(article)"
                        class="text-lg font-bold mb-2 text-gray-900 hover:text-primary cursor-pointer transition-colors"
                      >
                        {{ article.title }}
                      </h3>
                      <div
                        class="flex items-center justify-between text-sm text-gray-500"
                      >
                        <div class="flex items-center">
                          <CalendarIcon class="h-4 w-4 mr-1" />
                          <span>{{ article.date }}</span>
                        </div>
                        <span
                          >Posted by:
                          <span class="text-primary">{{
                            article.author
                          }}</span></span
                        >
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </article>
        </div>
</template>
<script setup>
 definePageMeta({
    layout: "adsy-news",
  });
import {
    SunIcon,
    MenuIcon,
    XIcon,
    SearchIcon,
    ChevronLeftIcon,
    ChevronRightIcon,
    CalendarIcon,
    ClockIcon,
    MessageSquareIcon,
    ArrowRightIcon,
    ArrowLeftIcon,
    TwitterIcon,
    FacebookIcon,
    LinkIcon,
    CloudIcon,
    CloudRainIcon,
    LayoutGridIcon,
    LayoutListIcon,
    TrendingUpIcon,
  } from "lucide-vue-next";
  
  // Navigation state
  const mobileMenuOpen = ref(false);
  
  // Search state
  const searchQuery = ref("");
  const searchResults = ref([]);
  
  // Perform search when query changes
  const performSearch = () => {
    // Always show results as user types, even with just 1 character
    if (!searchQuery.value) {
      searchResults.value = [];
      return;
    }
  
    // Filter articles based on search query
    const query = searchQuery.value.toLowerCase();
  
    searchResults.value = articles.value.filter((article) => {
      return article.title.toLowerCase().includes(query);
    });
  };
  
  // Clear search
  const clearSearch = () => {
    searchQuery.value = "";
    searchResults.value = [];
  };
  
  // Newsletter
  const newsletterEmail = ref("");
  const subscribeNewsletter = () => {
    // Simulate subscription
    alert(`Thank you for subscribing with ${newsletterEmail.value}!`);
    newsletterEmail.value = "";
  };
  
  // Categories
  const categories = ref([
    { id: "all", name: "All News" },
    { id: "world", name: "World" },
    { id: "politics", name: "Politics" },
    { id: "business", name: "Business" },
    { id: "technology", name: "Technology" },
    { id: "science", name: "Science" },
    { id: "health", name: "Health" },
    { id: "sports", name: "Sports" },
    { id: "entertainment", name: "Entertainment" },
  ]);
  
  const activeCategory = ref("all");
  const setActiveCategory = (categoryId) => {
    activeCategory.value = categoryId;
    selectedArticle.value = null;
    mobileMenuOpen.value = false;
  };
  
  const getCategoryName = (categoryId) => {
    const category = categories.value.find((c) => c.id === categoryId);
    return category ? category.name : "Uncategorized";
  };
  
  // Layout options
  const layouts = ref([
    { id: "grid", name: "Grid View" },
    { id: "list", name: "List View" },
  ]);
  const currentLayout = ref("grid");
  
  // Breaking news ticker
  const breakingNews = ref([
    "Global Summit on Climate Change Reaches Historic Agreement",
    "New Technology Breakthrough Could Revolutionize Renewable Energy",
    "Major Economic Reform Bill Passes in Senate",
    "Scientists Discover Potential Cure for Rare Disease",
  ]);
  const currentTickerIndex = ref(0);
  
  const startTicker = () => {
    setInterval(() => {
      currentTickerIndex.value =
        (currentTickerIndex.value + 1) % breakingNews.value.length;
    }, 5000);
  };
  
  // Current date
  const currentDate = computed(() => {
    return new Date().toLocaleDateString("en-US", {
      weekday: "long",
      year: "numeric",
      month: "long",
      day: "numeric",
    });
  });
  
  // Weather data (simulated)
  const weather = reactive({
    temp: 24,
    condition: "Partly Cloudy",
    icon: "cloud",
  });
  
  // Trending News Carousel
  const trendingArticles = computed(() => {
    // Sort articles by number of comments (as a proxy for popularity)
    return [...articles.value]
      .sort((a, b) => b.comments.length - a.comments.length)
      .slice(0, 8); // Take top 8 trending articles
  });
  
  const trendingIndex = ref(0);
  const trendingPerPage = computed(() => {
    if (window.innerWidth < 640) return 1;
    if (window.innerWidth < 768) return 2;
    if (window.innerWidth < 1024) return 3;
    return 4;
  });
  
  const nextTrending = () => {
    const maxIndex =
      Math.ceil(trendingArticles.value.length / trendingPerPage.value) - 1;
    trendingIndex.value =
      trendingIndex.value >= maxIndex ? 0 : trendingIndex.value + 1;
  };
  
  const prevTrending = () => {
    const maxIndex =
      Math.ceil(trendingArticles.value.length / trendingPerPage.value) - 1;
    trendingIndex.value =
      trendingIndex.value <= 0 ? maxIndex : trendingIndex.value - 1;
  };
  
  // Trending Topics
  const trendingTopics = ref([
    "Climate Change",
    "Artificial Intelligence",
    "Global Economy",
    "Space Exploration",
    "Renewable Energy",
    "Healthcare Innovation",
    "Cybersecurity",
  ]);
  
  // Articles data
  const articles = ref([
    {
      id: 1,
      title: "New Technology Breakthrough Could Revolutionize Renewable Energy",
      summary:
        "Scientists have developed a new method to harness solar energy with unprecedented efficiency, potentially making renewable energy more accessible worldwide.",
      content: `<p class="mb-4">Scientists at the National Renewable Energy Laboratory have announced a breakthrough in solar cell technology that could dramatically increase efficiency while reducing costs.</p>
                <p class="mb-4">The new technology, which uses a novel arrangement of materials to capture a broader spectrum of sunlight, has achieved a record-breaking 39% efficiency in laboratory tests. This represents a significant improvement over current commercial solar panels, which typically operate at 15-20% efficiency.</p>
                <p class="mb-4">"This is a game-changer for renewable energy," said Dr. Sarah Chen, lead researcher on the project. "With this level of efficiency, solar power becomes not just competitive with fossil fuels, but potentially more economical in many regions."</p>
                <p class="mb-4">Industry analysts predict that if the technology can be successfully commercialized, it could accelerate the global transition to renewable energy sources and help combat climate change.</p>
                <p class="mb-4">The breakthrough involves a new type of "tandem" solar cell that stacks multiple layers of light-absorbing materials. Each layer is designed to capture a different part of the solar spectrum, allowing the cell to harvest more energy from the same amount of sunlight.</p>
                <p class="mb-4">What makes this development particularly promising is that the materials used are abundant and relatively inexpensive, addressing one of the key challenges in scaling up renewable energy technologies.</p>
                <p class="mb-4">"We've been working on this for nearly a decade," Dr. Chen explained. "The real innovation came when we developed a new manufacturing process that allows these complex cells to be produced at scale without significantly increasing costs."</p>
                <p class="mb-4">The research team is now working with industry partners to scale up production and expects the first commercial products to be available within three years.</p>
                <p class="mb-4">Environmental groups have hailed the announcement as a potential turning point in the fight against climate change. "This kind of technological leap is exactly what we need to accelerate the transition away from fossil fuels," said James Rivera, director of the Climate Action Coalition.</p>
                <p class="mb-4">The breakthrough comes at a critical time, as countries around the world are seeking to reduce carbon emissions and meet ambitious climate targets. If successfully deployed at scale, this technology could help nations achieve their renewable energy goals while potentially reducing electricity costs for consumers.</p>`,
      image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
      date: "May 15, 2023",
      readTime: 5,
      author: "John Doe",
      authorTitle: "Science Correspondent",
      authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
      categoryId: "technology",
      tags: ["renewable energy", "solar power", "climate change", "technology"],
      comments: [
        {
          name: "Alex Johnson",
          text: "This is incredible news! I wonder how long until we see this technology in commercial applications.",
          date: "May 15, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
        {
          name: "Maria Garcia",
          text: "I'm skeptical about the timeline for commercialization. These breakthroughs often take decades to reach the market.",
          date: "May 16, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
      ],
    },
    {
      id: 2,
      title: "Global Summit on Climate Change Reaches Historic Agreement",
      summary:
        "World leaders have committed to ambitious new targets for reducing carbon emissions by 2030, marking a significant step forward in international climate cooperation.",
      content: `<p class="mb-4">In a landmark decision, representatives from 195 countries have agreed to a new framework for tackling climate change at the Global Climate Summit in Geneva.</p>
                <p class="mb-4">The agreement, which builds on the Paris Climate Accord, sets more ambitious targets for reducing greenhouse gas emissions and provides financial mechanisms to support developing nations in their transition to cleaner energy sources.</p>
                <p class="mb-4">"This represents a turning point in our collective effort to address the climate crisis," said UN Secretary-General António Guterres. "For the first time, we have concrete commitments from all major economies that align with what the science tells us is necessary."</p>
                <p class="mb-4">Key provisions of the agreement include:</p>
                <ul class="list-disc pl-5 mb-4">
                  <li class="mb-2">A 50% reduction in global carbon emissions by 2030 compared to 2005 levels</li>
                  <li class="mb-2">Establishment of a $100 billion annual fund to help vulnerable nations adapt to climate impacts</li>
                  <li class="mb-2">Phasing out of coal power in developed nations by 2030 and globally by 2040</li>
                  <li class="mb-2">Commitment to protect 30% of land and ocean ecosystems by 2030</li>
                </ul>
                <p class="mb-4">The agreement came after intense negotiations that extended nearly 48 hours beyond the scheduled conclusion of the summit. Several key sticking points had threatened to derail the talks, including disagreements over financing mechanisms and the timeline for emissions reductions.</p>
                <p class="mb-4">Climate activists have cautiously welcomed the agreement while emphasizing the need for immediate action. "These commitments are a step in the right direction, but the real test will be implementation," said Greta Thunberg, who led protests outside the summit. "We need to see concrete policies and actions, not just promises."</p>
                <p class="mb-4">The agreement is legally binding, with provisions for regular reporting and verification of progress. Countries that fail to meet their commitments could face trade penalties and exclusion from certain international financial mechanisms.</p>
                <p class="mb-4">Market reaction to the announcement has been positive, with renewable energy stocks surging and fossil fuel companies seeing modest declines. Analysts suggest this reflects growing investor confidence in the global energy transition.</p>
                <p class="mb-4">The next steps will involve each country developing detailed implementation plans, which must be submitted to the UN within six months. A follow-up summit is scheduled for next year to assess progress and address any challenges in implementation.</p>`,
      image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
      date: "June 2, 2023",
      readTime: 6,
      author: "Emma Wilson",
      authorTitle: "Political Correspondent",
      authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
      categoryId: "world",
      tags: [
        "climate change",
        "global summit",
        "carbon emissions",
        "international relations",
      ],
      comments: [
        {
          name: "Thomas Lee",
          text: "It's about time! Now we need to make sure countries actually follow through on these commitments.",
          date: "June 2, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
        {
          name: "Sarah Johnson",
          text: "I'm concerned about the enforcement mechanisms. Without real consequences, these agreements don't mean much.",
          date: "June 3, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
        {
          name: "Michael Chen",
          text: "This is a significant step forward. The inclusion of financial support for developing nations is particularly important.",
          date: "June 3, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
      ],
    },
    {
      id: 3,
      title: "Artificial Intelligence Makes Breakthrough in Medical Diagnostics",
      summary:
        "A new AI system can detect early signs of cancer with greater accuracy than human doctors, potentially revolutionizing early disease detection.",
      content: `<p class="mb-4">Researchers at Stanford Medical Center have developed an artificial intelligence system that can detect early signs of several types of cancer with significantly higher accuracy than experienced oncologists.</p>
                <p class="mb-4">The system, named MediScan, was trained on millions of medical images and can identify subtle patterns that might be missed by human observers. In clinical trials, it demonstrated a 94% accuracy rate in detecting early-stage pancreatic cancer, compared to 65% for specialist physicians.</p>
                <p class="mb-4">"Early detection is crucial for successful treatment of many cancers," explained Dr. Robert Kim, who led the research team. "MediScan could potentially save thousands of lives by identifying cancers at a stage when they're much more treatable."</p>
                <p class="mb-4">The technology is now undergoing FDA review and could be deployed in hospitals within the next two years.</p>`,
      image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
      date: "June 10, 2023",
      readTime: 4,
      author: "David Chen",
      authorTitle: "Health & Science Editor",
      authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
      categoryId: "health",
      tags: [
        "artificial intelligence",
        "healthcare",
        "cancer research",
        "medical technology",
      ],
      comments: [],
    },
    {
      id: 4,
      title: "Major Economic Reform Bill Passes in Senate",
      summary:
        "After months of negotiation, the Senate has passed a comprehensive economic reform package aimed at reducing inflation and boosting growth.",
      content: `<p class="mb-4">The U.S. Senate has passed a sweeping economic reform bill that aims to address inflation, create jobs, and strengthen the middle class. The legislation, which passed with bipartisan support, now moves to the House of Representatives.</p>
                <p class="mb-4">Key provisions of the bill include tax incentives for businesses that create domestic manufacturing jobs, expanded child tax credits for families, and measures to reduce prescription drug prices.</p>
                <p class="mb-4">"This represents the most significant economic legislation in a generation," said Senate Majority Leader in a press conference following the vote. "We're taking concrete steps to build an economy that works for everyone, not just those at the top."</p>
                <p class="mb-4">Economists have generally responded positively to the package, with many predicting it could help reduce inflation while stimulating economic growth. However, some have expressed concerns about its impact on the national debt.</p>`,
      image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
      date: "June 15, 2023",
      readTime: 7,
      author: "Jennifer Adams",
      authorTitle: "Economics Correspondent",
      authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
      categoryId: "politics",
      tags: ["economics", "legislation", "inflation", "politics"],
      comments: [
        {
          name: "Robert Johnson",
          text: "It's about time we saw some real action on economic reform. The expanded child tax credit will make a huge difference for families.",
          date: "June 15, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
      ],
    },
    {
      id: 5,
      title: "Tech Giant Unveils Revolutionary New Smartphone",
      summary:
        "The latest flagship device features groundbreaking battery technology and advanced AI capabilities that could set new industry standards.",
      content: `<p class="mb-4">Tech industry leader Quantum Technologies has unveiled its latest flagship smartphone, the Quantum X, featuring several innovations that could reshape the mobile device market.</p>
                <p class="mb-4">The most notable advancement is the phone's new solid-state battery technology, which the company claims can fully charge in just 10 minutes and last up to 72 hours on normal usage. If these claims hold up in real-world testing, it would represent a major leap forward in addressing one of the most common consumer complaints about smartphones.</p>
                <p class="mb-4">"We've been working on this technology for over five years," said Quantum's CEO during the launch event. "This isn't just an incremental improvement—it's a fundamental rethinking of how we power mobile devices."</p>
                <p class="mb-4">The Quantum X also features an advanced AI system that runs entirely on-device, rather than relying on cloud processing. This approach offers both improved privacy and faster performance for AI-driven features like photography, translation, and voice assistance.</p>`,
      image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
      date: "June 20, 2023",
      readTime: 5,
      author: "Michael Zhang",
      authorTitle: "Technology Reporter",
      authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
      categoryId: "technology",
      tags: [
        "technology",
        "smartphones",
        "battery technology",
        "artificial intelligence",
      ],
      comments: [
        {
          name: "Lisa Chen",
          text: "I'm most excited about the battery technology. If it lives up to the hype, this could be a game-changer.",
          date: "June 20, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
        {
          name: "James Wilson",
          text: "The on-device AI processing is a huge step forward for privacy. I'm glad to see companies finally taking this seriously.",
          date: "June 21, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
      ],
    },
    {
      id: 6,
      title: "Historic Sports Upset Shocks Fans Worldwide",
      summary:
        "Underdog team defeats reigning champions in what analysts are calling one of the biggest upsets in sports history.",
      content: `<p class="mb-4">In a stunning turn of events that has shocked the sports world, underdog team FC United has defeated the heavily favored Atletico Stars in the Champions Cup final.</p>
                <p class="mb-4">FC United, ranked 15th in the league and given less than a 5% chance of winning by oddsmakers, managed to secure a 2-1 victory with a dramatic goal in the final minutes of extra time.</p>
                <p class="mb-4">"This is what sports is all about," said FC United's captain after the match. "We believed in ourselves even when no one else did. This victory is for all the underdogs out there."</p>
                <p class="mb-4">The upset has already been compared to some of the greatest in sports history, with social media exploding with reactions from fans and celebrities alike.</p>
                <p class="mb-4">Atletico Stars, who had dominated the season with an almost perfect record, were visibly stunned by the defeat. "We didn't underestimate them, but sometimes in football, the best team doesn't win," said their manager in the post-match press conference.</p>`,
      image: "/static/frontend/images/placeholder.jpg?height=600&width=800",
      date: "June 25, 2023",
      readTime: 4,
      author: "Carlos Rodriguez",
      authorTitle: "Sports Editor",
      authorImage: "/static/frontend/images/placeholder.jpg?height=100&width=100",
      categoryId: "sports",
      tags: ["sports", "football", "champions cup", "upsets"],
      comments: [
        {
          name: "Diego Fernandez",
          text: "I was there! The atmosphere was electric when that final goal went in. A moment I'll never forget.",
          date: "June 25, 2023",
          userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
        },
      ],
    },
  ]);
  
  // Latest article (most recent by date)
  const latestArticle = computed(() => {
    return [...articles.value].sort((a, b) => {
      return new Date(b.date) - new Date(a.date);
    })[0];
  });
  
  // Filter articles based on active category and exclude latest article
  const filteredArticles = computed(() => {
    let filtered = articles.value.filter(
      (article) => article.id !== latestArticle.value.id
    );
  
    if (activeCategory.value === "all") {
      return filtered;
    } else {
      return filtered.filter(
        (article) => article.categoryId === activeCategory.value
      );
    }
  });
  
  // Related articles (for article detail view)
  const relatedArticles = computed(() => {
    if (!selectedArticle.value) return [];
  
    return articles.value
      .filter(
        (article) =>
          article.id !== selectedArticle.value.id &&
          article.categoryId === selectedArticle.value.categoryId
      )
      .slice(0, 3);
  });
  
  // Article view state
  const selectedArticle = ref(null);
  
  const selectArticle = (article) => {
    selectedArticle.value = article;
    window.scrollTo(0, 0);
    // Clear search when selecting an article
    searchQuery.value = "";
    searchResults.value = [];
  };
  
  const readArticle = (article) => {
    selectArticle(article);
  };
  
  // Load more articles (simulated)
  const loadMoreArticles = () => {
    // In a real app, this would fetch more articles from an API
    alert(
      "In a real application, this would load more articles from the server."
    );
  };
  
  // New comment form data
  const newComment = reactive({
    text: "",
  });
  
  // Function to add a new comment
  const addComment = () => {
    if (newComment.text) {
      selectedArticle.value.comments.unshift({
        name: "Guest User",
        text: newComment.text,
        date: new Date().toLocaleDateString("en-US", {
          year: "numeric",
          month: "long",
          day: "numeric",
        }),
        userImage: "/static/frontend/images/placeholder.jpg?height=40&width=40",
      });
  
      // Reset form
      newComment.text = "";
    }
  };
  
  // Initialize on mount
  onMounted(() => {
    // Start breaking news ticker
    startTicker();
  
    // Set up window resize listener for responsive carousel
    window.addEventListener("resize", () => {
      // Reset carousel index when screen size changes to avoid empty slides
      trendingIndex.value = 0;
    });
  });
  </script>
  
  <style>
  :root {
    --color-primary: #e53e3e;
    --color-primary-dark: #c53030;
  }
  
  .bg-primary {
    background-color: var(--color-primary);
  }
  
  .text-primary {
    color: var(--color-primary);
  }
  
  .hover\:text-primary:hover {
    color: var(--color-primary);
  }
  
  .hover\:text-primary-dark:hover {
    color: var(--color-primary-dark);
  }
  
  .hover\:bg-primary-dark:hover {
    background-color: var(--color-primary-dark);
  }
  
  .focus\:ring-primary:focus {
    --tw-ring-color: var(--color-primary);
  }
  
  .focus\:border-primary:focus {
    border-color: var(--color-primary);
  }
  
  .border-primary {
    border-color: var(--color-primary);
  }
  
  /* Ticker animation */
  .ticker-container {
    animation: ticker 20s linear infinite;
  }
  
  .ticker-item {
    margin-right: 50px;
  }
  
  @keyframes ticker {
    0% {
      transform: translateX(100%);
    }
    100% {
      transform: translateX(-100%);
    }
  }
  
  /* Transition effects */
  .comment-list-enter-active,
  .comment-list-leave-active {
    transition: all 0.5s ease;
  }
  .comment-list-enter-from,
  .comment-list-leave-to {
    opacity: 0;
    transform: translateY(30px);
  }
  
  /* Line clamp for article summaries */
  .line-clamp-2 {
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    overflow: hidden;
  }
  </style>