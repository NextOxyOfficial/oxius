/**
 * Enhanced Popup Management System
 * Handles loading and displaying popups with advanced close functionality
 */

class PopupManager {
  constructor() {
    this.popups = [];
    this.currentPopupIndex = 0;
    this.baseUrl = "/api/popups";
    this.activeTimers = new Map(); // Track active timers for cleanup
    this.init();
  }

  async init() {
    await this.loadPopups();
    this.showNextPopup();
  }

  async loadPopups() {
    try {
      const response = await fetch(`${this.baseUrl}/api/get-popups/`);
      const data = await response.json();
      this.popups = data.popups || [];
    } catch (error) {
      console.error("Error loading popups:", error);
    }
  }

  showNextPopup() {
    if (this.currentPopupIndex < this.popups.length) {
      const popup = this.popups[this.currentPopupIndex];
      this.displayPopup(popup);
      this.currentPopupIndex++;
    }
  }

  displayPopup(popup) {
    // Create popup overlay
    const overlay = document.createElement("div");
    overlay.className = "popup-overlay";
    overlay.id = `popup-${popup.id}`;

    // Add click-to-close functionality if enabled
    if (popup.close_on_overlay_click) {
      overlay.addEventListener("click", (e) => {
        if (e.target === overlay) {
          this.closePopup(popup.id, "overlay_click");
        }
      });
    }

    // Create popup container
    const container = document.createElement("div");
    container.className = "popup-container";
    container.style.width = `${popup.width}px`;
    container.style.maxHeight = `${popup.height}px`;
    container.style.backgroundColor = popup.background_color;
    container.style.color = popup.text_color;

    // Create close button (only if enabled)
    let closeBtn = null;
    if (popup.show_close_button) {
      closeBtn = document.createElement("button");
      closeBtn.className = "popup-close";
      closeBtn.innerHTML = "&times;";
      closeBtn.onclick = () => this.closePopup(popup.id, "manual");
      closeBtn.setAttribute("aria-label", "Close popup");

      // Add keyboard support
      closeBtn.addEventListener("keydown", (e) => {
        if (e.key === "Enter" || e.key === " ") {
          e.preventDefault();
          this.closePopup(popup.id, "manual");
        }
      });
    }

    // Create content based on popup type
    let content = "";

    if (popup.popup_type === "image" && popup.image_url) {
      content = `<img src="${popup.image_url}" alt="${popup.title}" class="popup-image">`;
    } else if (popup.popup_type === "text" && popup.text_content) {
      content = `<div class="popup-text">${popup.text_content}</div>`;
    } else if (popup.popup_type === "mixed") {
      content = "";
      if (popup.image_url) {
        content += `<img src="${popup.image_url}" alt="${popup.title}" class="popup-image">`;
      }
      if (popup.text_content) {
        content += `<div class="popup-text">${popup.text_content}</div>`;
      }
    } // Add link if provided
    if (popup.link_url && popup.link_text) {
      const linkTarget = this.getLinkTarget(popup.link_navigation);
      const linkAttributes = this.getLinkAttributes(popup.link_navigation);

      content += `<div class="popup-actions">
                <a href="${popup.link_url}" class="popup-link" ${linkAttributes}>${popup.link_text}</a>
            </div>`;
    }

    container.innerHTML = `
            <div class="popup-header">
                <h3 class="popup-title">${popup.title}</h3>
            </div>
            <div class="popup-content">
                ${content}
            </div>
        `;

    // Add close button if enabled
    if (closeBtn) {
      container.appendChild(closeBtn);
    }

    // Add countdown timer container if auto-close is enabled
    if (popup.auto_close_enabled && popup.auto_close_delay > 0) {
      const timerContainer = document.createElement("div");
      timerContainer.className = "popup-timer";
      timerContainer.id = `timer-${popup.id}`;
      container.appendChild(timerContainer);
    }

    overlay.appendChild(container);
    document.body.appendChild(overlay);

    // Add CSS styles
    this.addPopupStyles();

    // Add ESC key support
    const escHandler = (e) => {
      if (e.key === "Escape") {
        this.closePopup(popup.id, "escape_key");
        document.removeEventListener("keydown", escHandler);
      }
    };
    document.addEventListener("keydown", escHandler);

    // Show popup with delay
    const showTimer = setTimeout(() => {
      overlay.classList.add("show");
      this.recordPopupView(popup.id);

      // Start auto-close timer if enabled
      if (popup.auto_close_enabled && popup.auto_close_delay > 0) {
        this.startAutoCloseTimer(popup.id, popup.auto_close_delay);
      }
    }, popup.delay_seconds * 1000);

    // Store timer for cleanup
    this.activeTimers.set(`show-${popup.id}`, showTimer);
  }

  startAutoCloseTimer(popupId, delay) {
    const timerElement = document.getElementById(`timer-${popupId}`);
    let timeLeft = delay;

    const updateTimer = () => {
      if (timerElement) {
        timerElement.innerHTML = `
                    <div class="auto-close-timer">
                        <span class="timer-text">Auto-closing in ${timeLeft}s</span>
                        <div class="timer-progress">
                            <div class="timer-bar" style="width: ${
                              (timeLeft / delay) * 100
                            }%"></div>
                        </div>
                    </div>
                `;
      }

      timeLeft--;

      if (timeLeft >= 0) {
        const timerId = setTimeout(updateTimer, 1000);
        this.activeTimers.set(`timer-${popupId}`, timerId);
      } else {
        this.closePopup(popupId, "auto_close");
      }
    };

    updateTimer();
  }

  closePopup(popupId, reason = "unknown") {
    console.log(`Closing popup ${popupId} due to: ${reason}`);

    // Clear any active timers for this popup
    this.clearPopupTimers(popupId);

    const overlay = document.getElementById(`popup-${popupId}`);
    if (overlay) {
      overlay.classList.remove("show");
      setTimeout(() => {
        overlay.remove();
        this.showNextPopup();

        // Record close event (optional)
        this.recordPopupClose(popupId, reason);
      }, 300);
    }
  }

  clearPopupTimers(popupId) {
    // Clear show timer
    const showTimer = this.activeTimers.get(`show-${popupId}`);
    if (showTimer) {
      clearTimeout(showTimer);
      this.activeTimers.delete(`show-${popupId}`);
    }

    // Clear countdown timer
    const countdownTimer = this.activeTimers.get(`timer-${popupId}`);
    if (countdownTimer) {
      clearTimeout(countdownTimer);
      this.activeTimers.delete(`timer-${popupId}`);
    }
  }

  async recordPopupView(popupId) {
    try {
      await fetch(`${this.baseUrl}/api/record-view/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ popup_id: popupId }),
      });
    } catch (error) {
      console.error("Error recording popup view:", error);
    }
  }

  async recordPopupClose(popupId, reason) {
    try {
      await fetch(`${this.baseUrl}/api/record-close/`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          popup_id: popupId,
          close_reason: reason,
        }),
      });
    } catch (error) {
      console.error("Error recording popup close:", error);
    }
  }

  addPopupStyles() {
    if (!document.getElementById("popup-styles")) {
      const style = document.createElement("style");
      style.id = "popup-styles";
      style.textContent = `
                .popup-overlay {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    background-color: rgba(0, 0, 0, 0.7);
                    display: flex;
                    justify-content: center;
                    align-items: center;
                    z-index: 10000;
                    opacity: 0;
                    visibility: hidden;
                    transition: all 0.3s ease;
                }

                .popup-overlay.show {
                    opacity: 1;
                    visibility: visible;
                }

                .popup-container {
                    position: relative;
                    background: white;
                    border-radius: 12px;
                    box-shadow: 0 10px 30px rgba(0, 0, 0, 0.3);
                    max-width: 90vw;
                    max-height: 90vh;
                    overflow: hidden;
                    transform: scale(0.8);
                    transition: transform 0.3s ease;
                }

                .popup-overlay.show .popup-container {
                    transform: scale(1);
                }

                .popup-close {
                    position: absolute;
                    top: 15px;
                    right: 15px;
                    background: rgba(0, 0, 0, 0.5);
                    color: white;
                    border: none;
                    border-radius: 50%;
                    width: 30px;
                    height: 30px;
                    font-size: 18px;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    z-index: 10001;
                    transition: background-color 0.3s ease;
                }

                .popup-close:hover,
                .popup-close:focus {
                    background: rgba(0, 0, 0, 0.8);
                    outline: none;
                }

                .popup-header {
                    padding: 20px 20px 0;
                }

                .popup-title {
                    margin: 0;
                    font-size: 1.5rem;
                    font-weight: bold;
                }

                .popup-content {
                    padding: 20px;
                    overflow-y: auto;
                    max-height: calc(90vh - 100px);
                }

                .popup-image {
                    width: 100%;
                    height: auto;
                    border-radius: 8px;
                    margin-bottom: 15px;
                }

                .popup-text {
                    line-height: 1.6;
                    margin-bottom: 15px;
                }

                .popup-actions {
                    text-align: center;
                    margin-top: 20px;
                }

                .popup-link {
                    display: inline-block;
                    background: #007bff;
                    color: white;
                    padding: 12px 24px;
                    text-decoration: none;
                    border-radius: 6px;
                    font-weight: bold;
                    transition: background-color 0.3s ease;
                }

                .popup-link:hover {
                    background: #0056b3;
                    color: white;
                }

                .popup-timer {
                    position: absolute;
                    bottom: 0;
                    left: 0;
                    right: 0;
                    padding: 10px;
                    background: rgba(0, 0, 0, 0.05);
                    border-top: 1px solid rgba(0, 0, 0, 0.1);
                }

                .auto-close-timer {
                    text-align: center;
                }

                .timer-text {
                    font-size: 12px;
                    color: #666;
                    margin-bottom: 5px;
                    display: block;
                }

                .timer-progress {
                    height: 4px;
                    background: rgba(0, 0, 0, 0.1);
                    border-radius: 2px;
                    overflow: hidden;
                }

                .timer-bar {
                    height: 100%;
                    background: #007bff;
                    transition: width 1s linear;
                }

                @media (max-width: 768px) {
                    .popup-container {
                        width: 95% !important;
                        margin: 20px;
                    }
                    
                    .popup-title {
                        font-size: 1.25rem;
                    }
                    
                    .popup-content {
                        padding: 15px;
                    }
                    
                    .popup-close {
                        top: 10px;
                        right: 10px;
                        width: 25px;
                        height: 25px;
                        font-size: 16px;
                    }
                }
            `;
      document.head.appendChild(style);
    }
  }

  getLinkTarget(navigation) {
    switch (navigation) {
      case "external":
        return "_blank";
      case "new_tab":
        return "_blank";
      case "internal":
      default:
        return "_self";
    }
  }

  getLinkAttributes(navigation) {
    switch (navigation) {
      case "external":
        return 'target="_blank" rel="noopener noreferrer" data-external="true"';
      case "new_tab":
        return 'target="_blank" rel="noopener noreferrer"';
      case "internal":
      default:
        return 'target="_self"';
    }
  }

  handleLinkClick(url, navigation, event) {
    if (navigation === "external") {
      // For external links, we might want to open in system browser
      // This is more relevant for mobile apps/PWAs
      event.preventDefault();
      if (window.open) {
        window.open(url, "_blank", "noopener,noreferrer");
      } else {
        window.location.href = url;
      }
    }
    // For 'internal' and 'new_tab', let the browser handle normally
  }

  // Cleanup method to clear all timers
  destroy() {
    this.activeTimers.forEach((timer) => {
      clearTimeout(timer);
    });
    this.activeTimers.clear();
  }
}

// Initialize popup manager when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  window.popupManager = new PopupManager();
});

// Cleanup on page unload
window.addEventListener("beforeunload", () => {
  if (window.popupManager) {
    window.popupManager.destroy();
  }
});

// Export for manual initialization if needed
window.PopupManager = PopupManager;
