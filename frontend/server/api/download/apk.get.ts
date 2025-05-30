
// Google Drive URL for the APK file
const GOOGLE_DRIVE_APK_URL = 'https://drive.usercontent.google.com/download?id=1pqqxQbxXjkuWfBWeZLELTq8yno2Aq35o&export=download&authuser=0'

export default defineEventHandler(async (event) => {
  try {
    // Just redirect to the Google Drive download URL (for backward compatibility)
    return sendRedirect(event, GOOGLE_DRIVE_APK_URL, 302)
  } catch (error) {
    console.error('Error redirecting to APK file:', error)
    throw createError({
      statusCode: 500,
      statusMessage: 'Error redirecting to APK file'
    })
  }
})
