"""
AdsyClub Email Service
Professional email templates with white/light gray theme.
All transactional emails for users and admin notifications.
"""
import logging
from django.core.mail import send_mail, EmailMultiAlternatives, get_connection
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)

ADMIN_EMAIL = "alimulislam50@gmail.com"
SITE_NAME = "AdsyClub"
SITE_URL = "https://adsyclub.com"
# Match the AdsyConnect chat header (blue -> indigo -> violet).
BRAND_COLOR = "#6366F1"          # indigo (solid uses: links, button fallback)
BRAND_COLOR_DARK = "#8B5CF6"     # violet
BRAND_GRADIENT = "linear-gradient(135deg,#3B82F6,#6366F1,#8B5CF6)"
BRAND_GRADIENT_BAR = "linear-gradient(90deg,#3B82F6,#6366F1,#8B5CF6)"
BRAND_SHADOW = "rgba(99,102,241,0.32)"


def _logo_url():
    """The current AdsyClub brand logo (as shown on the site), with a stable
    static fallback so emails always render a logo even if the DB is unreachable."""
    try:
        from .models import Logo
        logo = Logo.objects.first()
        if logo and logo.image:
            url = logo.image.url
            return url if url.startswith("http") else SITE_URL + url
    except Exception:
        pass
    return f"{SITE_URL}/static/frontend/images/logo.png"


def _base_template(title, body_content, footer_note=""):
    """Base HTML email — international-grade layout: brand accent, AdsyClub logo
    header, clean body and a professional multi-link footer. Built with tables +
    inline styles for maximum email-client compatibility."""
    logo = _logo_url()
    year = timezone.now().year

    note_html = ""
    if footer_note:
        note_html = f"""<tr><td style="padding:0 36px 28px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f8fafc;border-radius:10px;">
<tr><td style="padding:14px 18px;"><p style="margin:0;color:#64748b;font-size:13px;line-height:1.55;">{footer_note}</p></td></tr>
</table></td></tr>"""

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="x-apple-disable-message-reformatting">
<title>{title}</title>
</head>
<body style="margin:0;padding:0;background-color:#eef1f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;-webkit-font-smoothing:antialiased;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#eef1f5;padding:32px 14px;">
<tr><td align="center">
<table role="presentation" width="600" cellspacing="0" cellpadding="0" style="width:600px;max-width:600px;background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(15,23,42,0.08);">

<!-- Brand accent -->
<tr><td style="height:5px;background:{BRAND_GRADIENT_BAR};font-size:0;line-height:0;">&nbsp;</td></tr>

<!-- Logo header -->
<tr>
<td style="padding:30px 32px 22px;text-align:center;background-color:#ffffff;border-bottom:1px solid #eef1f5;">
<img src="{logo}" alt="{SITE_NAME}" height="42" style="height:42px;width:auto;border:0;display:inline-block;outline:none;text-decoration:none;">
<div style="margin:10px 0 0;color:#94a3b8;font-size:11px;letter-spacing:2px;text-transform:uppercase;font-weight:600;">Social Business Network</div>
</td>
</tr>

<!-- Title -->
<tr>
<td style="padding:28px 36px 0;">
<h2 style="margin:0;color:#0f172a;font-size:21px;font-weight:700;letter-spacing:-0.2px;">{title}</h2>
</td>
</tr>

<!-- Body -->
<tr>
<td style="padding:18px 36px 30px;">
{body_content}
</td>
</tr>

{note_html}

<!-- Footer -->
<tr>
<td style="background-color:#f8fafc;padding:30px 32px;border-top:1px solid #e8edf3;text-align:center;">
<div style="margin:0 0 4px;color:#0f172a;font-size:16px;font-weight:800;letter-spacing:-0.2px;">{SITE_NAME}</div>
<div style="margin:0 0 16px;color:#94a3b8;font-size:12px;">Bangladesh's Social Business Network</div>
<div style="margin:0 0 16px;">
<a href="{SITE_URL}" style="color:{BRAND_COLOR_DARK};text-decoration:none;font-size:12px;font-weight:600;">Website</a>
<span style="color:#cbd5e1;">&nbsp;&bull;&nbsp;</span>
<a href="{SITE_URL}/faq" style="color:{BRAND_COLOR_DARK};text-decoration:none;font-size:12px;font-weight:600;">Help Center</a>
<span style="color:#cbd5e1;">&nbsp;&bull;&nbsp;</span>
<a href="{SITE_URL}/privacy-policy" style="color:{BRAND_COLOR_DARK};text-decoration:none;font-size:12px;font-weight:600;">Privacy</a>
<span style="color:#cbd5e1;">&nbsp;&bull;&nbsp;</span>
<a href="{SITE_URL}/contact-us" style="color:{BRAND_COLOR_DARK};text-decoration:none;font-size:12px;font-weight:600;">Contact</a>
</div>
<div style="margin:0 0 6px;color:#9aa5b4;font-size:11px;">&copy; {year} {SITE_NAME}. All rights reserved.</div>
<div style="margin:0;color:#b8c2cf;font-size:11px;line-height:1.5;">This is an automated message — please do not reply to this email.<br>If you didn't request this, you can safely ignore it.</div>
</td>
</tr>

</table>
<div style="color:#aab3c0;font-size:11px;margin-top:18px;">Sent with care by {SITE_NAME} &middot; <a href="{SITE_URL}" style="color:#8a96a5;text-decoration:none;">{SITE_URL}</a></div>
</td></tr>
</table>
</body>
</html>"""


def _info_row(label, value):
    """Single row for key-value info display"""
    return f"""<tr>
<td style="padding:8px 12px;color:#6b7280;font-size:14px;border-bottom:1px solid #f3f4f6;width:140px;">{label}</td>
<td style="padding:8px 12px;color:#111827;font-size:14px;font-weight:500;border-bottom:1px solid #f3f4f6;">{value}</td>
</tr>"""


def _info_table(rows_html):
    """Wrapper for info table"""
    return f"""<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f9fafb;border-radius:8px;overflow:hidden;border:1px solid #e5e7eb;margin:16px 0;">
{rows_html}
</table>"""


def _button(text, url):
    """CTA button"""
    return f"""<div style="text-align:center;margin:28px 0;">
<a href="{url}" style="display:inline-block;padding:14px 40px;background:{BRAND_GRADIENT};color:#ffffff;text-decoration:none;border-radius:10px;font-size:15px;font-weight:700;letter-spacing:0.3px;box-shadow:0 4px 12px {BRAND_SHADOW};">{text}</a>
</div>"""


def _get_email_settings():
    """Get email settings from database or fallback to settings.py"""
    try:
        from .models import EmailSettings
        email_settings = EmailSettings.objects.filter(is_active=True).first()
        if email_settings:
            return {
                'host': email_settings.email_host,
                'port': email_settings.email_port,
                'use_tls': email_settings.email_use_tls,
                'host_user': email_settings.email_host_user,
                'host_password': email_settings.email_host_password,
                'from_email': email_settings.from_email or f"AdsyClub <{email_settings.email_host_user}>",
                'admin_email': email_settings.admin_email or email_settings.email_host_user,
            }
    except Exception as e:
        logger.warning(f"Could not load email settings from database: {e}")
    
    # Fallback to settings.py
    return {
        'host': getattr(settings, 'EMAIL_HOST', 'smtp.gmail.com'),
        'port': getattr(settings, 'EMAIL_PORT', 587),
        'use_tls': getattr(settings, 'EMAIL_USE_TLS', True),
        'host_user': getattr(settings, 'EMAIL_HOST_USER', ''),
        'host_password': getattr(settings, 'EMAIL_HOST_PASSWORD', ''),
        'from_email': getattr(settings, 'DEFAULT_FROM_EMAIL', f"AdsyClub <{getattr(settings, 'EMAIL_HOST_USER', '')}>"),
        'admin_email': getattr(settings, 'ADMIN_EMAIL', ADMIN_EMAIL),
    }


def _send_email(subject, to_email, text_content, html_content):
    """Send email with HTML and plain text fallback"""
    try:
        email_settings = _get_email_settings()
        
        # Configure email backend dynamically
        connection = get_connection(
            host=email_settings['host'],
            port=email_settings['port'],
            use_tls=email_settings['use_tls'],
            username=email_settings['host_user'],
            password=email_settings['host_password'],
        )
        
        msg = EmailMultiAlternatives(
            subject=f"[{SITE_NAME}] {subject}",
            body=text_content,
            from_email=email_settings['from_email'],
            to=[to_email],
            connection=connection,
        )
        msg.attach_alternative(html_content, "text/html")
        msg.send()
        
        logger.info(f"Email sent: '{subject}' to {to_email}")
        return True
    except Exception as e:
        logger.error(f"Email failed: '{subject}' to {to_email} - {e}")
        return False


# ============================================================
# USER EMAILS
# ============================================================

def send_welcome_email(user):
    """Send welcome email to newly registered user"""
    name = user.name or user.first_name or user.username or "there"
    subject = "Welcome to AdsyClub!"
    text = f"Hi {name}, Welcome to AdsyClub! Your account has been created successfully."

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Welcome to <strong>{SITE_NAME}</strong>! Your account has been created successfully. You're now part of Bangladesh's leading social business network.</p>

{_info_table(
    _info_row("Name", name) +
    _info_row("Email", user.email or "N/A") +
    _info_row("Phone", user.phone or "N/A") +
    _info_row("Referral Code", user.referral_code or "N/A")
)}

<p style="color:#374151;font-size:15px;line-height:1.6;margin:16px 0;">Here's what you can do on AdsyClub:</p>
<ul style="color:#374151;font-size:14px;line-height:2;padding-left:20px;margin:0 0 16px;">
<li><strong>Business Network</strong> – Connect with professionals</li>
<li><strong>Buy & Sell</strong> – Trade products & services</li>
<li><strong>Workspace Gigs</strong> – Hire or get hired</li>
<li><strong>AdsyConnect</strong> – Chat, voice & video calls</li>
<li><strong>eLearning</strong> – Learn new skills</li>
</ul>

{_button("Get Started", SITE_URL + "/adsy-business-network")}
"""

    html = _base_template(subject, body, "If you didn't create this account, please contact our support team.")
    return _send_email(subject, user.email, text, html)


def send_transfer_sent_email(sender_user, receiver_user, amount, transaction_id):
    """Email to sender after successful fund transfer"""
    name = sender_user.name or sender_user.first_name or sender_user.username
    receiver_name = receiver_user.name or receiver_user.first_name or receiver_user.username
    subject = "Fund Transfer Successful"
    text = f"Hi {name}, You sent ৳{amount} to {receiver_name}."

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your fund transfer has been completed successfully.</p>

{_info_table(
    _info_row("Amount", f"৳{amount}") +
    _info_row("Sent To", receiver_name) +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("View Balance", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body, "This is an automated notification. If you didn't make this transfer, contact support immediately.")
    return _send_email(subject, sender_user.email, text, html)


def send_transfer_received_email(receiver_user, sender_user, amount, transaction_id):
    """Email to receiver after receiving fund transfer"""
    name = receiver_user.name or receiver_user.first_name or receiver_user.username
    sender_name = sender_user.name or sender_user.first_name or sender_user.username
    subject = "Fund Transfer Received"
    text = f"Hi {name}, You received ৳{amount} from {sender_name}."

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">You have received a fund transfer to your AdsyClub wallet.</p>

{_info_table(
    _info_row("Amount", f"৳{amount}") +
    _info_row("From", sender_name) +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("View Balance", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, receiver_user.email, text, html)


def send_deposit_email(user, amount, transaction_id, payment_method=""):
    """Email to user after successful deposit"""
    name = user.name or user.first_name or user.username
    subject = "Deposit Successful"
    text = f"Hi {name}, Your deposit of ৳{amount} was successful."

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your deposit has been processed successfully and added to your wallet.</p>

{_info_table(
    _info_row("Amount", f"৳{amount}") +
    _info_row("Method", payment_method or "Online Payment") +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("View Balance", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, text, html)


def send_withdraw_email(user, amount, transaction_id, payment_method="", payment_number=""):
    """Email to user after withdrawal request"""
    name = user.name or user.first_name or user.username
    subject = "Withdrawal Request Submitted"
    text = f"Hi {name}, Your withdrawal of ৳{amount} has been submitted."

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your withdrawal request has been submitted and is being processed.</p>

{_info_table(
    _info_row("Amount", f"৳{amount}") +
    _info_row("Method", payment_method or "N/A") +
    _info_row("Account", payment_number or "N/A") +
    _info_row("Status", "Processing") +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("View Transactions", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body, "Withdrawals are usually processed within 24-48 hours. You will receive a confirmation once completed.")
    return _send_email(subject, user.email, text, html)


def send_withdraw_approved_email(user, amount, transaction_id):
    """Email to user after withdrawal is approved"""
    name = user.name or user.first_name or user.username
    subject = "Withdrawal Approved"
    text = f"Hi {name}, Your withdrawal of ৳{amount} has been approved."

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your withdrawal request has been <strong style="color:{BRAND_COLOR};">approved</strong> and the funds have been sent to your account.</p>

{_info_table(
    _info_row("Amount", f"৳{amount}") +
    _info_row("Status", "Approved ✓") +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, text, html)


def send_gig_order_placed_email(buyer, seller, gig_title, amount, order_id):
    """Email to both buyer and seller when a gig order is placed"""
    buyer_name = buyer.name or buyer.first_name or buyer.username
    seller_name = seller.name or seller.first_name or seller.username

    # Email to buyer
    buyer_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{buyer_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your gig order has been placed successfully.</p>

{_info_table(
    _info_row("Gig", gig_title) +
    _info_row("Seller", seller_name) +
    _info_row("Amount", f"৳{amount}") +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("Status", "Pending")
)}

{_button("View Order", SITE_URL + "/adsy-business-network/workspace")}
"""
    buyer_html = _base_template("Gig Order Placed", buyer_body, "The seller will review and accept your order shortly.")
    _send_email("Gig Order Placed", buyer.email, f"Your gig order for '{gig_title}' has been placed.", buyer_html)

    # Email to seller
    seller_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{seller_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">You have received a new gig order!</p>

{_info_table(
    _info_row("Gig", gig_title) +
    _info_row("Buyer", buyer_name) +
    _info_row("Amount", f"৳{amount}") +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("Status", "Pending - Action Required")
)}

{_button("Review Order", SITE_URL + "/adsy-business-network/workspace")}
"""
    seller_html = _base_template("New Gig Order Received", seller_body, "Please review and accept or decline this order within 24 hours.")
    _send_email("New Gig Order Received", seller.email, f"New order received for '{gig_title}'.", seller_html)


def send_gig_order_completed_email(buyer, seller, gig_title, amount, order_id):
    """Email to both parties when a gig order is completed"""
    buyer_name = buyer.name or buyer.first_name or buyer.username
    seller_name = seller.name or seller.first_name or seller.username

    # Email to buyer
    buyer_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{buyer_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your gig order has been <strong style="color:{BRAND_COLOR};">completed</strong> and payment has been released to the seller.</p>

{_info_table(
    _info_row("Gig", gig_title) +
    _info_row("Seller", seller_name) +
    _info_row("Amount", f"৳{amount}") +
    _info_row("Status", "Completed ✓")
)}

{_button("Leave a Review", SITE_URL + "/adsy-business-network/workspace")}
"""
    buyer_html = _base_template("Gig Order Completed", buyer_body)
    _send_email("Gig Order Completed", buyer.email, f"Your gig order for '{gig_title}' is completed.", buyer_html)

    # Email to seller
    seller_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{seller_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">A gig order has been completed and <strong style="color:{BRAND_COLOR};">৳{amount}</strong> has been added to your balance!</p>

{_info_table(
    _info_row("Gig", gig_title) +
    _info_row("Buyer", buyer_name) +
    _info_row("Amount", f"৳{amount}") +
    _info_row("Status", "Payment Released ✓")
)}

{_button("View Balance", SITE_URL + "/deposit-withdraw")}
"""
    seller_html = _base_template("Payment Released", seller_body)
    _send_email("Payment Released - Gig Completed", seller.email, f"Payment of ৳{amount} released for '{gig_title}'.", seller_html)


def send_gig_order_status_email(recipient_user, gig_title, order_id, new_status, actor_name=""):
    """Generic email for gig order status changes (accepted, declined, delivered, revision, cancelled)"""
    name = recipient_user.name or recipient_user.first_name or recipient_user.username

    status_labels = {
        "accepted": ("Order Accepted", f"Your gig order for <strong>{gig_title}</strong> has been accepted by {actor_name}.", BRAND_COLOR),
        "in_progress": ("Order In Progress", f"Work has started on your gig order for <strong>{gig_title}</strong>.", "#3b82f6"),
        "delivered": ("Order Delivered", f"Your gig order for <strong>{gig_title}</strong> has been delivered by {actor_name}. Please review the delivery.", "#8b5cf6"),
        "revision": ("Revision Requested", f"A revision has been requested for gig order <strong>{gig_title}</strong>.", "#f59e0b"),
        "declined": ("Order Declined", f"The gig order for <strong>{gig_title}</strong> has been declined by {actor_name}.", "#ef4444"),
        "cancelled": ("Order Cancelled", f"The gig order for <strong>{gig_title}</strong> has been cancelled.", "#ef4444"),
    }

    label, desc, color = status_labels.get(new_status, ("Order Update", f"Your gig order status has been updated.", "#6b7280"))
    subject = f"Gig Order: {label}"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">{desc}</p>

{_info_table(
    _info_row("Gig", gig_title) +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("New Status", f'<span style="color:{color};font-weight:600;">{new_status.replace("_", " ").title()}</span>')
)}

{_button("View Order", SITE_URL + "/adsy-business-network/workspace")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, recipient_user.email, f"Gig order status: {label}", html)


def send_kyc_approved_email(user):
    """Email when KYC is approved"""
    name = user.name or user.first_name or user.username
    subject = "KYC Verification Approved"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your KYC verification has been <strong style="color:{BRAND_COLOR};">approved</strong>! You now have access to all features on AdsyClub.</p>

{_button("Go to Dashboard", SITE_URL + "/adsy-business-network")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Hi {name}, Your KYC has been approved.", html)


def send_kyc_rejected_email(user, reason=""):
    """Email when KYC is rejected"""
    name = user.name or user.first_name or user.username
    subject = "KYC Verification Update"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Unfortunately, your KYC verification could not be approved at this time.</p>
{"<p style='color:#374151;font-size:14px;line-height:1.6;margin:0 0 16px;'><strong>Reason:</strong> " + reason + "</p>" if reason else ""}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Please resubmit your documents with clear, valid information.</p>

{_button("Resubmit KYC", SITE_URL + "/adsy-business-network/profile")}
"""

    html = _base_template(subject, body, "If you believe this is an error, please contact our support team.")
    return _send_email(subject, user.email, f"Hi {name}, KYC update.", html)


def send_account_suspended_email(user, reason=""):
    """Email sent when an account is suspended."""
    name = user.name or user.first_name or user.username
    subject = "Your AdsyClub account has been suspended"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your AdsyClub account has been <strong style="color:#DC2626;">suspended</strong>. While suspended you will not be able to use any of the app's services.</p>
{"<p style='color:#374151;font-size:14px;line-height:1.6;margin:0 0 16px;'><strong>Reason:</strong> " + reason + "</p>" if reason else ""}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">If you believe this is a mistake, please contact our support team.</p>
"""

    html = _base_template(subject, body, "If you believe this is an error, please contact our support team.")
    return _send_email(subject, user.email, f"Hi {name}, your account has been suspended.", html)


def send_account_unsuspended_email(user):
    """Email sent when a suspended account is restored."""
    name = user.name or user.first_name or user.username
    subject = "Your AdsyClub account has been restored"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Good news — your AdsyClub account has been <strong style="color:{BRAND_COLOR};">restored</strong>. You can use the app again.</p>

{_button("Open AdsyClub", SITE_URL)}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Hi {name}, your account has been restored.", html)


def send_pro_subscription_email(user, months, amount):
    """Email when Pro subscription is activated"""
    name = user.name or user.first_name or user.username
    subject = "Pro Subscription Activated"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your <strong style="color:{BRAND_COLOR};">Pro subscription</strong> has been activated! Enjoy premium features.</p>

{_info_table(
    _info_row("Plan", f"{months} Month(s)") +
    _info_row("Amount", f"৳{amount}") +
    _info_row("Activated", timezone.now().strftime("%B %d, %Y"))
)}

{_button("Explore Pro Features", SITE_URL + "/adsy-business-network")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Pro subscription activated for {months} months.", html)


def send_referral_reward_email(user, reward_amount, claim_type):
    """Email when referral reward is claimed"""
    name = user.name or user.first_name or user.username
    subject = "Referral Reward Claimed"
    role = "referring a friend" if claim_type == "referrer" else "signing up via referral"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Congratulations! You earned <strong style="color:{BRAND_COLOR};">৳{reward_amount}</strong> for {role}. The reward has been added to your wallet.</p>

{_info_table(
    _info_row("Reward", f"৳{reward_amount}") +
    _info_row("Type", claim_type.title()) +
    _info_row("Date", timezone.now().strftime("%B %d, %Y"))
)}

{_button("View Balance", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Referral reward of ৳{reward_amount} claimed.", html)


def send_password_reset_email(user, otp):
    """Email with OTP for password reset"""
    name = user.name or user.first_name or user.username
    subject = "Password Reset OTP"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Hi <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your password reset OTP is:</p>

<div style="text-align:center;margin:24px 0;">
<span style="display:inline-block;padding:16px 40px;background-color:#f3f4f6;border:2px solid #e5e7eb;border-radius:12px;font-size:32px;font-weight:700;letter-spacing:8px;color:#111827;">{otp}</span>
</div>

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:0;text-align:center;">This code is valid for 10 minutes. Do not share it with anyone.</p>
"""

    html = _base_template(subject, body, "If you didn't request a password reset, please ignore this email.")
    return _send_email(subject, user.email, f"Your AdsyClub OTP is: {otp}. Valid for 10 minutes.", html)


def send_mobile_recharge_email(user, amount, phone_number):
    """Email after successful mobile recharge"""
    name = user.name or user.first_name or user.username
    subject = "Mobile Recharge Successful"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Your mobile recharge has been processed successfully!</p>

{_info_table(
    _info_row("Recharge Amount", f"৳{amount}") +
    _info_row("Phone Number", phone_number) +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">Thank you for using AdsyClub mobile recharge service.</p>
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Mobile recharge successful: ৳{amount}", html)


def send_test_email(to_email=None):
    """Send a test email to verify SMTP configuration"""
    if not to_email:
        email_settings = _get_email_settings()
        to_email = email_settings['admin_email']
    
    subject = "AdsyClub Email Configuration Test"
    
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">This is a test email to verify your SMTP configuration is working correctly.</p>

{_info_table(
    _info_row("Test Time", timezone.now().strftime("%B %d, %Y %I:%M %p")) +
    _info_row("SMTP Host", _get_email_settings()['host']) +
    _info_row("SMTP Port", str(_get_email_settings()['port'])) +
    _info_row("TLS Enabled", "Yes" if _get_email_settings()['use_tls'] else "No")
)}

<p style="color:#10b981;font-size:15px;line-height:1.6;margin:16px 0;">✅ If you receive this email, your SMTP configuration is working perfectly!</p>

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">This test was sent from the AdsyClub Email Settings admin panel.</p>
"""

    html = _base_template(subject, body)
    return _send_email(subject, to_email, "Test email from AdsyClub", html)


# ============================================================
# ADMIN NOTIFICATION EMAILS
# ============================================================

def notify_admin_new_registration(user):
    """Notify admin when a new user registers"""
    name = user.name or user.first_name or user.username or "Unknown"
    subject = "New User Registration"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">A new user has registered on AdsyClub.</p>

{_info_table(
    _info_row("Name", name) +
    _info_row("Email", user.email or "N/A") +
    _info_row("Phone", user.phone or "N/A") +
    _info_row("Referred By", str(user.refer) if user.refer else "Direct") +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("View in Admin", SITE_URL + "/admin/base/user/")}
"""

    html = _base_template(subject, body)
    email_settings = _get_email_settings()
    return _send_email(subject, email_settings['admin_email'], f"New user registered: {name} ({user.email})", html)


def notify_admin_withdrawal_request(user, amount, payment_method, payment_number):
    """Notify admin when a withdrawal request is made"""
    name = user.name or user.first_name or user.username
    subject = "New Withdrawal Request"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">A user has submitted a withdrawal request.</p>

{_info_table(
    _info_row("User", name) +
    _info_row("Email", user.email or "N/A") +
    _info_row("Amount", f"৳{amount}") +
    _info_row("Method", payment_method or "N/A") +
    _info_row("Account", payment_number or "N/A") +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("Review in Admin", SITE_URL + "/admin/base/balance/")}
"""

    html = _base_template(subject, body, "Please review and approve/reject this withdrawal request.")
    return _send_email(subject, ADMIN_EMAIL, f"Withdrawal request: ৳{amount} by {name}", html)


def notify_admin_kyc_submission(user):
    """Notify admin when a KYC is submitted"""
    name = user.name or user.first_name or user.username
    subject = "New KYC Submission"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">A user has submitted KYC documents for verification.</p>

{_info_table(
    _info_row("User", name) +
    _info_row("Email", user.email or "N/A") +
    _info_row("Phone", user.phone or "N/A") +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("Review KYC", SITE_URL + "/admin/base/nid/")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, ADMIN_EMAIL, f"KYC submission from {name}", html)


def notify_admin_user_blocked(blocker, blocked_user, reason=""):
    """Notify admin when a user is blocked — required by Apple App Store Guideline 1.2 (UGC moderation)"""
    blocker_name = blocker.name or blocker.first_name or blocker.username or "Unknown"
    blocked_name = blocked_user.name or blocked_user.first_name or blocked_user.username or "Unknown"
    subject = "User Block Report — Action Required"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">A user has blocked another user on AdsyClub. Please review the blocked account for potential policy violations.</p>

{_info_table(
    _info_row("Reported By (Blocker)", f"{blocker_name} (@{blocker.username})") +
    _info_row("Blocker Email", blocker.email or "N/A") +
    _info_row("Blocked User", f"{blocked_name} (@{blocked_user.username})") +
    _info_row("Blocked Email", blocked_user.email or "N/A") +
    _info_row("Reason", reason or "Not specified") +
    _info_row("Date", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#ef4444;font-size:14px;line-height:1.6;margin:16px 0;font-weight:600;">⚠️ Please review the blocked user's content and account within 24 hours per our content moderation policy.</p>

{_button("Review Blocked Users", SITE_URL + "/admin/adsyconnect/blockeduser/")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, ADMIN_EMAIL, f"User block report: {blocker_name} blocked {blocked_name}", html)
