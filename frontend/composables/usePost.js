export function usePost() {
  const posts = ref([]);
  const loading = ref(false);
  const error = ref(null);

  // Generate sample posts
  const generatePosts = (start, count) => {
    const categories = [
      "Marketing",
      "Finance",
      "Operations",
      "Leadership",
      "Technology",
      "HR",
      "Sales",
      "Strategy",
    ];
    const users = [
      {
        id: "user-1",
        fullName: "Emma Johnson",
        avatar: "/images/placeholder.jpg?height=40&width=40",
        verified: true,
      },
      {
        id: "user-2",
        fullName: "Liam Smith",
        avatar: "/images/placeholder.jpg?height=40&width=40",
      },
      {
        id: "user-3",
        fullName: "Olivia Williams",
        avatar: "/images/placeholder.jpg?height=40&width=40",
        verified: true,
      },
      {
        id: "user-4",
        fullName: "Noah Brown",
        avatar: "/images/placeholder.jpg?height=40&width=40",
      },
      {
        id: "user-5",
        fullName: "Ava Jones",
        avatar: "/images/placeholder.jpg?height=40&width=40",
      },
    ];

    return Array.from({ length: count }, (_, i) => {
      const postId = start + i;
      const likeCount = Math.floor(Math.random() * 30);
      const commentCount = Math.floor(Math.random() * 15);
      const mediaCount = Math.floor(Math.random() * 5) + 1;
      const user = users[Math.floor(Math.random() * users.length)];

      // Assign 1-2 random categories to each post
      const numCategories = Math.floor(Math.random() * 2) + 1;
      const postCategories = Array.from(
        { length: numCategories },
        () => categories[Math.floor(Math.random() * categories.length)]
      ).filter((value, index, self) => self.indexOf(value) === index); // Remove duplicates

      return {
        id: postId,
        title: `Business Strategy Update ${postId}: ${
          [
            "Market Analysis",
            "Quarterly Report",
            "Team Building",
            "Product Launch",
            "Industry Trends",
          ][Math.floor(Math.random() * 5)]
        }`,
        author: user,
        timestamp: new Date(Date.now() - postId * 3600000).toISOString(),
        content: [
          "Our latest market analysis shows significant growth opportunities in the APAC region. The consumer behavior data indicates a shift towards sustainable products, with a 27% increase in eco-friendly purchases over the last quarter.",
          "The Q3 financial results exceeded expectations with a 15% revenue increase year-over-year. Our cost-cutting initiatives have resulted in a 7% reduction in operational expenses, improving our overall profit margins.",
          "I'm excited to share that our team building workshop last week was a tremendous success. The cross-departmental collaboration exercises resulted in three innovative product ideas that we're now exploring further.",
          "We're thrilled to announce that our new product line will launch on November 15th. The marketing campaign will begin next week, focusing on digital channels and influencer partnerships.",
          "The latest industry report highlights a shift towards AI-powered solutions in our sector. Our R&D team has prepared a comprehensive analysis of how we can leverage these technologies to enhance our product offerings.",
        ][Math.floor(Math.random() * 5)],
        likeCount,
        likedBy: Array.from(
          { length: likeCount },
          () => users[Math.floor(Math.random() * users.length)]
        ),
        comments: Array.from({ length: commentCount }, (_, j) => ({
          id: `comment-${postId}-${j}`,
          user: users[Math.floor(Math.random() * users.length)],
          text: [
            "Great insight! Thanks for sharing.",
            "I completely agree with your analysis.",
            "This is exactly what our team needed to hear.",
            "Looking forward to discussing this further in our next meeting.",
            "Could you elaborate more on the second point?",
            "I've been thinking about this approach as well.",
          ][Math.floor(Math.random() * 6)],
          timestamp: new Date(
            Date.now() - Math.floor(Math.random() * 86400000 * 7)
          ).toISOString(),
        })),
        mediaCount,
        media: Array.from({ length: mediaCount }, (_, j) => ({
          id: `${postId}-${j}`,
          type: j < 4 ? "image" : "video",
          url: `/placeholder.jpg?height=300&width=400`,
          thumbnail: `/placeholder.jpg?height=150&width=200`,
          likeCount: Math.floor(Math.random() * 20),
          likedBy: Array.from(
            { length: Math.floor(Math.random() * 20) },
            () => users[Math.floor(Math.random() * users.length)]
          ),
        })),
        categories: postCategories,
        isLiked: false,
        isSaved: false,
      };
    });
  };

  // Get posts with optional filtering
  const getPosts = async ({ page = 1, limit = 10, filter = {} } = {}) => {
    loading.value = true;
    error.value = null;

    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1000));

      // Generate posts
      const start = (page - 1) * limit + 1;
      let newPosts = generatePosts(start, limit);

      // Apply filters if any
      if (filter.categories && filter.categories.length > 0) {
        newPosts = newPosts.filter((post) =>
          post.categories.some((category) =>
            filter.categories.includes(category)
          )
        );
      }

      if (filter.query) {
        const query = filter.query.toLowerCase();
        newPosts = newPosts.filter(
          (post) =>
            post.title.toLowerCase().includes(query) ||
            post.content.toLowerCase().includes(query)
        );
      }

      return newPosts;
    } catch (err) {
      error.value = err.message || "Failed to load posts";
      return [];
    } finally {
      loading.value = false;
    }
  };

  // Get a single post by ID
  const getPost = async (id) => {
    loading.value = true;
    error.value = null;

    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 500));

      // Generate a single post
      const post = generatePosts(id, 1)[0];
      return post;
    } catch (err) {
      error.value = err.message || "Failed to load post";
      return null;
    } finally {
      loading.value = false;
    }
  };

  // Create a new post
  const createPost = async (postData) => {
    loading.value = true;
    error.value = null;

    try {
      // Simulate API call
      await new Promise((resolve) => setTimeout(resolve, 1500));

      // Create new post
      const newPost = {
        id: Date.now(),
        author: {
          id: "current-user",
          fullName: "You",
          avatar: "/images/placeholder.jpg?height=40&width=40",
          verified: true,
        },
        timestamp: new Date().toISOString(),
        likeCount: 0,
        likedBy: [],
        comments: [],
        isLiked: false,
        isSaved: false,
        ...postData,
      };

      return newPost;
    } catch (err) {
      error.value = err.message || "Failed to create post";
      throw error.value;
    } finally {
      loading.value = false;
    }
  };

  return {
    posts,
    loading,
    error,
    getPosts,
    getPost,
    createPost,
  };
}
