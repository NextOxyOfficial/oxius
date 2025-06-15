/**
 * Composable for handling mention functionality in comments
 */
export const useMentions = () => {
  /**
   * Normalize and validate a username for mention processing
   * @param {string} username - The username to normalize
   * @returns {string} Normalized username
   */
  const normalizeUsername = (username) => {
    if (!username) return '';
    
    // Trim whitespace and remove any leading @ symbol
    let normalized = username.trim().replace(/^@+/, '');
    
    // Remove any trailing punctuation that might have been captured
    normalized = normalized.replace(/[.!?,:;]+$/, '');
    
    return normalized;
  };

  /**
   * Check if a string contains valid mention characters
   * @param {string} text - The text to validate
   * @returns {boolean} True if valid mention text
   */
  const isValidMentionText = (text) => {
    if (!text) return false;
    
    // Check if text contains only valid Unicode characters for names
    const validPattern = /^[\p{L}\p{M}\p{N}_'-]+(?:\s+[\p{L}\p{M}\p{N}_'-]+)*$/u;
    return validPattern.test(text.trim());
  };
    /**
   * Process comment content to make mentioned usernames clickable
   * @param {string} content - The comment content
   * @param {Function} h - Vue's render function or component's h function
   * @returns {Array} Array of VNode elements or string parts
   */  const processMentionedUsers = (content, h) => {
    if (!content) return [content];
    
    // Enhanced regex to match @Username patterns including full names
    // This pattern matches @ followed by Unicode letters, numbers, and common name characters
    // It stops at: space+@, punctuation, or end of string
    // Supports all Unicode scripts including Bangla, Arabic, Chinese, etc.
    const mentionRegex = /@([\p{L}\p{M}\p{N}_'-]+(?:\s+[\p{L}\p{M}\p{N}_'-]+)*?)(?=\s+@|\s*[.!?,:;]|\s*$|$)/gu;
    
    const parts = [];
    let lastIndex = 0;
    let match;    // Process all mentions in the content
    while ((match = mentionRegex.exec(content)) !== null) {
      const beforeMention = content.slice(lastIndex, match.index);
      const mentionedName = normalizeUsername(match[1]);
      
      // Skip if the extracted name is not valid
      if (!isValidMentionText(mentionedName)) {
        // Add the original text and continue
        if (beforeMention) {
          parts.push(beforeMention);
        }
        parts.push(match[0]); // Add the original @text
        lastIndex = match.index + match[0].length;
        continue;
      }
      
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
   * First try to find the user by name, then navigate to their profile
   * @param {string} mentionedName - The mentioned user's display name
   */
  const navigateToUserProfile = async (mentionedName) => {
    try {
      const router = useRouter();
      const { get } = useApi();
      
      console.log('Searching for mentioned user:', mentionedName);
      
      // First, try to search for the user by name to get their ID
      try {
        const { data } = await get(`/bn/user-search/?q=${encodeURIComponent(mentionedName)}`);
        
        let users = [];
        if (data && data.results) {
          users = data.results;
        } else if (Array.isArray(data)) {
          users = data;
        }
        
        // Find exact or close match
        const exactMatch = users.find(user => {
          const fullName = user.name || 
                          `${user.first_name || ''} ${user.last_name || ''}`.trim() || 
                          user.username;
          return fullName.toLowerCase() === mentionedName.toLowerCase();
        });
        
        if (exactMatch && exactMatch.id) {
          // Navigate directly to the user's profile
          console.log('Found exact match, navigating to profile:', exactMatch);
          await router.push(`/business-network/profile/${exactMatch.id}`);
          return;
        }
        
        // If no exact match but we have results, navigate to search results
        if (users.length > 0) {
          console.log('No exact match, showing search results');
          await router.push({
            path: `/business-network/search-results/${encodeURIComponent(mentionedName)}`,
            query: { type: 'people' }
          });
          return;
        }
      } catch (searchError) {
        console.error('Error searching for user:', searchError);
      }
      
      // Fallback: navigate to search results
      console.log('Fallback: navigating to search results');
      await router.push({
        path: `/business-network/search-results/${encodeURIComponent(mentionedName)}`,
        query: { type: 'people' }
      });
      
    } catch (error) {
      console.error('Error navigating to mentioned user:', error);
      // Final fallback to general business network search
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
  };  /**
   * Simple version that returns HTML string for v-html usage
   * Creates mention chips/tags with the same design as the input component
   * @param {string} content - The comment content
   * @returns {string} HTML string with mention chips and regular text
   */  const processMentionsAsHTML = (content) => {
    if (!content) return content;
    
    try {
      // Enhanced regex that stops at double spaces (our delimiter), punctuation, or other mentions
      // Double space acts as a clear boundary between mentions and regular text
      // Supports all Unicode scripts including Bangla, Arabic, Chinese, etc.
      // \p{L} = Unicode letters, \p{M} = Unicode marks (diacritics), \p{N} = Unicode numbers
      const mentionRegex = /@([\p{L}\p{M}\p{N}_'-]+(?:\s+[\p{L}\p{M}\p{N}_'-]+)*?)(?=\s{2,}|\s*[.!?,:;]|\s+@|\s*$|$)/gu;
      
      const result = content.replace(mentionRegex, (match, mentionedName) => {
        const trimmedName = normalizeUsername(mentionedName);
        
        // Skip if the extracted name is not valid
        if (!isValidMentionText(trimmedName)) {
          console.debug('Invalid mention text:', trimmedName, 'from match:', match);
          return match; // Return original text if not a valid mention
        }
        
        console.debug('Processing mention:', trimmedName, 'from original:', mentionedName);
        
        // Create mention chip with @ symbol and no space between @ and name
        return `<span 
          class="inline-flex items-center px-2.5 py-1 mx-0.5 bg-gradient-to-r from-blue-500/15 to-purple-500/15 dark:from-blue-600/25 dark:to-purple-600/25 border border-blue-200/60 dark:border-blue-700/40 rounded-full hover:from-blue-500/30 hover:to-purple-500/30 dark:hover:from-blue-600/40 dark:hover:to-purple-600/40 transition-all duration-300 cursor-pointer transform hover:scale-105 shadow-sm hover:shadow-md text-xs font-medium mention-chip mention-link active:scale-95" 
          data-username="${trimmedName}"
          title="Click to view ${trimmedName}'s profile"
          role="button"
          tabindex="0"
        >
          <span class="text-blue-700 dark:text-blue-300 hover:text-purple-700 dark:hover:text-purple-300 transition-colors duration-300 font-medium whitespace-nowrap">
            <span class="text-blue-500 dark:text-blue-400 hover:text-purple-500 dark:hover:text-purple-400 font-semibold">@</span>${trimmedName}
          </span>
        </span>`;
      }).replace(/\s{2,}/g, ' '); // Clean up multiple spaces after processing
      
      return result;
    } catch (error) {
      console.error('Error processing mentions in HTML:', error);
      return content; // Return original content on error
    }
  };
  /**
   * Setup click handlers for mention links
   * Call this in the component's onMounted hook
   */
  const setupMentionClickHandlers = () => {
    if (process.client) {
      // Add global click listener for mention links
      const handleMentionInteraction = (event) => {
        if (event.target.classList.contains('mention-link') || event.target.closest('.mention-link')) {
          event.preventDefault();
          event.stopPropagation();
          
          const mentionElement = event.target.classList.contains('mention-link') 
            ? event.target 
            : event.target.closest('.mention-link');
            
          const username = mentionElement.getAttribute('data-username');
          if (username) {
            console.log('Mention clicked:', username);
            navigateToUserProfile(username);
          }
        }
      };
      
      // Handle clicks
      document.addEventListener('click', handleMentionInteraction);
      
      // Handle keyboard navigation (Enter key)
      document.addEventListener('keydown', (event) => {
        if ((event.key === 'Enter' || event.key === ' ') && 
            (event.target.classList.contains('mention-link') || event.target.closest('.mention-link'))) {
          event.preventDefault();
          handleMentionInteraction(event);
        }
      });
    }
  };  return {
    processMentionedUsers,
    navigateToUserProfile,
    processMentionsAsHTML,
    setupMentionClickHandlers,
    normalizeUsername,
    isValidMentionText
  };
};
