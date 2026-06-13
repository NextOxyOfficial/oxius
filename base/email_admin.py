"""
Email Settings Admin Panel
Allow admin to configure SMTP settings from Django admin
"""
from django.contrib import admin
from django import forms
from django.conf import settings
from django.contrib import messages
from django.utils.safestring import mark_safe
from django.http import HttpResponseRedirect
from django.urls import reverse
from .models import EmailSettings


class RevealablePasswordInput(forms.PasswordInput):
    """Masked password field (shows dots, never plain text on the page) whose
    stored value is preserved on save (render_value=True, so editing other fields
    won't wipe the password). A small "Show" checkbox lets an admin reveal it when
    they actually need to read it."""

    def __init__(self, attrs=None, render_value=True):
        super().__init__(attrs=attrs, render_value=render_value)

    def render(self, name, value, attrs=None, renderer=None):
        attrs = dict(attrs or {})
        field_id = attrs.get("id") or f"id_{name}"
        attrs["id"] = field_id
        html = super().render(name, value, attrs, renderer)
        toggle = (
            f'<label style="display:inline-block;margin-left:10px;font-weight:normal;cursor:pointer;color:#555;">'
            f'<input type="checkbox" style="vertical-align:middle;" '
            f"onclick=\"var f=document.getElementById('{field_id}');"
            f"f.type=this.checked?'text':'password';\"> Show</label>"
        )
        return mark_safe(html + toggle)


class EmailSettingsAdminForm(forms.ModelForm):
    """Form for email settings configuration"""

    class Meta:
        model = EmailSettings
        fields = '__all__'
        widgets = {
            'email_host': forms.TextInput(attrs={'class': 'vTextField', 'style': 'width: 300px;'}),
            'email_port': forms.NumberInput(attrs={'class': 'vIntegerField', 'style': 'width: 100px;'}),
            'email_host_user': forms.EmailInput(attrs={'class': 'vTextField', 'style': 'width: 300px;'}),
            'email_host_password': RevealablePasswordInput(attrs={'class': 'vTextField', 'style': 'width: 300px;'}),
            'from_email': forms.EmailInput(attrs={'class': 'vTextField', 'style': 'width: 300px;'}),
            'admin_email': forms.EmailInput(attrs={'class': 'vTextField', 'style': 'width: 300px;'}),
        }
    
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.fields['email_host_password'].help_text = "Use Gmail App Password for Gmail accounts"
        self.fields['email_host'].help_text = "e.g., smtp.gmail.com, smtp.office365.com"
        self.fields['email_port'].help_text = "Common ports: 587 (TLS), 465 (SSL), 25 (no encryption)"


@admin.register(EmailSettings)
class EmailSettingsAdmin(admin.ModelAdmin):
    """Admin interface for email settings"""

    form = EmailSettingsAdminForm  # masks the password (PasswordInput + Show toggle)

    list_display = ('email_host', 'email_port', 'email_host_user', 'from_email', 'is_active', 'updated_at')
    list_filter = ('is_active', 'email_host', 'email_port')
    search_fields = ('email_host', 'email_host_user', 'from_email', 'admin_email')
    actions = ['send_test_email']
    
    readonly_fields = ('created_at', 'updated_at')
    
    fieldsets = (
        ('SMTP Configuration', {
            'fields': ('email_host', 'email_port', 'email_use_tls', 'is_active'),
            'description': mark_safe(
                'Configure SMTP server settings. '
                'For Gmail, use <a href="https://myaccount.google.com/apppasswords" target="_blank">App Passwords</a> '
                'instead of your regular password.'
            )
        }),
        ('Authentication', {
            'fields': ('email_host_user', 'email_host_password'),
            'description': 'SMTP server credentials. Password is stored encrypted in database.'
        }),
        ('Email Addresses', {
            'fields': ('from_email', 'admin_email'),
            'description': 'Default sender and admin notification email addresses.'
        }),
        ('System Information', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',)
        }),
    )
    
    def save_model(self, request, obj, form, change):
        """Override save to show message about settings application"""
        super().save_model(request, obj, form, change)
        messages.success(
            request, 
            'Email settings saved successfully! '
            'Note: These settings are stored in the database and will be used for email sending. '
            'If you want to use environment variables instead, set EMAIL_* variables in your .env file.'
        )
    
    def get_readonly_fields(self, request, obj=None):
        readonly = list(self.readonly_fields)
        if obj and obj.pk:  # If editing existing object
            readonly.append('email_host')  # Don't allow changing host after creation
        return readonly
    
    def send_test_email(self, request, queryset):
        """Send test email action"""
        if queryset.count() != 1:
            messages.error(request, 'Please select exactly one email setting to test.')
            return HttpResponseRedirect(reverse('admin:base_emailsettings_changelist'))
        
        email_setting = queryset.first()
        if not email_setting.is_active:
            messages.error(request, 'Email setting must be active to send test email.')
            return HttpResponseRedirect(reverse('admin:base_emailsettings_changelist'))
        
        try:
            from .email_service import send_test_email
            success = send_test_email(email_setting.admin_email or email_setting.email_host_user)
            
            if success:
                messages.success(
                    request, 
                    f'✅ Test email sent successfully to {email_setting.admin_email or email_setting.email_host_user}!'
                )
            else:
                messages.error(
                    request, 
                    '❌ Failed to send test email. Please check your SMTP configuration.'
                )
        except Exception as e:
            messages.error(request, f'❌ Error sending test email: {str(e)}')
        
        return HttpResponseRedirect(reverse('admin:base_emailsettings_changelist'))
    
    send_test_email.short_description = 'Send test email'


# ---------------------------------------------------------------------------
# Email template preview (see what reaches the customer + tune the design)
# ---------------------------------------------------------------------------
from django.http import HttpResponse
from django.shortcuts import render
from django.urls import path

from .email_preview import (
    email_template_choices,
    render_email_preview,
    send_test_email_for,
)
from .models import EmailTemplatePreview


@admin.register(EmailTemplatePreview)
class EmailTemplatePreviewAdmin(admin.ModelAdmin):
    """Preview-only page: pick an email template from the dropdown and see the
    exact HTML the customer receives, rendered live below."""
    change_list_template = "admin/email_template_preview.html"

    def has_add_permission(self, request):
        return False

    def has_delete_permission(self, request, obj=None):
        return False

    def has_change_permission(self, request, obj=None):
        return True

    def get_urls(self):
        urls = [
            path(
                "raw-preview/",
                self.admin_site.admin_view(self.raw_preview),
                name="email-template-raw",
            ),
        ]
        return urls + super().get_urls()

    def changelist_view(self, request, extra_context=None):
        choices = email_template_choices()
        selected = (
            request.POST.get("template")
            or request.GET.get("template")
            or (choices[0][0] if choices else "")
        )

        # Handle "Send test" — render the selected template and email it out.
        if request.method == "POST" and "send_test" in request.POST:
            from django.http import HttpResponseRedirect
            test_email = (request.POST.get("test_email") or "").strip()
            if not test_email:
                self.message_user(
                    request, "Enter an email address to send the test to.",
                    level=messages.ERROR,
                )
            else:
                try:
                    ok = send_test_email_for(selected, test_email)
                    if ok:
                        self.message_user(
                            request,
                            f"✅ Test '{selected}' email sent to {test_email}.",
                            level=messages.SUCCESS,
                        )
                    else:
                        self.message_user(
                            request,
                            "❌ Could not send. Check Email Settings (SMTP) in the admin.",
                            level=messages.ERROR,
                        )
                except Exception as e:
                    self.message_user(
                        request, f"❌ Error sending test: {e}", level=messages.ERROR,
                    )
            return HttpResponseRedirect(f"?template={selected}")

        subject = ""
        if selected:
            subject, _ = render_email_preview(selected)
        context = {
            **self.admin_site.each_context(request),
            "title": "Email templates",
            "templates": choices,
            "selected": selected,
            "subject": subject,
            "default_test_email": getattr(request.user, "email", "") or "",
        }
        return render(request, self.change_list_template, context)

    def raw_preview(self, request):
        """Returns the rendered email HTML for use inside the preview iframe."""
        key = request.GET.get("template", "")
        _, html = render_email_preview(key)
        resp = HttpResponse(html)
        # Allow this response to be framed by the (same-origin) admin preview
        # page — Django defaults X-Frame-Options to DENY, which blocks the iframe.
        resp["X-Frame-Options"] = "SAMEORIGIN"
        return resp


from .models import AdminEmailRecipient


@admin.register(AdminEmailRecipient)
class AdminEmailRecipientAdmin(admin.ModelAdmin):
    """Extra admin-notification recipients (managers, assistant managers...).

    Every admin notification (new user, recharge, withdrawal, KYC, moderation
    approval requests, block reports) is sent to the primary admin email in
    Email Settings PLUS all active addresses listed here."""

    list_display = ('email', 'label', 'is_active', 'created_at')
    list_editable = ('is_active',)
    list_filter = ('is_active',)
    search_fields = ('email', 'label')
    ordering = ('email',)


from .models import EmailSuppression, ValidEmail


@admin.register(EmailSuppression)
class EmailSuppressionAdmin(admin.ModelAdmin):
    """The email BLACKLIST — invalid/bounced + unsubscribed addresses that the
    whole email system skips. Filter by "reason" to see each list (invalid vs
    unsubscribed); change the reason inline (then Save) or use the actions to move
    between them; "Move to VALID" (or delete a row) re-allows sending. Add a row
    manually to block any address."""
    list_display = ("email", "reason", "note", "created_at")
    list_filter = ("reason",)
    list_editable = ("reason",)
    search_fields = ("email", "note")
    ordering = ("-created_at",)
    actions = ["mark_invalid", "mark_unsubscribed", "move_to_valid"]

    def mark_invalid(self, request, queryset):
        n = queryset.update(reason="invalid")
        self.message_user(request, f"{n} address(es) marked INVALID.", level=messages.WARNING)
    mark_invalid.short_description = "Mark selected as INVALID"

    def mark_unsubscribed(self, request, queryset):
        n = queryset.update(reason="unsubscribed")
        self.message_user(request, f"{n} address(es) marked UNSUBSCRIBED.", level=messages.WARNING)
    mark_unsubscribed.short_description = "Mark selected as UNSUBSCRIBED"

    def move_to_valid(self, request, queryset):
        n = queryset.count()
        queryset.delete()
        self.message_user(
            request, f"{n} address(es) moved back to VALID (sending re-allowed).",
            level=messages.SUCCESS,
        )
    move_to_valid.short_description = "Move selected to VALID (re-allow sending)"


@admin.register(ValidEmail)
class ValidEmailAdmin(admin.ModelAdmin):
    """Active, deliverable user emails — NOT on the suppression blacklist. The
    email system sends only to these. Use the actions to move an address to
    invalid / unsubscribed (which immediately stops sending to it)."""
    list_display = ("email", "name", "date_joined", "last_login")
    search_fields = ("email", "name", "first_name", "last_name")
    ordering = ("-date_joined",)
    actions = ["move_to_invalid", "move_to_unsubscribed"]

    def get_queryset(self, request):
        from django.db.models.functions import Lower
        qs = (
            super().get_queryset(request)
            .filter(is_active=True)
            .exclude(email="")
            .exclude(email__isnull=True)
        )
        blocked = set(EmailSuppression.objects.values_list("email", flat=True))
        return qs.alias(_em=Lower("email")).exclude(_em__in=blocked)

    def has_add_permission(self, request):
        return False  # "valid" = an existing user not blocked; nothing to add here

    def _block(self, request, queryset, reason, label):
        from .email_service import suppress_email
        n = 0
        for u in queryset:
            if (u.email or "").strip():
                suppress_email(u.email, reason=reason, note="manually moved from Valid Emails admin")
                n += 1
        self.message_user(request, f"{n} address(es) moved to {label}.", level=messages.WARNING)

    def move_to_invalid(self, request, queryset):
        self._block(request, queryset, "invalid", "INVALID (sending stopped)")
    move_to_invalid.short_description = "Move selected to INVALID (stop sending)"

    def move_to_unsubscribed(self, request, queryset):
        self._block(request, queryset, "unsubscribed", "UNSUBSCRIBED")
    move_to_unsubscribed.short_description = "Move selected to UNSUBSCRIBED"
