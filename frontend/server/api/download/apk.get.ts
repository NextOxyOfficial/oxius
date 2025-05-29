export default defineEventHandler(async (event) => {
  try {
    // Set proper headers for APK download
    setHeader(event, 'Content-Type', 'application/vnd.android.package-archive')
    setHeader(event, 'Content-Disposition', 'attachment; filename="AdsyClub-V1.apk"')
    setHeader(event, 'Cache-Control', 'public, max-age=31536000') // Cache for 1 year
    
    // Redirect to the direct file in public folder
    // Nuxt will serve it directly from public
    return sendRedirect(event, '/AdsyClub.V.1.apk', 302)
    
  } catch (error) {
    console.error('Error serving APK file:', error)
    throw createError({
      statusCode: 500,
      statusMessage: 'Error serving APK file'
    })
  }
})
