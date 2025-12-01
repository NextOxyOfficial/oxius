from django.contrib import admin
from django.utils.html import format_html, mark_safe
from django.urls import reverse
from django.utils import timezone
from .models import (
    Gig, GigReview, GigFavorite, GigOrder, OrderMessage, GigOrderTransaction,
    GigCategory, GigSkill, GigDeliveryTime, GigRevisionOption,
    WorkspaceBanner, GigFeeSettings
)


# ============================================
# Gig Options Admin (Categories, Skills, etc.)
# ============================================

@admin.register(GigCategory)
class GigCategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'icon', 'is_active', 'order', 'skills_count', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('name', 'slug', 'description')
    prepopulated_fields = {'slug': ('name',)}
    list_editable = ('is_active', 'order')
    ordering = ('order', 'name')
    
    def skills_count(self, obj):
        count = obj.skills.count()
        return format_html('<span style="color: blue;">{}</span>', count)
    skills_count.short_description = 'Skills'


@admin.register(GigSkill)
class GigSkillAdmin(admin.ModelAdmin):
    list_display = ('name', 'slug', 'category', 'is_active', 'created_at')
    list_filter = ('is_active', 'category')
    search_fields = ('name', 'slug')
    prepopulated_fields = {'slug': ('name',)}
    list_editable = ('is_active',)
    ordering = ('name',)
    autocomplete_fields = ['category']


@admin.register(GigDeliveryTime)
class GigDeliveryTimeAdmin(admin.ModelAdmin):
    list_display = ('label', 'days', 'is_active', 'order')
    list_filter = ('is_active',)
    list_editable = ('is_active', 'order')
    ordering = ('order', 'days')


@admin.register(GigRevisionOption)
class GigRevisionOptionAdmin(admin.ModelAdmin):
    list_display = ('label', 'count', 'is_active', 'order')
    list_filter = ('is_active',)
    list_editable = ('is_active', 'order')
    ordering = ('order', 'count')


# ============================================
# Main Gig Admin
# ============================================

@admin.register(Gig)
class GigAdmin(admin.ModelAdmin):
    list_display = ('title', 'user', 'category', 'price', 'status', 'views_count', 'orders_count', 'created_at')
    list_filter = ('category', 'status', 'is_featured', 'created_at')
    search_fields = ('title', 'description', 'user__first_name', 'user__last_name', 'user__email')
    readonly_fields = ('id', 'views_count', 'orders_count', 'created_at', 'updated_at')
    ordering = ('-created_at',)


@admin.register(GigReview)
class GigReviewAdmin(admin.ModelAdmin):
    list_display = ('gig', 'user', 'rating', 'created_at')
    list_filter = ('rating', 'created_at')
    search_fields = ('gig__title', 'user__first_name', 'user__last_name', 'comment')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


@admin.register(GigFavorite)
class GigFavoriteAdmin(admin.ModelAdmin):
    list_display = ('gig', 'user', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('gig__title', 'user__first_name', 'user__last_name')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)


@admin.register(GigOrder)
class GigOrderAdmin(admin.ModelAdmin):
    list_display = ('order_id_short', 'gig_title', 'buyer_info', 'seller_info', 'price_display', 'status_badge', 'message_count', 'created_at')
    list_filter = ('status', 'created_at')
    search_fields = ('id', 'gig__title', 'buyer__first_name', 'buyer__last_name', 'buyer__email', 'seller__first_name', 'seller__last_name')
    readonly_fields = ('id', 'order_summary', 'chat_history', 'created_at', 'updated_at')
    ordering = ('-created_at',)
    list_per_page = 25
    
    fieldsets = (
        ('📋 Order Summary', {
            'fields': ('order_summary',),
            'classes': ('wide',),
        }),
        ('⚙️ Order Status', {
            'fields': ('status',),
        }),
        ('💬 Chat History', {
            'fields': ('chat_history',),
            'classes': ('wide', 'collapse'),
            'description': 'Click to expand and view the complete conversation between buyer and seller.'
        }),
    )
    
    def order_id_short(self, obj):
        return format_html(
            '<code style="background: #e8e8e8; padding: 4px 8px; border-radius: 4px; font-family: monospace;">{}</code>',
            str(obj.id)[:8].upper()
        )
    order_id_short.short_description = 'Order ID'
    
    def gig_title(self, obj):
        title = obj.gig.title[:35] + '...' if len(obj.gig.title) > 35 else obj.gig.title
        return format_html('<span title="{}">{}</span>', obj.gig.title, title)
    gig_title.short_description = 'Gig'
    
    def buyer_info(self, obj):
        return format_html(
            '<div style="line-height: 1.4;"><strong>{}</strong><br><small style="color: #666;">{}</small></div>',
            f"{obj.buyer.first_name} {obj.buyer.last_name}",
            obj.buyer.email
        )
    buyer_info.short_description = 'Buyer'
    
    def seller_info(self, obj):
        return format_html(
            '<div style="line-height: 1.4;"><strong>{}</strong><br><small style="color: #666;">{}</small></div>',
            f"{obj.seller.first_name} {obj.seller.last_name}",
            obj.seller.email
        )
    seller_info.short_description = 'Seller'
    
    def price_display(self, obj):
        return format_html(
            '<span style="font-weight: bold; color: #2e7d32;">৳{}</span>',
            obj.price
        )
    price_display.short_description = 'Amount'
    
    def status_badge(self, obj):
        colors = {
            'pending': ('#ff9800', '#fff'),
            'in_progress': ('#2196f3', '#fff'),
            'delivered': ('#9c27b0', '#fff'),
            'completed': ('#4caf50', '#fff'),
            'cancelled': ('#f44336', '#fff'),
            'revision': ('#ff5722', '#fff'),
        }
        bg, fg = colors.get(obj.status, ('#grey', '#000'))
        return format_html(
            '<span style="background: {}; color: {}; padding: 4px 10px; border-radius: 12px; font-size: 11px; font-weight: bold; text-transform: uppercase;">{}</span>',
            bg, fg, obj.status.replace('_', ' ')
        )
    status_badge.short_description = 'Status'
    
    def message_count(self, obj):
        count = obj.messages.count()
        if count > 0:
            return format_html(
                '<span style="background: #4caf50; color: white; padding: 4px 12px; border-radius: 12px; font-weight: bold;">{} 💬</span>',
                count
            )
        return format_html('<span style="color: #999;">No messages</span>')
    message_count.short_description = 'Messages'
    
    def order_summary(self, obj):
        """Display order details in a card format"""
        delivery_date = obj.delivery_date.strftime("%b %d, %Y") if obj.delivery_date else "Not set"
        completed_at = obj.completed_at.strftime("%b %d, %Y %I:%M %p") if obj.completed_at else "Not completed"
        created_at = obj.created_at.strftime("%b %d, %Y %I:%M %p")
        
        return format_html(
            '''
            <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); padding: 20px; border-radius: 12px; color: white; margin-bottom: 10px;">
                <h2 style="margin: 0 0 5px 0; font-size: 18px;">🛒 {gig_title}</h2>
                <p style="margin: 0; opacity: 0.9; font-size: 13px;">Order ID: {order_id}</p>
            </div>
            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 15px; padding: 15px; background: #f8f9fa; border-radius: 8px;">
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <div style="font-size: 11px; color: #666; text-transform: uppercase; margin-bottom: 5px;">👤 Buyer</div>
                    <div style="font-weight: bold; color: #333;">{buyer_name}</div>
                    <div style="font-size: 12px; color: #666;">{buyer_email}</div>
                </div>
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <div style="font-size: 11px; color: #666; text-transform: uppercase; margin-bottom: 5px;">🏪 Seller</div>
                    <div style="font-weight: bold; color: #333;">{seller_name}</div>
                    <div style="font-size: 12px; color: #666;">{seller_email}</div>
                </div>
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <div style="font-size: 11px; color: #666; text-transform: uppercase; margin-bottom: 5px;">💰 Amount</div>
                    <div style="font-weight: bold; color: #2e7d32; font-size: 24px;">৳{price}</div>
                </div>
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <div style="font-size: 11px; color: #666; text-transform: uppercase; margin-bottom: 5px;">💬 Messages</div>
                    <div style="font-weight: bold; color: #333; font-size: 24px;">{message_count}</div>
                </div>
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <div style="font-size: 11px; color: #666; text-transform: uppercase; margin-bottom: 5px;">📅 Created</div>
                    <div style="font-weight: bold; color: #333;">{created_at}</div>
                </div>
                <div style="background: white; padding: 15px; border-radius: 8px; box-shadow: 0 1px 3px rgba(0,0,0,0.1);">
                    <div style="font-size: 11px; color: #666; text-transform: uppercase; margin-bottom: 5px;">🚚 Delivery Date</div>
                    <div style="font-weight: bold; color: #333;">{delivery_date}</div>
                </div>
            </div>
            ''',
            gig_title=obj.gig.title,
            order_id=str(obj.id)[:8].upper(),
            buyer_name=f"{obj.buyer.first_name} {obj.buyer.last_name}",
            buyer_email=obj.buyer.email,
            seller_name=f"{obj.seller.first_name} {obj.seller.last_name}",
            seller_email=obj.seller.email,
            price=obj.price,
            message_count=obj.messages.count(),
            created_at=created_at,
            delivery_date=delivery_date
        )
    order_summary.short_description = ''
    
    def chat_history(self, obj):
        """Display full conversation in chat bubble format"""
        messages = obj.messages.all().order_by('created_at')
        
        if not messages:
            return format_html(
                '''
                <div style="padding: 60px 40px; text-align: center; background: #fafafa; border-radius: 12px; border: 2px dashed #ddd;">
                    <div style="font-size: 48px; margin-bottom: 15px;">💬</div>
                    <div style="color: #666; font-size: 16px;">No messages in this conversation yet.</div>
                </div>
                '''
            )
        
        html = '''
        <div style="background: #f5f5f5; border-radius: 12px; overflow: hidden;">
            <div style="background: #1a1a2e; color: white; padding: 15px 20px; display: flex; justify-content: space-between; align-items: center;">
                <div>
                    <strong>💬 Conversation</strong>
                    <span style="margin-left: 10px; background: rgba(255,255,255,0.2); padding: 2px 10px; border-radius: 10px; font-size: 12px;">{} messages</span>
                </div>
                <div style="font-size: 12px; opacity: 0.8;">
                    {} ↔ {}
                </div>
            </div>
            <div style="max-height: 500px; overflow-y: auto; padding: 20px;">
        '''.format(
            messages.count(),
            f"{obj.buyer.first_name}",
            f"{obj.seller.first_name}"
        )
        
        current_date = None
        for msg in messages:
            # Date separator
            msg_date = msg.created_at.strftime("%B %d, %Y")
            if msg_date != current_date:
                current_date = msg_date
                html += f'''
                <div style="text-align: center; margin: 20px 0;">
                    <span style="background: #e0e0e0; padding: 6px 16px; border-radius: 20px; font-size: 12px; color: #555; font-weight: 500;">
                        {msg_date}
                    </span>
                </div>
                '''
            
            sender_name = f"{msg.sender.first_name} {msg.sender.last_name}" if msg.sender else "System"
            is_buyer = msg.sender == obj.buyer if msg.sender else False
            is_system = msg.sender is None
            
            # Bubble styling
            if is_system:
                html += f'''
                <div style="text-align: center; margin: 15px 0;">
                    <div style="display: inline-block; background: #fff3e0; border: 1px solid #ffcc80; padding: 10px 20px; border-radius: 8px; font-size: 13px; color: #e65100;">
                        ⚡ {msg.content}
                    </div>
                </div>
                '''
                continue
            
            if is_buyer:
                align = "flex-start"
                bubble_bg = "#ffffff"
                border_color = "#2196f3"
                avatar_bg = "#2196f3"
                label = "BUYER"
            else:
                align = "flex-end"
                bubble_bg = "#e8f5e9"
                border_color = "#4caf50"
                avatar_bg = "#4caf50"
                label = "SELLER"
            
            # Message content
            content_html = ""
            if msg.media:
                if msg.message_type == 'image':
                    content_html += f'''
                    <div style="margin-bottom: 8px;">
                        <a href="{msg.media.url}" target="_blank">
                            <img src="{msg.media.url}" style="max-width: 280px; max-height: 200px; border-radius: 8px; cursor: pointer; border: 1px solid #eee;" />
                        </a>
                    </div>
                    '''
                elif msg.message_type == 'video':
                    content_html += f'''
                    <div style="margin-bottom: 8px;">
                        <video src="{msg.media.url}" controls style="max-width: 280px; border-radius: 8px;"></video>
                    </div>
                    '''
                elif msg.message_type == 'document':
                    file_size = f" ({msg.file_size // 1024} KB)" if msg.file_size else ""
                    content_html += f'''
                    <div style="margin-bottom: 8px; padding: 12px; background: rgba(0,0,0,0.05); border-radius: 8px; display: flex; align-items: center; gap: 10px;">
                        <span style="font-size: 24px;">📎</span>
                        <a href="{msg.media.url}" target="_blank" style="color: #1976d2; text-decoration: none; font-weight: 500;">
                            {msg.file_name or "Document"}{file_size}
                        </a>
                    </div>
                    '''
            
            if msg.content:
                escaped_content = msg.content.replace('<', '&lt;').replace('>', '&gt;').replace('\n', '<br>')
                content_html += f'<div style="white-space: pre-wrap; word-break: break-word; line-height: 1.5;">{escaped_content}</div>'
            
            time_str = msg.created_at.strftime("%I:%M %p")
            initial = sender_name[0].upper() if sender_name else "?"
            
            html += f'''
            <div style="display: flex; justify-content: {align}; margin-bottom: 16px;">
                <div style="display: flex; gap: 10px; max-width: 75%; {"flex-direction: row-reverse;" if not is_buyer else ""}">
                    <div style="width: 36px; height: 36px; border-radius: 50%; background: {avatar_bg}; color: white; display: flex; align-items: center; justify-content: center; font-weight: bold; font-size: 14px; flex-shrink: 0;">
                        {initial}
                    </div>
                    <div style="background: {bubble_bg}; border-left: 4px solid {border_color}; padding: 12px 16px; border-radius: 12px; box-shadow: 0 1px 2px rgba(0,0,0,0.1);">
                        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; gap: 15px;">
                            <span style="font-weight: 600; color: #333; font-size: 13px;">{sender_name}</span>
                            <span style="font-size: 9px; padding: 2px 8px; border-radius: 10px; background: {avatar_bg}; color: white; text-transform: uppercase; font-weight: bold;">{label}</span>
                        </div>
                        <div style="color: #333; font-size: 14px;">{content_html}</div>
                        <div style="text-align: right; margin-top: 8px; font-size: 11px; color: #888;">
                            {time_str} {"✓✓" if msg.is_read else "✓"}
                        </div>
                    </div>
                </div>
            </div>
            '''
        
        html += '''
            </div>
        </div>
        <div style="margin-top: 15px; padding: 15px; background: #fff3e0; border-radius: 8px; border-left: 4px solid #ff9800;">
            <strong>⚠️ Moderation Guidelines:</strong>
            <ul style="margin: 10px 0 0 20px; color: #666; font-size: 13px;">
                <li>Check for sharing of personal contact information (phone, email, social media)</li>
                <li>Look for inappropriate or offensive content</li>
                <li>Identify potential scam attempts or fraud</li>
                <li>Verify compliance with platform terms & conditions</li>
            </ul>
        </div>
        '''
        
        return mark_safe(html)
    chat_history.short_description = ''


# Note: OrderMessage is intentionally not registered as a separate admin model.
# All messages are viewed through the GigOrder detail page for better context.


@admin.register(GigOrderTransaction)
class GigOrderTransactionAdmin(admin.ModelAdmin):
    list_display = ('transaction_id', 'order_link', 'user_info', 'amount_display', 'transaction_type_badge', 'status_badge', 'created_at')
    list_filter = ('transaction_type', 'status', 'created_at')
    search_fields = ('id', 'order__id', 'user__first_name', 'user__last_name', 'user__email', 'description')
    readonly_fields = ('id', 'created_at')
    ordering = ('-created_at',)
    list_per_page = 50
    
    def transaction_id(self, obj):
        return format_html(
            '<code style="background: #f0f0f0; padding: 2px 6px; border-radius: 4px; font-size: 11px;">{}</code>',
            str(obj.id)[:8].upper()
        )
    transaction_id.short_description = 'ID'
    
    def order_link(self, obj):
        url = reverse('admin:workspace_gigorder_change', args=[obj.order.id])
        return format_html(
            '<a href="{}" style="color: #1976d2;">Order #{}</a>',
            url, str(obj.order.id)[:8].upper()
        )
    order_link.short_description = 'Order'
    
    def user_info(self, obj):
        return format_html(
            '<div><strong>{}</strong><br><small style="color: #666;">{}</small></div>',
            f"{obj.user.first_name} {obj.user.last_name}",
            obj.user.email
        )
    user_info.short_description = 'User'
    
    def amount_display(self, obj):
        color = '#4caf50' if obj.transaction_type in ['release', 'refund'] else '#333'
        prefix = '+' if obj.transaction_type in ['release', 'refund'] else '-' if obj.transaction_type == 'payment' else ''
        return format_html(
            '<span style="font-weight: bold; color: {};">{}৳{}</span>',
            color, prefix, obj.amount
        )
    amount_display.short_description = 'Amount'
    
    def transaction_type_badge(self, obj):
        colors = {
            'payment': '#2196f3',
            'refund': '#ff9800',
            'release': '#4caf50',
            'hold': '#9c27b0',
        }
        icons = {
            'payment': '💳',
            'refund': '↩️',
            'release': '✅',
            'hold': '🔒',
        }
        color = colors.get(obj.transaction_type, '#666')
        icon = icons.get(obj.transaction_type, '')
        return format_html(
            '<span style="background: {}; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">{} {}</span>',
            color, icon, obj.transaction_type.upper()
        )
    transaction_type_badge.short_description = 'Type'
    
    def status_badge(self, obj):
        colors = {
            'pending': '#ff9800',
            'completed': '#4caf50',
            'failed': '#f44336',
            'refunded': '#9c27b0',
        }
        color = colors.get(obj.status, '#666')
        return format_html(
            '<span style="background: {}; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">{}</span>',
            color, obj.status.upper()
        )
    status_badge.short_description = 'Status'


@admin.register(WorkspaceBanner)
class WorkspaceBannerAdmin(admin.ModelAdmin):
    list_display = ('banner_preview', 'title', 'link_type', 'status_badge', 'order', 'schedule_info', 'created_at')
    list_filter = ('is_active', 'link_type')
    search_fields = ('title', 'link', 'internal_path')
    list_editable = ('order',)
    ordering = ('order', '-created_at')
    
    fieldsets = (
        ('Banner Info', {
            'fields': ('title', 'image')
        }),
        ('Link Settings', {
            'fields': ('link_type', 'link', 'internal_path'),
            'description': 'Configure where the banner navigates to when clicked'
        }),
        ('Display Settings', {
            'fields': ('is_active', 'order')
        }),
        ('Schedule', {
            'fields': ('starts_at', 'ends_at'),
            'classes': ('collapse',),
            'description': 'Leave empty to show always'
        }),
    )
    
    def banner_preview(self, obj):
        if obj.image:
            return format_html(
                '<img src="{}" style="height: 50px; width: auto; border-radius: 4px; object-fit: cover;" />',
                obj.image.url
            )
        return '-'
    banner_preview.short_description = 'Preview'
    
    def status_badge(self, obj):
        if obj.is_currently_active:
            return format_html(
                '<span style="background: #4caf50; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">Active</span>'
            )
        elif not obj.is_active:
            return format_html(
                '<span style="background: #9e9e9e; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">Disabled</span>'
            )
        else:
            return format_html(
                '<span style="background: #ff9800; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">Scheduled</span>'
            )
    status_badge.short_description = 'Status'
    
    def schedule_info(self, obj):
        if obj.starts_at or obj.ends_at:
            start = obj.starts_at.strftime('%b %d, %Y') if obj.starts_at else 'Now'
            end = obj.ends_at.strftime('%b %d, %Y') if obj.ends_at else 'Forever'
            return f"{start} → {end}"
        return 'Always'
    schedule_info.short_description = 'Schedule'


# ============================================
# Gig Fee Settings Admin (Singleton)
# ============================================

@admin.register(GigFeeSettings)
class GigFeeSettingsAdmin(admin.ModelAdmin):
    """Admin for managing gig order fees - singleton model"""
    
    list_display = (
        'buyer_fees_display', 'seller_fees_display', 
        'buyer_fee_status', 'seller_discount_status', 'updated_at'
    )
    
    fieldsets = (
        ('Buyer Fees (Order Placement)', {
            'description': 'Fees charged to buyers when placing an order',
            'fields': (
                'buyer_fee_waived',
                ('buyer_service_fee_percent', 'buyer_processing_fee'),
                ('buyer_service_fee_min', 'buyer_service_fee_max'),
            )
        }),
        ('Seller Fees (Order Completion)', {
            'description': 'Platform commission deducted from seller earnings',
            'fields': (
                'seller_commission_percent',
                ('seller_commission_min', 'seller_commission_max'),
                'seller_fee_discount_percent',
                'seller_withdrawal_fee',
            )
        }),
        ('Metadata', {
            'classes': ('collapse',),
            'fields': ('updated_at', 'updated_by'),
        }),
    )
    
    readonly_fields = ('updated_at',)
    
    def has_add_permission(self, request):
        """Only allow one instance"""
        return not GigFeeSettings.objects.exists()
    
    def has_delete_permission(self, request, obj=None):
        """Prevent deletion"""
        return False
    
    def buyer_fees_display(self, obj):
        if obj.buyer_fee_waived:
            return format_html(
                '<span style="color: #4caf50; font-weight: bold;">FREE (Waived)</span>'
            )
        return format_html(
            '<span style="font-weight: bold;">{}%</span> + ৳{} processing',
            obj.buyer_service_fee_percent, obj.buyer_processing_fee
        )
    buyer_fees_display.short_description = 'Buyer Fees'
    
    def seller_fees_display(self, obj):
        return format_html(
            '<span style="font-weight: bold; color: #f44336;">{}%</span> commission',
            obj.seller_commission_percent
        )
    seller_fees_display.short_description = 'Seller Commission'
    
    def buyer_fee_status(self, obj):
        if obj.buyer_fee_waived:
            return format_html(
                '<span style="background: #4caf50; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">WAIVED</span>'
            )
        return format_html(
            '<span style="background: #2196f3; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">ACTIVE</span>'
        )
    buyer_fee_status.short_description = 'Buyer Fee Status'
    
    def seller_discount_status(self, obj):
        if obj.seller_fee_discount_percent > 0:
            return format_html(
                '<span style="background: #ff9800; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">{}% OFF</span>',
                obj.seller_fee_discount_percent
            )
        return format_html(
            '<span style="background: #9e9e9e; color: white; padding: 3px 10px; border-radius: 12px; font-size: 11px;">No Discount</span>'
        )
    seller_discount_status.short_description = 'Seller Discount'
    
    def save_model(self, request, obj, form, change):
        obj.updated_by = request.user
        super().save_model(request, obj, form, change)
    
    def changelist_view(self, request, extra_context=None):
        """Redirect to the single instance edit page"""
        obj = GigFeeSettings.get_settings()
        return self.changeform_view(request, str(obj.pk), extra_context=extra_context)
