import { joinURL } from 'ufo'
import type { ProviderGetImage } from '@nuxt/image'

export const getImage: ProviderGetImage = (
  src,
  { modifiers = {}, baseURL } = {}
) => {
  const { width, height, fit, format, quality } = modifiers

  // Handle absolute URLs (external images)
  if (src.startsWith('http://') || src.startsWith('https://')) {
    return {
      url: src
    }
  }

  // Handle Django media URLs
  if (src.startsWith('/media/')) {
    const url = joinURL(baseURL || '', src)
    return {
      url
    }
  }

  // Handle static frontend assets
  if (src.startsWith('/static/')) {
    const url = joinURL(baseURL || '', src)
    return {
      url
    }
  }

  // Default: treat as media path
  const url = joinURL(baseURL || '', src.startsWith('/') ? src : `/media/${src}`)
  
  return {
    url
  }
}
