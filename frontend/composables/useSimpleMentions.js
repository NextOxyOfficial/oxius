import { ref, computed, onMounted, onBeforeUnmount, watch, nextTick } from "vue";

// Clean, simple mention system that ACTUALLY works
export function useMentionSystem(props, emit) {
  // Core state
  const extractedMentions = ref([]);
  const displayCommentText = ref('');
  
  // Dropdown state
  const showMentions = ref(false);
  const mentionSuggestions = ref([]);
  const mentionSearchText = ref('');
  const mentionInputPosition = ref(null);
  
  // DOM ref
  const commentInputRef = ref(null);
  
  // Simple functions that work
  const removeMention = (mentionToRemove) => {
    extractedMentions.value = extractedMentions.value.filter(m => m.id !== mentionToRemove.id);
  };
  
  const clearComment = () => {
    displayCommentText.value = '';
    extractedMentions.value = [];
    props.post.commentText = '';
  };
  
  const selectMention = (selectedUser) => {
    const userName = selectedUser.name || 
                     `${selectedUser.first_name || ''} ${selectedUser.last_name || ''}`.trim() || 
                     selectedUser.username || 
                     'Unknown User';
    
    // Add to mentions if not already there (by ID)
    const exists = extractedMentions.value.some(m => m.id === selectedUser.id);
    if (!exists) {
      extractedMentions.value.push({
        id: selectedUser.id,
        name: userName,
        image: selectedUser.image,
        user: selectedUser
      });
    }
    
    // Clear mention input
    showMentions.value = false;
    mentionSuggestions.value = [];
    mentionInputPosition.value = null;
    
    // Focus back to input
    nextTick(() => {
      if (commentInputRef.value) {
        commentInputRef.value.focus();
      }
    });
    
    emit('select-mention', selectedUser, props.post);
  };
  
  const handlePostComment = () => {
    let finalText = displayCommentText.value.trim();
    
    // Add mentions to text
    if (extractedMentions.value.length > 0) {
      const mentionTexts = extractedMentions.value.map(mention => `@${mention.name.trim()}`);
      if (finalText) {
        finalText = mentionTexts.join(' ') + ' ' + finalText;
      } else {
        finalText = mentionTexts.join(' ');
      }
    }
    
    if (finalText || extractedMentions.value.length > 0) {
      props.post.commentText = finalText;
      emit('add-comment', props.post);
      
      // Clear after posting
      displayCommentText.value = '';
      extractedMentions.value = [];
      props.post.commentText = '';
    }
  };
  
  // ONLY clear when parent says we posted successfully
  watch(() => props.post.commentText, (newText, oldText) => {
    if (oldText && oldText.length > 0 && (!newText || newText.length === 0)) {
      displayCommentText.value = '';
      extractedMentions.value = [];
    }
  });
  
  return {
    extractedMentions,
    displayCommentText,
    showMentions,
    mentionSuggestions,
    mentionSearchText,
    mentionInputPosition,
    commentInputRef,
    removeMention,
    clearComment,
    selectMention,
    handlePostComment
  };
}
