/**
 * Composable for handling mention functionality in comments
 */
export const useMentions = () => {
  
  /**
   * Process comment content to make mentioned usernames clickable
   * @param {string} content - The comment content
   * @param {Function} h - Vue's render function or component's h function
   * @returns {Array} Array of VNode elements or string parts
   */
  const processMentionedUsers = (content, h) => {
    if (!content) return [content];    // Improved regex to match @Username patterns including full names
    // This pattern matches @ followed by any characters until a space, punctuation, or end of string
    // It handles names like "John Doe", "John-Paul Smith", "Mary O'Connor", etc.
    const mentionRegex = /@([^\s@]+(?:\s+[^\s@]+)*?)(?=\s|$|[.!?,:;])/g;
    
    const parts = [];
    let lastIndex = 0;
    let match;

    // Process all mentions in the content
    while ((match = mentionRegex.exec(content)) !== null) {
      const beforeMention = content.slice(lastIndex, match.index);
      const mentionedName = match[1].trim();
      
      // Add text before the mention
      if (beforeMention) {
        parts.push(beforeMention);
      }
      
      // Create clickable mention link
      parts.push(
        h('NuxtLink', {
          to: `/business-network/profile/search?name=${encodeURIComponent(mentionedName)}`,
          class: 'text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium cursor-pointer transition-colors duration-200',
          onClick: (event) => {
            // We'll handle the navigation through search since we only have the name
            event.preventDefault();
            navigateToUserProfile(mentionedName);
          }
        }, `@${mentionedName}`)
      );
      
      lastIndex = match.index + match[0].length;
    }
    
    // Add any remaining text after the last mention
    if (lastIndex < content.length) {
      parts.push(content.slice(lastIndex));
    }
    
    // If no mentions found, return the original content
    return parts.length === 0 ? [content] : parts;
  };  /**
   * Navigate to user profile by searching for the mentioned name
   * Since we only have the display name and not the user ID, we'll search for the user
   * @param {string} mentionedName - The mentioned user's display name
   */
  const navigateToUserProfile = async (mentionedName) => {
    try {
      const router = useRouter();
      
      // Navigate to search results to help find the mentioned user
      // This is more reliable than trying to guess the user ID
      await router.push({
        path: `/business-network/search-results/${encodeURIComponent(mentionedName)}`,
        query: { type: 'people' }
      });
    } catch (error) {
      console.error('Error navigating to mentioned user:', error);
      // Fallback to general business network search
      try {
        const router = useRouter();
        await router.push({
          path: '/business-network',
          query: { search: mentionedName }
        });
      } catch (fallbackError) {
        console.error('Error with fallback navigation:', fallbackError);
      }
    }
  };/**
   * Simple version that returns HTML string for v-html usage
   * @param {string} content - The comment content
   * @returns {string} HTML string with clickable mentions
   */
  const processMentionsAsHTML = (content) => {
    if (!content) return content;

    // Improved regex to match @Username patterns including full names
    // This pattern matches @ followed by any characters until a space, punctuation, or end of string
    // It handles names like "John Doe", "John-Paul Smith", "Mary O'Connor", etc.
    const mentionRegex = /@([^\s@]+(?:\s+[^\s@]+)*?)(?=\s|$|[.!?,:;])/g;
    
    return content.replace(mentionRegex, (match, mentionedName) => {
      const trimmedName = mentionedName.trim();
      // Create a clickable span that calls a global navigation function
      return `<span class="mention-link text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 font-medium cursor-pointer transition-colors duration-200" data-username="${trimmedName}">@${trimmedName}</span>`;
    });
  };

  /**
   * Setup click handlers for mention links
   * Call this in the component's onMounted hook
   */
  const setupMentionClickHandlers = () => {
    if (process.client) {
      // Add global click listener for mention links
      document.addEventListener('click', (event) => {
        if (event.target.classList.contains('mention-link')) {
          event.preventDefault();
          const username = event.target.getAttribute('data-username');
          if (username) {
            navigateToUserProfile(username);
          }
        }
      });
    }
  };
  return {
    processMentionedUsers,
    navigateToUserProfile,
    processMentionsAsHTML,
    setupMentionClickHandlers
  };
};
