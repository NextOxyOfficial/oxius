from django import template
from django.utils.safestring import mark_safe

register = template.Library()

@register.simple_tag
def popup_scripts():
    """Include popup JavaScript and initialize the popup system"""
    return mark_safe('''
    <script src="/static/js/popup-manager.js"></script>
    <script>
        // Initialize popup manager when DOM is ready
        document.addEventListener('DOMContentLoaded', function() {
            if (typeof PopupManager !== 'undefined') {
                new PopupManager();
            }
        });
    </script>
    ''')

@register.simple_tag
def popup_css():
    """Include popup CSS styles"""
    return mark_safe('''
    <style>
        /* Popup system styles are included in popup-manager.js */
        /* You can add additional custom styles here if needed */
    </style>
    ''')
