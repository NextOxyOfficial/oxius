export function useUtils() {
    const formatDate = (date: Date | string) => {
      const parsedDate = new Date(date); // Convert string to Date object if needed
  
      if (isNaN(parsedDate.getTime())) {
        console.error("Invalid date:", date);
        return "Invalid Date";
      }
  
      var seconds = Math.floor((new Date().getTime() - parsedDate.getTime()) / 1000);
      var interval = seconds / 31536000;
  
      if (interval > 1) {
        return Math.floor(interval) + " years ago";
      }
      interval = seconds / 2592000;
      if (interval > 1) {
        return Math.floor(interval) + " months ago";
      }
      interval = seconds / 86400;
      if (interval > 1) {
        return Math.floor(interval) + " days ago";
      }
      interval = seconds / 3600;
      if (interval > 1) {
        return Math.floor(interval) + " hours ago";
      }
      interval = seconds / 60;
      if (interval > 1) {
        return Math.floor(interval) + " minutes ago";
      }
      return Math.floor(seconds) + " seconds ago";
    };
  
    return {
      formatDate,
    };
  }