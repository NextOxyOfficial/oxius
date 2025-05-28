// Session management composable for e-learning access control
import { ref, computed, onMounted, onUnmounted, readonly } from 'vue'
import { useApi } from '~/composables/useApi'

interface SessionData {
  id: string
  status: string
  is_pro_user: boolean
  remaining_time: number | null
  session_viewing_time: number
  total_viewing_time: number
}

interface DeviceFingerprint {
  screen: string
  timezone: string
  language: string
  platform: string
  cookieEnabled: boolean
  doNotTrack: string | null
  userAgent: string
}

interface SessionResponse {
  success?: boolean
  session?: SessionData
  session_viewing_time?: number
  total_viewing_time?: number
  remaining_time?: number
  error_code?: string
  message?: string
}

export const useELearningSession = () => {
  const { $fetch } = useNuxtApp()
  const { get, post } = useApi()
  
  const session = ref<SessionData | null>(null)
  const isSessionActive = ref(false)
  const timeRemaining = ref<number | null>(null)
  const heartbeatInterval = ref<number | null>(null)
  const viewingTimeInterval = ref<number | null>(null)
  const currentVideoId = ref<string | null>(null)
  const currentSubjectId = ref<string | null>(null)

  // Device fingerprinting
  const generateDeviceFingerprint = (): DeviceFingerprint => {
    return {
      screen: `${screen.width}x${screen.height}`,
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      language: navigator.language,
      platform: navigator.platform,
      cookieEnabled: navigator.cookieEnabled,
      doNotTrack: navigator.doNotTrack,
      userAgent: navigator.userAgent
    }
  }

  const hashFingerprint = async (fingerprint: DeviceFingerprint): Promise<string> => {
    const text = JSON.stringify(fingerprint)
    const encoder = new TextEncoder()
    const data = encoder.encode(text)
    const hash = await crypto.subtle.digest('SHA-256', data)
    return Array.from(new Uint8Array(hash))
      .map(b => b.toString(16).padStart(2, '0'))
      .join('')
  }  // Session management
  const startSession = async (pageUrl: string, subjectId?: string): Promise<boolean> => {
    try {
      const fingerprint = generateDeviceFingerprint()
      const deviceHash = await hashFingerprint(fingerprint)

      const response = await post('/elearning/sessions/start/', {
        page_url: pageUrl,
        subject_id: subjectId,
        device_fingerprint: deviceHash,
        device_info: fingerprint
      })

      const responseData = response.data as SessionResponse

      if (responseData?.success) {
        session.value = responseData.session!
        isSessionActive.value = true
        timeRemaining.value = responseData.session!.remaining_time
        currentSubjectId.value = subjectId || null
        
        // Start heartbeat and viewing time tracking
        startHeartbeat()
        return true
      } else {
        // Handle specific error cases
        if (responseData?.error_code === 'CONCURRENT_SESSION') {
          throw new Error('Another session is already active. Please close other tabs/devices.')
        } else if (responseData?.error_code === 'TIME_LIMIT_EXCEEDED') {
          throw new Error('Daily viewing time limit reached. Please upgrade to Pro.')
        }
        throw new Error(responseData?.message || 'Failed to start session')
      }
    } catch (error) {
      console.error('Failed to start session:', error)
      throw error
    }
  }
  
  const endSession = async (): Promise<void> => {
    try {
      if (session.value) {
        await post('/elearning/sessions/end/', {
          session_id: session.value.id
        })
      }
    } catch (error) {
      console.error('Failed to end session:', error)
    } finally {
      cleanup()
    }
  }
  
  const checkSessionStatus = async (): Promise<void> => {
    try {
      if (!session.value) return

      const response = await get(`/elearning/sessions/status/?session_id=${session.value.id}`)
      const responseData = response.data as SessionResponse

      if (responseData?.session) {
        session.value = responseData.session
        timeRemaining.value = responseData.session.remaining_time
        isSessionActive.value = responseData.session.status === 'active'
      } else {
        cleanup()
      }
    } catch (error) {
      console.error('Failed to check session status:', error)
      cleanup()
    }
  }
  
  const trackActivity = async (action: string, details?: any): Promise<void> => {
    try {
      if (!session.value) return

      await post('/elearning/sessions/track-activity/', {
        session_id: session.value.id,
        action,
        details: details || {}
      })
    } catch (error) {
      console.error('Failed to track activity:', error)
    }
  }
    const trackViewingTime = async (seconds: number): Promise<boolean> => {
    try {
      if (!session.value) return false

      const response = await post('/elearning/sessions/track-viewing-time/', {
        session_id: session.value.id,
        seconds
      })

      const responseData = response.data as SessionResponse

      if (responseData?.success) {
        session.value.session_viewing_time = responseData.session_viewing_time!
        session.value.total_viewing_time = responseData.total_viewing_time!
        timeRemaining.value = responseData.remaining_time!
        return true
      } else {
        // Time limit reached
        if (responseData?.error_code === 'TIME_LIMIT_EXCEEDED') {
          cleanup()
          throw new Error('Viewing time limit reached. Please upgrade to Pro for unlimited access.')
        }
        return false
      }
    } catch (error) {
      console.error('Failed to track viewing time:', error)
      throw error
    }
  }

  // Video tracking
  const startVideoTracking = (videoId: string): void => {
    currentVideoId.value = videoId
    trackActivity('video_start', { video_id: videoId })
    
    // Track viewing time every 5 seconds
    if (viewingTimeInterval.value) {
      clearInterval(viewingTimeInterval.value)
    }
    
    viewingTimeInterval.value = setInterval(async () => {
      try {
        await trackViewingTime(5)
      } catch (error) {
        // Stop tracking if there's an error (e.g., time limit reached)
        stopVideoTracking()
        throw error
      }
    }, 5000)
  }

  const pauseVideoTracking = (): void => {
    if (viewingTimeInterval.value) {
      clearInterval(viewingTimeInterval.value)
      viewingTimeInterval.value = null
    }
    trackActivity('video_pause', { video_id: currentVideoId.value })
  }

  const resumeVideoTracking = (): void => {
    if (!viewingTimeInterval.value && currentVideoId.value) {
      startVideoTracking(currentVideoId.value)
      trackActivity('video_resume', { video_id: currentVideoId.value })
    }
  }

  const stopVideoTracking = (): void => {
    if (viewingTimeInterval.value) {
      clearInterval(viewingTimeInterval.value)
      viewingTimeInterval.value = null
    }
    if (currentVideoId.value) {
      trackActivity('video_end', { video_id: currentVideoId.value })
      currentVideoId.value = null
    }
  }
  // Heartbeat to keep session alive
  const startHeartbeat = (): void => {
    if (heartbeatInterval.value) {
      clearInterval(heartbeatInterval.value)
    }
    
    heartbeatInterval.value = setInterval(async () => {
      try {
        await post('/elearning/sessions/heartbeat/', {
          session_id: session.value?.id
        })
      } catch (error) {
        console.error('Heartbeat failed:', error)
        cleanup()
      }
    }, 30000) // Every 30 seconds
  }

  const cleanup = (): void => {
    session.value = null
    isSessionActive.value = false
    timeRemaining.value = null
    currentVideoId.value = null
    currentSubjectId.value = null
    
    if (heartbeatInterval.value) {
      clearInterval(heartbeatInterval.value)
      heartbeatInterval.value = null
    }
    
    if (viewingTimeInterval.value) {
      clearInterval(viewingTimeInterval.value)
      viewingTimeInterval.value = null
    }
  }

  // Computed properties
  const isProUser = computed(() => session.value?.is_pro_user || false)
  const hasTimeLimit = computed(() => !isProUser.value)
  const timeRemainingFormatted = computed(() => {
    if (timeRemaining.value === null) return null
    const minutes = Math.floor(timeRemaining.value / 60)
    const seconds = timeRemaining.value % 60
    return `${minutes}:${seconds.toString().padStart(2, '0')}`
  })
  // Lifecycle
  onMounted(() => {
    // Check for existing session on page load - only on client side
    if (typeof window !== 'undefined') {
      checkSessionStatus()
    }
  })

  onUnmounted(() => {
    cleanup()
  })

  // Handle page visibility changes
  const handleVisibilityChange = (): void => {
    if (document.hidden && isSessionActive.value) {
      pauseVideoTracking()
    } else if (!document.hidden && isSessionActive.value && currentVideoId.value) {
      resumeVideoTracking()
    }
  }

  if (typeof window !== 'undefined') {
    document.addEventListener('visibilitychange', handleVisibilityChange)
  }

  return {
    // State
    session: readonly(session),
    isSessionActive: readonly(isSessionActive),
    timeRemaining: readonly(timeRemaining),
    currentVideoId: readonly(currentVideoId),
    currentSubjectId: readonly(currentSubjectId),
    
    // Computed
    isProUser,
    hasTimeLimit,
    timeRemainingFormatted,
    
    // Methods
    startSession,
    endSession,
    checkSessionStatus,
    trackActivity,
    trackViewingTime,
    startVideoTracking,
    pauseVideoTracking,
    resumeVideoTracking,
    stopVideoTracking
  }
}
