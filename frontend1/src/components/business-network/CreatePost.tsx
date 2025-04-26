import React, { useState, useRef, useEffect, useMemo } from 'react';
import { useRouter } from 'next/router';
import ReactDOM from 'react-dom';
import styles from './CreatePost.module.css';
import { 
  Plus,
  X,
  Smile,
  Image as ImageIcon,
  Hash,
  Loader2,
  AlertCircle,
  Type,
  AlignLeft,
  Send,
  Edit3,
  AlertTriangle,
  Trash2,
  CheckCircle,
  Upload
} from 'lucide-react';
import { useApi } from '@/hooks/useApi'; // Replace with your actual API hook
import { useAuth } from '@/hooks/useAuth'; // Replace with your actual Auth hook
import CommonEditor from '@/components/CommonEditor'; // Replace with your actual editor component

interface CommonEditorProps {
  value: string;
  onChange: (value: string) => void;
  className?: string;
  placeholder?: string;
}

interface CreatePostProps {
  onPostCreated?: (post: any) => void;
}

const CreatePost: React.FC<CreatePostProps> = ({ onPostCreated }) => {
  const router = useRouter();
  const { post, get } = useApi();
  const auth = useAuth();

  // State (equivalent to Vue refs)
  const [isCreatePostOpen, setIsCreatePostOpen] = useState<boolean>(false);
  const [form, setForm] = useState({
    title: "",
    content: "",
  });
  const [images, setImages] = useState<any[]>([]);
  const [createPostCategories, setCreatePostCategories] = useState<string[]>([]);
  const [categoryInput, setCategoryInput] = useState<string>("");
  const [showEmojiPicker, setShowEmojiPicker] = useState<boolean>(false);
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [formError, setFormError] = useState<string>("");
  const [showConfirmClose, setShowConfirmClose] = useState<boolean>(false);
  const [uploadError, setUploadError] = useState<string>("");
  const [isUploading, setIsUploading] = useState<boolean>(false);
  const [showSuccessToast, setShowSuccessToast] = useState<boolean>(false);
  const [isDragging, setIsDragging] = useState<boolean>(false);
  const [showSuggestions, setShowSuggestions] = useState<boolean>(false);
  const [hashtagSuggestions, setHashtagSuggestions] = useState<any[]>([]);
  const [popularHashtags, setPopularHashtags] = useState<any[]>([]);
  const [selectedSuggestionIndex, setSelectedSuggestionIndex] = useState<number>(-1);

  // Refs
  const fileInputRef = useRef<HTMLInputElement>(null);
  const hashtagInputRef = useRef<HTMLInputElement>(null);
  const modalRef = useRef<HTMLDivElement>(null);

  // Computed properties
  const canAddMoreMedia = useMemo(() => images.length < 12, [images]);

  const hasUnsavedChanges = useMemo(() => 
    form.title.trim() !== "" || 
    form.content.trim() !== "" || 
    images.length > 0 || 
    createPostCategories.length > 0,
    [form.title, form.content, images.length, createPostCategories.length]
  );

  // Methods
  const openCreatePostModal = () => {
    setIsCreatePostOpen(true);
    document.body.style.overflow = 'hidden';
    fetchPopularHashtags();
  };

  const closeModalWithConfirm = (e?: React.MouseEvent) => {
    if (e) {
      e.stopPropagation();
    }
    
    if (hasUnsavedChanges) {
      setShowConfirmClose(true);
    } else {
      setIsCreatePostOpen(false);
      document.body.style.overflow = '';
    }
  };

  const discardChanges = () => {
    setShowConfirmClose(false);
    setIsCreatePostOpen(false);
    resetForm();
    document.body.style.overflow = '';
  };

  const resetForm = () => {
    setForm({
      title: "",
      content: "",
    });
    setImages([]);
    setCreatePostCategories([]);
    setCategoryInput("");
    setFormError("");
  };

  const triggerFileInput = () => {
    fileInputRef.current?.click();
  };

  const removeMedia = (index: number) => {
    setImages(images.filter((_, i) => i !== index));
  };

  const clearAllImages = () => {
    setImages([]);
  };

  const updateContent = (content: string) => {
    setForm(prev => ({
      ...prev,
      content
    }));
  };

  // File handling functions
  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    if (!event.target.files || event.target.files.length === 0) return;
    
    const files = Array.from(event.target.files);
    
    if (images.length + files.length > 12) {
      setFormError(`You can only upload up to 12 images (${12 - images.length} remaining)`);
      setTimeout(() => {
        setFormError("");
      }, 3000);
      return;
    }
    
    setIsUploading(true);
    setUploadError("");
    
    try {
      for (const file of files) {
        if (!file.type.startsWith("image/")) {
          continue;
        }
        
        if (file.size > 5 * 1024 * 1024) {
          setUploadError("Some images exceed 5MB and were skipped");
          continue;
        }
        
        await processImage(file);
      }
    } catch (error) {
      console.error("File upload error:", error);
      setUploadError("Error processing some images");
    } finally {
      setIsUploading(false);
      if (event.target) {
        event.target.value = "";
      }
    }
  };

  const handleFileDrop = (event: React.DragEvent) => {
    event.preventDefault();
    setIsDragging(false);
    
    const files = Array.from(event.dataTransfer.files);
    const imageFiles = files.filter(file => file.type.startsWith("image/"));
    
    if (imageFiles.length === 0) return;
    
    if (images.length + imageFiles.length > 12) {
      setFormError(`You can only upload up to 12 images (${12 - images.length} remaining)`);
      setTimeout(() => {
        setFormError("");
      }, 3000);
      return;
    }
    
    setIsUploading(true);
    
    Promise.all(imageFiles.map(file => processImage(file)))
      .catch(error => {
        console.error("File drop error:", error);
        setUploadError("Error processing some images");
      })
      .finally(() => {
        setIsUploading(false);
      });
  };

  const processImage = (file: File): Promise<void> => {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      
      reader.onload = (e) => {
        const img = new Image();
        
        img.onload = () => {
          const canvas = document.createElement("canvas");
          let width = img.width;
          let height = img.height;

          // Resize while maintaining aspect ratio
          const maxSize = 1000;
          if (width > maxSize || height > maxSize) {
            if (width > height) {
              height = height * (maxSize / width);
              width = maxSize;
            } else {
              width = width * (maxSize / height);
              height = maxSize;
            }
          }

          canvas.width = width;
          canvas.height = height;

          const ctx = canvas.getContext("2d");
          if (ctx) {
            ctx.drawImage(img, 0, 0, width, height);
            const compressedDataUrl = canvas.toDataURL("image/jpeg", 0.8);
            
            setTimeout(() => {
              setImages(prevImages => [...prevImages, compressedDataUrl]);
              resolve();
            }, images.length * 100);
          } else {
            reject(new Error("Could not get canvas context"));
          }
        };

        img.onerror = () => {
          reject(new Error("Invalid image"));
        };

        img.src = e.target?.result as string;
      };

      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  };

  // Hashtag management
  const addCategory = () => {
    if (!categoryInput.trim()) return;

    let category = categoryInput.trim();
    if (category.startsWith("#")) {
      category = category.substring(1);
    }

    if (!createPostCategories.includes(category)) {
      setCreatePostCategories(prev => [...prev, category]);
    }

    setCategoryInput("");
    setHashtagSuggestions([]);
    setShowSuggestions(false);
  };

  const removeCategory = (category: string) => {
    setCreatePostCategories(prev => prev.filter(c => c !== category));
  };

  // Hashtag suggestions functions
  const searchHashtags = async () => {
    if (!categoryInput.trim()) {
      setHashtagSuggestions([]);
      setShowSuggestions(popularHashtags.length > 0);
      return;
    }

    try {
      const { data } = await get(`/news/categories/search/?q=${categoryInput.trim()}`);
      
      if (data && Array.isArray(data.results)) {
        setHashtagSuggestions(
          data.results.map((tag: any) => ({
            id: tag.id,
            tag: tag.tag,
            count: tag.posts_count || 0
          })).slice(0, 5)
        );
        setShowSuggestions(true);
      } else {
        setHashtagSuggestions([]);
        setShowSuggestions(popularHashtags.length > 0);
      }
      
      setSelectedSuggestionIndex(-1);
    } catch (error) {
      console.error("Error fetching hashtag suggestions:", error);
      setHashtagSuggestions([]);
      setShowSuggestions(popularHashtags.length > 0);
    }
  };

  const fetchPopularHashtags = async () => {
    try {
      const { data } = await get('/news/categories/popular/?limit=8');
      
      if (data && Array.isArray(data.results)) {
        setPopularHashtags(
          data.results.map((tag: any) => ({
            id: tag.id,
            tag: tag.tag,
            count: tag.posts_count || 0
          }))
        );
      } else if (data && Array.isArray(data)) {
        setPopularHashtags(
          data.map((tag: any) => ({
            id: tag.id || 0,
            tag: tag.tag || tag.name,
            count: tag.posts_count || tag.count || 0
          }))
        );
      }
    } catch (error) {
      console.error("Error fetching popular hashtags:", error);
      setPopularHashtags([]);
    }
  };

  // Hashtag input focus handlers
  const onHashtagInputFocus = () => {
    setShowSuggestions(true);
    if (!categoryInput.trim() && popularHashtags.length === 0) {
      fetchPopularHashtags();
    } else {
      searchHashtags();
    }
  };

  const selectNextSuggestion = () => {
    if (hashtagSuggestions.length === 0) return;
    
    setSelectedSuggestionIndex(prev => 
      prev < hashtagSuggestions.length - 1 ? prev + 1 : 0
    );
  };

  const selectPrevSuggestion = () => {
    if (hashtagSuggestions.length === 0) return;
    
    setSelectedSuggestionIndex(prev => 
      prev > 0 ? prev - 1 : hashtagSuggestions.length - 1
    );
  };

  const selectHashtagSuggestion = (tag: string) => {
    if (tag && !createPostCategories.includes(tag)) {
      setCreatePostCategories(prev => [...prev, tag]);
    }
    
    setCategoryInput("");
    setHashtagSuggestions([]);
    setShowSuggestions(false);
  };

  // Post creation function
  const handleCreatePost = async () => {
    setFormError('');
    setIsSubmitting(true);
    
    try {
      const { data } = await post("/bn/posts/", {
        ...form,
        images,
        tags: createPostCategories,
      });
      
      if (data) {
        resetForm();
        setIsCreatePostOpen(false);
        document.body.style.overflow = '';
        
        setShowSuccessToast(true);
        setTimeout(() => {
          setShowSuccessToast(false);
        }, 5000);
        
        if (onPostCreated) {
          onPostCreated(data);
        }
        
        // Event bus equivalent would go here if needed
        
        const user = auth.user;
        
        if (router.pathname !== `/business-network/profile/${user?.user?.id}`) {
          router.push(`/business-network/profile/${user?.user?.id}`);
        } else {
          setTimeout(() => {
            const newPostElement = document.getElementById(`post-${data.id}`);
            if (newPostElement) {
              newPostElement.scrollIntoView({ behavior: 'smooth', block: 'center' });
              newPostElement.classList.add('highlight-new-post');
            }
          }, 500);
        }
      }
    } catch (error: any) {
      console.error("Error creating post:", error);
      setFormError(error.response?.data?.message || "Failed to create post. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  // Effects
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      const target = event.target as HTMLElement;
      const hashtagInput = target.closest('input[ref="hashtagInputRef"]');
      const suggestionsDropdown = target.closest('.hashtag-suggestions');
      
      if (!hashtagInput && !suggestionsDropdown && showSuggestions) {
        setShowSuggestions(false);
      }
      
      const emojiTrigger = target.closest(".emoji-trigger");
      const emojiPicker = target.closest(".emoji-picker");
      
      if (!emojiTrigger && !emojiPicker && showEmojiPicker) {
        setShowEmojiPicker(false);
      }
    };

    document.addEventListener("click", handleClickOutside);
    return () => document.removeEventListener("click", handleClickOutside);
  }, [showSuggestions, showEmojiPicker]);

  useEffect(() => {
    const handleEscape = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        if (showEmojiPicker) {
          setShowEmojiPicker(false);
        } else if (showSuggestions) {
          setShowSuggestions(false);
        } else if (isCreatePostOpen) {
          closeModalWithConfirm();
        }
      }
    };
    
    document.addEventListener('keydown', handleEscape);
    return () => {
      document.removeEventListener('keydown', handleEscape);
      document.body.style.overflow = '';
    };
  }, [showEmojiPicker, showSuggestions, isCreatePostOpen]);

  useEffect(() => {
    fetchPopularHashtags();
  }, []);

  useEffect(() => {
    if (!categoryInput) {
      const timer = setTimeout(() => {
        setShowSuggestions(false);
      }, 200);
      return () => clearTimeout(timer);
    }
  }, [categoryInput]);

  useEffect(() => {
    // Focus the modal when opened
    if (isCreatePostOpen && modalRef.current) {
      // Set timeout to wait for animation
      const timeout = setTimeout(() => {
        if (modalRef.current) {
          modalRef.current.focus();
        }
      }, 100);
      
      return () => clearTimeout(timeout);
    }
  }, [isCreatePostOpen]);

  // Modal portals (equivalent to Vue's teleport)
  const renderCreatePostModal = () => {
    if (!isCreatePostOpen) return null;

    return typeof window !== 'undefined' && ReactDOM.createPortal(
      <div 
        className="fixed inset-0 z-[9999] bg-black/60 backdrop-blur-sm flex items-center justify-center p-4 transition-opacity duration-300"
        onClick={closeModalWithConfirm}
      >
        <div
          className={`bg-white dark:bg-gray-800 rounded-xl max-w-lg w-full max-h-[90vh] overflow-hidden shadow-2xl
            ${isCreatePostOpen ? 'opacity-100 scale-100 translate-y-0' : 'opacity-0 scale-95 translate-y-4'} 
            transition-all duration-300`}
          onClick={(e) => e.stopPropagation()}
          ref={modalRef}
        >
          {/* Modal Header */}
          <div className="p-4 border-b border-gray-200 dark:border-gray-700 flex items-center justify-between bg-gradient-to-r from-white to-gray-50 dark:from-gray-800 dark:to-gray-900">
            <h2 className="text-xl font-semibold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent flex items-center gap-2">
              <div className="rounded-full bg-gradient-to-r from-blue-600 to-indigo-600 p-1.5 shadow-sm">
                <Edit3 className="h-4 w-4 text-white" />
              </div>
              Create Post
            </h2>
            <button
              className="rounded-full hover:bg-gray-100 dark:hover:bg-gray-700 p-2 transition-colors transform hover:rotate-90 duration-300"
              onClick={closeModalWithConfirm}
            >
              <X className="h-5 w-5 text-gray-500 dark:text-gray-400" />
            </button>
          </div>

          {/* Modal Content */}
          <div className="p-2 pb-6 overflow-y-auto max-h-[calc(90vh-130px)] hide-scrollbar">
            <div className="space-y-5">
              {/* Form Feedback Alert */}
              {formError && (
                <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800/30 rounded-lg p-3 text-red-700 dark:text-red-300 text-sm flex items-start animate-shake">
                  <AlertCircle className="h-5 w-5 mr-2 flex-shrink-0 mt-0.5" />
                  <div>{formError}</div>
                </div>
              )}

              {/* Title Input */}
              <div className="relative group">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5 flex items-center gap-1.5">
                  <Type className="h-4 w-4 text-blue-500" />
                  Post Title<span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <input
                    type="text"
                    placeholder="Write a catchy title..."
                    className="w-full p-3 border border-gray-200 dark:border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-900 dark:text-white transition-all duration-200 pr-16"
                    value={form.title}
                    onChange={(e) => setForm({...form, title: e.target.value})}
                    maxLength={255}
                  />
                  <span 
                    className={`absolute right-3 bottom-3 text-xs px-1.5 py-0.5 rounded-full transition-all duration-200
                      ${form.title.length > 200 ? 'bg-amber-100 text-amber-700' : 'text-gray-400'}`}
                  >
                    {form.title.length}/255
                  </span>
                </div>
              </div>

              {/* Description Textarea */}
              <div className="relative group">
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-1.5 flex items-center gap-1.5">
                  <AlignLeft className="h-4 w-4 text-blue-500" />
                  Description<span className="text-red-500">*</span>
                </label>
                <div className="relative">
                  <CommonEditor
                    value={form.content}
                    onChange={updateContent}
                    className="editor-container"
                    placeholder="Write your post description here..."
                  />
                  <div className="absolute right-2 bottom-2 text-xs bg-white dark:bg-gray-800 px-2 py-1 rounded-full shadow-sm border border-gray-100 dark:border-gray-700">
                    <span className={form.content.length > 5000 ? 'text-amber-500' : 'text-gray-400'}>
                      {form.content.length}
                    </span>
                    <span className="text-gray-400"> characters</span>
                  </div>
                </div>
              </div>

              {/* Media Upload Area */}
              {images.length === 0 && (
                <div 
                  className={`border-2 border-dashed border-gray-300 dark:border-gray-700 rounded-lg p-4 transition-all hover:border-blue-400 dark:hover:border-blue-500 hover:bg-blue-50/50 dark:hover:bg-blue-900/10
                    ${isDragging ? 'bg-blue-50/80 dark:bg-blue-900/20 border-blue-400 dark:border-blue-500' : ''}`}
                  onDragOver={(e) => {
                    e.preventDefault();
                    setIsDragging(true);
                  }}
                  onDragLeave={(e) => {
                    e.preventDefault();
                    setIsDragging(false);
                  }}
                  onDrop={handleFileDrop}
                >
                  <div className="text-center">
                    <div className="mx-auto h-12 w-12 flex items-center justify-center rounded-full bg-blue-100 dark:bg-blue-900/30 mb-3">
                      <ImageIcon className="h-6 w-6 text-blue-600 dark:text-blue-400" />
                    </div>
                    <p className="text-sm font-medium text-gray-700 dark:text-gray-300">
                      {isDragging ? 'Drop your images here' : 'Drag images here or click to select'}
                    </p>
                    <p className="mt-1 text-xs text-gray-500 dark:text-gray-400">
                      Select up to 12 images (PNG, JPG, JPEG)
                    </p>
                    <button 
                      onClick={(e) => {
                        e.stopPropagation();
                        triggerFileInput();
                      }}
                      className="mt-3 px-4 py-1.5 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm transition-all duration-200 hover:shadow-md flex items-center gap-1.5 mx-auto"
                    >
                      <Upload className="h-3.5 w-3.5" />
                      Select Images
                    </button>
                  </div>
                </div>
              )}

              {/* Media Preview */}
              {images.length > 0 && (
                <div className="space-y-3 overflow-hidden">
                  <div className="flex items-center justify-between">
                    <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                      <ImageIcon className="h-4 w-4 text-blue-500" />
                      <span>Selected Media</span>
                    </h4>
                    <div className="flex items-center gap-2">
                      <span 
                        className={`text-xs px-2 py-0.5 rounded-full
                          ${images.length > 9 ? 'bg-amber-100 text-amber-700' : 'bg-gray-100 text-gray-600'}`}
                      >
                        {images.length}/12
                      </span>
                      <button 
                        onClick={clearAllImages} 
                        className="text-xs px-2 py-0.5 text-red-600 hover:bg-red-50 rounded transition-colors"
                      >
                        Clear All
                      </button>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 sm:grid-cols-4 gap-2">
                    {images.map((img, index) => (
                      <div
                        key={index}
                        className="relative aspect-square bg-gray-100 dark:bg-gray-800 rounded-md overflow-hidden media-card group"
                      >
                        {typeof img === 'string' ? (
                          <img
                            src={img}
                            alt={`Selected media ${index + 1}`}
                            className="object-cover w-full h-full"
                          />
                        ) : (
                          <img
                            src={img.data}
                            alt={`Selected media ${index + 1}`}
                            className="object-cover w-full h-full"
                          />
                        )}
                        
                        <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent opacity-0 group-hover:opacity-100 transition-opacity flex items-end p-2">
                          <span className="text-white text-xs truncate w-full">Image {index + 1}</span>
                        </div>
                        
                        <button
                          className="absolute top-1 right-1 bg-black/50 hover:bg-black/70 rounded-full p-1.5 media-delete-btn"
                          onClick={() => removeMedia(index)}
                          aria-label="Remove image"
                        >
                          <X className="h-3 w-3 text-white" />
                        </button>
                      </div>
                    ))}

                    {/* Add More Media Button */}
                    {canAddMoreMedia && (
                      <button
                        onClick={triggerFileInput}
                        className="aspect-square border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-md flex flex-col items-center justify-center hover:bg-gray-50 dark:hover:bg-gray-800 transition-colors hover:border-blue-400 dark:hover:border-blue-500 group"
                      >
                        <div className="p-2 rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-600 dark:text-blue-400 group-hover:scale-125 transition-transform">
                          <Plus className="h-5 w-5" />
                        </div>
                        <span className="text-xs text-gray-500 mt-1 group-hover:text-blue-600 transition-colors">Add More</span>
                      </button>
                    )}
                  </div>
                </div>
              )}

              {/* Hashtags Section */}
              <div className="space-y-2 mb-5">
                <h4 className="text-sm font-medium text-gray-700 dark:text-gray-300 flex items-center gap-1.5">
                  <Hash className="h-4 w-4 text-green-500" />
                  Hashtags (Optional)
                </h4>

                {/* Tags Display */}
                {createPostCategories.length > 0 && (
                  <div className="flex flex-wrap gap-2 mb-3 overflow-hidden">
                    {createPostCategories.map(category => (
                      <span
                        key={category}
                        className="tag-item px-2 py-1 group bg-blue-50 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-sm rounded-full flex items-center transition-all hover:bg-blue-100 dark:hover:bg-blue-900/50 hover:shadow-sm"
                      >
                        #{category}
                        <button
                          onClick={() => removeCategory(category)}
                          className="ml-1 rounded-full hover:bg-blue-200 dark:hover:bg-blue-800 p-0.5 transition-colors"
                          aria-label="Remove hashtag"
                        >
                          <X className="h-3 w-3" />
                        </button>
                      </span>
                    ))}
                  </div>
                )}

                <div className="relative">
                  <div className="flex gap-2">
                    <div className="relative flex-1">
                      <input
                        type="text"
                        ref={hashtagInputRef}
                        placeholder="Add hashtags without # symbol..."
                        value={categoryInput}
                        onChange={(e) => setCategoryInput(e.target.value)}
                        className="pl-8 pr-4 py-2 w-full border border-gray-200 dark:border-gray-700 rounded-md focus:outline-none focus:ring-1 focus:ring-blue-500 bg-white dark:bg-gray-900 dark:text-white"
                        onKeyDown={(e) => {
                          if (e.key === 'Enter') {
                            e.preventDefault();
                            addCategory();
                          } else if (e.key === 'ArrowDown') {
                            e.preventDefault();
                            selectNextSuggestion();
                          } else if (e.key === 'ArrowUp') {
                            e.preventDefault();
                            selectPrevSuggestion();
                          }
                        }}
                        onInput={searchHashtags}
                        onFocus={onHashtagInputFocus}
                      />
                      <Hash className="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-gray-400" />
                      
                      {/* Hashtag Suggestions Dropdown */}
                      {(hashtagSuggestions.length > 0 || popularHashtags.length > 0) && showSuggestions && (
                        <div className="hashtag-suggestions absolute left-0 right-0 top-full mt-1 max-h-48 overflow-y-auto bg-white dark:bg-gray-900 rounded-md border border-gray-200 dark:border-gray-700 shadow-lg z-10 hide-scrollbar">
                          {/* Search results section */}
                          {hashtagSuggestions.length > 0 && (
                            <>
                              <div className="px-3 py-1.5 text-xs text-gray-500 bg-gray-50 dark:bg-gray-800 dark:text-gray-400 border-b border-gray-100 dark:border-gray-700">
                                Search Results
                              </div>
                              {hashtagSuggestions.map((tag, index) => (
                                <div
                                  key={tag.id}
                                  onClick={() => selectHashtagSuggestion(tag.tag)}
                                  className={`px-3 py-2 flex items-center gap-2 cursor-pointer transition-colors
                                    ${selectedSuggestionIndex === index ? 'bg-blue-50 dark:bg-blue-900/20' : 'hover:bg-gray-50 dark:hover:bg-gray-800'}`}
                                >
                                  <Hash className="h-3.5 w-3.5 text-blue-500" />
                                  <span className="text-sm">{tag.tag}</span>
                                  <span className="text-xs text-gray-500 ml-auto">{tag.count} posts</span>
                                </div>
                              ))}
                            </>
                          )}
                          
                          {/* Popular hashtags section */}
                          {popularHashtags.length > 0 && (
                            <>
                              <div className="px-3 py-1.5 text-xs text-gray-500 bg-gray-50 dark:bg-gray-800 dark:text-gray-400 border-b border-gray-100 dark:border-gray-700">
                                Popular Hashtags
                              </div>
                              <div className="flex flex-wrap gap-2 p-3">
                                {popularHashtags.map((tag) => (
                                  <button
                                    key={tag.id}
                                    onClick={() => selectHashtagSuggestion(tag.tag)}
                                    className="px-2 py-1 bg-gray-100 hover:bg-blue-50 dark:bg-gray-800 dark:hover:bg-blue-900/20 rounded-full text-xs text-gray-700 dark:text-gray-300 transition-colors flex items-center gap-1"
                                  >
                                    <Hash className="h-3 w-3 text-blue-500" />
                                    {tag.tag}
                                  </button>
                                ))}
                              </div>
                            </>
                          )}
                        </div>
                      )}
                    </div>
                    <button
                      className="px-3 py-1 bg-blue-600 hover:bg-blue-700 text-white rounded-md text-sm disabled:opacity-50 disabled:cursor-not-allowed transition-colors flex items-center gap-1"
                      onClick={addCategory}
                      disabled={
                        !categoryInput.trim() ||
                        createPostCategories.includes(categoryInput.trim())
                      }
                    >
                      <Plus className="h-3.5 w-3.5" />
                      Add
                    </button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          {/* Footer with Action Buttons */}
          <div className="p-4 border-t border-gray-200 dark:border-gray-700 flex justify-end bg-gradient-to-r from-gray-50 to-white dark:from-gray-900 dark:to-gray-800 sticky bottom-0">
            <button
              className="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-md mr-2 hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-colors hover:shadow-sm"
              onClick={closeModalWithConfirm}
            >
              Cancel
            </button>
            <button
              disabled={!form.title.trim() || !form.content.trim() || isSubmitting}
              onClick={handleCreatePost}
              className={`px-4 py-2 rounded-md text-white transition-all duration-300 flex items-center gap-2 shadow-sm
                ${isSubmitting ? 'bg-indigo-600 cursor-not-allowed' :
                  !form.title.trim() || !form.content.trim() ? 'bg-gray-400 cursor-not-allowed' :
                  'bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 hover:shadow-md'}`}
            >
              {isSubmitting ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
              {isSubmitting ? "Posting..." : "Publish Post"}
            </button>
          </div>

          {/* Hidden file input */}
          <input
            type="file"
            ref={fileInputRef}
            className="hidden"
            multiple
            accept="image/*"
            onChange={handleFileUpload}
          />
        </div>
      </div>,
      document.body
    );
  };

  const renderSuccessToast = () => {
    if (!showSuccessToast) return null;
    
    return typeof window !== 'undefined' && ReactDOM.createPortal(
      <div className="fixed bottom-6 left-1/2 -translate-x-1/2 bg-gradient-to-r from-green-50 to-emerald-50 border border-green-100 shadow-lg rounded-lg px-4 py-3 flex items-center gap-3 z-[10001] min-w-[280px] max-w-sm animate-bounce-once">
        <div className="p-1.5 rounded-full bg-gradient-to-r from-green-500 to-emerald-500 text-white shadow-sm">
          <CheckCircle className="h-5 w-5" />
        </div>
        <div>
          <p className="font-medium text-green-800">Post published!</p>
          <p className="text-sm text-green-600">Your post was successfully created</p>
        </div>
        <button 
          className="ml-auto p-1 text-green-700 hover:bg-green-100 rounded-full"
          onClick={() => setShowSuccessToast(false)}
          aria-label="Close notification"
        >
          <X className="h-4 w-4" />
        </button>
      </div>,
      document.body
    );
  };

  const renderConfirmModal = () => {
    if (!showConfirmClose) return null;
    
    return typeof window !== 'undefined' && ReactDOM.createPortal(
      <div
        className="fixed inset-0 z-[10000] bg-black/70 backdrop-blur-sm flex items-center justify-center p-4"
        onClick={() => setShowConfirmClose(false)}
      >
        <div
          className="bg-white dark:bg-gray-800 rounded-xl max-w-md w-full p-6 shadow-2xl"
          onClick={(e) => e.stopPropagation()}
        >
          <div className="flex items-start mb-4">
            <div className="p-2 bg-amber-100 dark:bg-amber-900/30 rounded-full mr-3">
              <AlertTriangle className="h-5 w-5 text-amber-600 dark:text-amber-500" />  
            </div>
            <div>
              <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                Discard changes?
              </h3>
              <p className="text-gray-600 dark:text-gray-300 mt-1.5">
                You have unsaved changes. Are you sure you want to discard your
                post?
              </p>
            </div>
          </div>
          <div className="flex justify-end gap-3 mt-6">
            <button
              className="px-4 py-2 border border-gray-200 dark:border-gray-700 rounded-md hover:bg-gray-50 dark:hover:bg-gray-800 text-gray-700 dark:text-gray-300 transition-colors"
              onClick={() => setShowConfirmClose(false)}
            >
              Keep Editing
            </button>
            <button
              className="px-4 py-2 bg-red-600 hover:bg-red-700 text-white rounded-md transition-colors flex items-center gap-1.5"
              onClick={discardChanges}
            >
              <Trash2 className="h-4 w-4" />
              Discard
            </button>
          </div>
        </div>
      </div>,
      document.body
    );
  };

  const renderEmojiPicker = () => {
    if (!showEmojiPicker) return null;
    
    // Simple emoji list for demonstration
    const emojis = ["😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍"];
    
    return (
      <div className="emoji-picker absolute bottom-full right-0 mb-2 bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700 rounded-lg shadow-lg p-2 z-10">
        <div className="grid grid-cols-5 gap-2">
          {emojis.map((emoji, index) => (
            <button
              key={index}
              className="w-8 h-8 flex items-center justify-center hover:bg-gray-100 dark:hover:bg-gray-700 rounded transition-colors"
              onClick={() => handleEmojiClick(emoji)}
            >
              {emoji}
            </button>
          ))}
        </div>
      </div>
    );
  };

  const handleEmojiClick = (emoji: string) => {
    setForm(prev => ({
      ...prev,
      content: prev.content + emoji
    }));
    setShowEmojiPicker(false);
  };

  return (
    <div>
      {/* Create Post Button */}
      <button
        className="fixed bottom-24 right-4 lg:right-[22%] md:bottom-4 rounded-full h-14 w-14 shadow-lg bg-gradient-to-r from-blue-600 to-indigo-700 hover:from-blue-700 hover:to-indigo-800 transition-all duration-300 hover:scale-105 border-none z-40 flex items-center justify-center text-white group"
        onClick={openCreatePostModal}
      >
        <Plus className="h-6 w-6 group-hover:rotate-90 transition-transform duration-300" />
        <span className="absolute opacity-0 group-hover:opacity-100 right-16 bg-gray-900 text-white text-xs px-2 py-1 rounded whitespace-nowrap transition-opacity duration-200">Create Post</span>
      </button>

      {/* Render Portals */}
      {renderCreatePostModal()}
      {renderSuccessToast()}
      {renderConfirmModal()}
      {renderEmojiPicker()}
    </div>
  );
};

export default CreatePost;

