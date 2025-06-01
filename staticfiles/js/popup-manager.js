/**
 * Popup Management System
 * Handles loading and displaying popups from Django backend
 */

class PopupManager {
  constructor() {
    this.popups = [];
    this.currentPopupIndex = 0;
    this.baseUrl = "/api/popups";
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

    // Create popup container
    const container = document.createElement("div");
    container.className = "popup-container";
    container.style.width = `${popup.width}px`;
    container.style.maxHeight = `${popup.height}px`;
    container.style.backgroundColor = popup.background_color;
    container.style.color = popup.text_color;

    // Create close button
    const closeBtn = document.createElement("button");
    closeBtn.className = "popup-close";
    closeBtn.innerHTML = "&times;";
    closeBtn.onclick = () => this.closePopup(popup.id);

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
    }

    // Add link if provided
    if (popup.link_url && popup.link_text) {
      content += `<div class="popup-actions">
                <a href="${popup.link_url}" class="popup-link" target="_blank">${popup.link_text}</a>
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

    container.appendChild(closeBtn);
    overlay.appendChild(container);
    document.body.appendChild(overlay);

    // Add CSS styles
    this.addPopupStyles();

    // Show popup with delay
    setTimeout(() => {
      overlay.classList.add("show");
      this.recordPopupView(popup.id);
    }, popup.delay_seconds * 1000);

    // Auto-close after 10 seconds if no interaction
    setTimeout(() => {
      if (document.getElementById(`popup-${popup.id}`)) {
        this.closePopup(popup.id);
      }
    }, 10000 + popup.delay_seconds * 1000);
  }

  closePopup(popupId) {
    const overlay = document.getElementById(`popup-${popupId}`);
    if (overlay) {
      overlay.classList.remove("show");
      setTimeout(() => {
        overlay.remove();
        this.showNextPopup();
      }, 300);
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

                .popup-close:hover {
                    background: rgba(0, 0, 0, 0.8);
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
                }
            `;
      document.head.appendChild(style);
    }
  }
}

// Initialize popup manager when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  new PopupManager();
});

// Export for manual initialization if needed
window.PopupManager = PopupManager;
