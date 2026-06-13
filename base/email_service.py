"""
AdsyClub Email Service
Professional email templates with white/light gray theme.
All transactional emails for users and admin notifications.
"""
import logging
from email.utils import formataddr, parseaddr
from smtplib import SMTPRecipientsRefused
from django.core.mail import send_mail, EmailMultiAlternatives, get_connection
from django.conf import settings
from django.utils import timezone

logger = logging.getLogger(__name__)

# No hardcoded admin address: the source of truth is the database (Django
# admin → Email Settings → admin_email, plus Admin Email Recipients).
# settings.ADMIN_EMAIL (env-driven) is only a last-resort fallback.
ADMIN_EMAIL = getattr(settings, "ADMIN_EMAIL", "")
SUPPORT_EMAIL = "support@adsyclub.com"
SUPPORT_PHONE = "+8801896144066"
SITE_NAME = "AdsyClub"
SITE_URL = "https://adsyclub.com"
# Match the AdsyConnect chat header (blue -> indigo -> violet).
BRAND_COLOR = "#6366F1"          # indigo (solid uses: links, button fallback)
BRAND_COLOR_DARK = "#8B5CF6"     # violet
BRAND_GRADIENT = "linear-gradient(135deg,#3B82F6,#6366F1,#8B5CF6)"
BRAND_GRADIENT_BAR = "linear-gradient(90deg,#3B82F6,#6366F1,#8B5CF6)"
BRAND_SHADOW = "rgba(99,102,241,0.16)"

# Every transactional email's footer carries a Donate button. The href is a
# placeholder that _send_email() swaps for a PERSONALIZED donate link (greets the
# recipient by name on the donate page) — the "smart" donation feature. Must match
# the salt used by alliance.views.donate_context to decode the token.
DONATE_PLACEHOLDER = "%%ADSY_DONATE_URL%%"
DONATE_SALT = "adsy-donate-v1"


def _donate_url_for(to_email):
    """Personalized donate link for a single known recipient (token greets them by
    name), or the generic /donate for unknown / multi-recipient sends."""
    try:
        from django.core import signing
        from django.contrib.auth import get_user_model
        if to_email and not isinstance(to_email, (list, tuple)):
            user = get_user_model().objects.filter(email__iexact=to_email).first()
            if user:
                name = user.name or getattr(user, "first_name", "") or ""
                token = signing.dumps({"n": name, "l": "bn"}, salt=DONATE_SALT)
                return f"{SITE_URL}/donate?u={token}"
    except Exception:
        pass
    return f"{SITE_URL}/donate?lang=bn"


# Every email footer also carries a one-click Unsubscribe hyperlink. Like the
# donate link, the href is a placeholder that _send_email() swaps for a unique
# per-recipient unsubscribe link (the unsubscribe page greets them by name and
# asks for confirmation).
UNSUB_PLACEHOLDER = "%%ADSY_UNSUB_URL%%"


def _unsub_url_for(to_email, lang="bn"):
    """Unique unsubscribe link for a single recipient (signed token, no login)."""
    try:
        if to_email and not isinstance(to_email, (list, tuple)):
            return f"{SITE_URL}/api/email/unsubscribe/?t={unsubscribe_token(to_email)}&lang={lang}"
    except Exception:
        pass
    return f"{SITE_URL}/api/email/unsubscribe/"


# App store install badges (icon + label, shown in the footer).
ANDROID_URL = "https://play.google.com/store/apps/details?id=com.oxius.app"
IOS_URL = "https://apps.apple.com/us/app/adsyclub/id6760218370"
ICON_GOOGLEPLAY = "https://img.icons8.com/color/96/google-play.png"
ICON_APPSTORE = "https://img.icons8.com/color/96/apple-app-store--v1.png"


def _app_badges_html():
    def badge(url, icon, label):
        return (f'<a href="{url}" target="_blank" style="display:inline-block;text-decoration:none;'
                f'border:1px solid #e3e5e9;border-radius:8px;padding:7px 13px;margin:0 5px 8px;background:#ffffff;">'
                f'<img src="{icon}" width="18" height="18" alt="" style="vertical-align:middle;border:0;">'
                f'<span style="color:#4b515b;font-size:12px;font-weight:600;vertical-align:middle;">&nbsp;&nbsp;{label}</span></a>')
    return (badge(ANDROID_URL, ICON_GOOGLEPLAY, "Available on Android")
            + badge(IOS_URL, ICON_APPSTORE, "Available on iOS"))


# ── Founder identity (CEO welcome email signature — mirrors the Alliance mail) ──
FOUNDER_PHOTO = "https://adsyclub.com/static/frontend/images/founder.jpg"
CEO_EMAIL = "ceo@adsyclub.com"
CEO_WHATSAPP = "+8801957045438"
CEO_WHATSAPP_LINK = "https://wa.me/8801957045438"
FOUNDER_FACEBOOK = "https://fb.com/AlimulOfficial"
FOUNDER_LINKEDIN = "https://www.linkedin.com/in/md-alimul-islam-299435115/"
ICON_EMAIL = "https://img.icons8.com/ios-filled/100/737a86/new-post.png"
ICON_WHATSAPP = "https://img.icons8.com/color/96/whatsapp--v1.png"
ICON_WEB = "https://img.icons8.com/ios-filled/100/737a86/domain.png"
ICON_FB = "https://img.icons8.com/color/96/facebook-new.png"
ICON_LI = "https://img.icons8.com/color/96/linkedin.png"
SIG_LINK = "#4f46e5"  # indigo


def _founder_signature_html():
    """Founder photo + name/title/contacts + social icons (FB, LinkedIn). The
    photo only renders once FOUNDER_PHOTO is hosted on a public URL."""
    photo = (f'<td style="width:138px;vertical-align:top;padding-right:10px;">'
             f'<img src="{FOUNDER_PHOTO}" width="128" height="128" alt="Alimul Islam" '
             f'style="width:128px;height:128px;border-radius:10px;display:block;border:0;"></td>') if FOUNDER_PHOTO else ""

    def crow(icon, val):
        return (f'<tr><td style="padding:5px 12px 5px 0;vertical-align:middle;width:18px;">'
                f'<img src="{icon}" width="17" height="17" alt="" style="display:block;border:0;"></td>'
                f'<td style="padding:5px 0;font-size:13px;color:#5b626d;vertical-align:middle;">{val}</td></tr>')

    contacts = (crow(ICON_EMAIL, f'<a href="mailto:{CEO_EMAIL}" style="color:{SIG_LINK};text-decoration:none;">{CEO_EMAIL}</a>')
                + crow(ICON_WHATSAPP, f'<a href="{CEO_WHATSAPP_LINK}" style="color:{SIG_LINK};text-decoration:none;">{CEO_WHATSAPP}</a>')
                + crow(ICON_WEB, f'<a href="https://www.adsyclub.com" style="color:{SIG_LINK};text-decoration:none;">https://www.adsyclub.com</a>'))

    def social(url, icon, alt):
        return (f'<td style="padding-right:11px;"><a href="{url}" target="_blank" style="text-decoration:none;">'
                f'<img src="{icon}" width="30" height="30" alt="{alt}" style="display:block;border:0;"></a></td>')

    socials = social(FOUNDER_FACEBOOK, ICON_FB, "Facebook") + social(FOUNDER_LINKEDIN, ICON_LI, "LinkedIn")
    return f"""
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:28px;">
<tr><td style="border-top:1px solid #ecedf1;padding-top:22px;">
  <table role="presentation" cellspacing="0" cellpadding="0"><tr>
    {photo}
    <td style="vertical-align:top;">
      <div style="font-size:16px;color:#1a1d23;font-weight:700;letter-spacing:-0.2px;">Alimul Islam</div>
      <div style="font-size:13px;color:#8a919c;margin-top:3px;">Developer, Founder &amp; CEO, AdsyClub</div>
      <table role="presentation" cellspacing="0" cellpadding="0" style="margin-top:12px;">{contacts}</table>
    </td>
  </tr></table>
  <table role="presentation" cellspacing="0" cellpadding="0" style="margin-top:14px;"><tr>{socials}</tr></table>
</td></tr>
</table>
"""


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
        note_html = f"""<tr><td class="ec-pad" style="padding:0 36px 28px;">
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
<style>
@media only screen and (max-width:600px) {{
  .ec-wrap {{ padding-left:4px !important; padding-right:4px !important; }}
  .ec-pad {{ padding-left:16px !important; padding-right:16px !important; }}
}}
</style>
</head>
<body style="margin:0;padding:0;background-color:#eef1f5;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;-webkit-font-smoothing:antialiased;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" class="ec-wrap" style="background-color:#eef1f5;padding:32px 14px;">
<tr><td align="center">
<table role="presentation" width="600" cellspacing="0" cellpadding="0" style="width:600px;max-width:600px;background-color:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(15,23,42,0.08);">

<!-- Brand accent -->
<tr><td style="height:5px;background:{BRAND_GRADIENT_BAR};font-size:0;line-height:0;">&nbsp;</td></tr>

<!-- Logo header -->
<tr>
<td class="ec-pad" style="padding:30px 32px 22px;text-align:center;background-color:#ffffff;border-bottom:1px solid #eef1f5;">
<img src="{logo}" alt="{SITE_NAME}" height="42" style="height:42px;width:auto;border:0;display:inline-block;outline:none;text-decoration:none;">
<div style="margin:10px 0 0;color:#94a3b8;font-size:11px;letter-spacing:2px;text-transform:uppercase;font-weight:600;">Social Business Network</div>
</td>
</tr>

<!-- Body -->
<!-- Note: the email subject is shown by the mail client itself, so we do
     NOT repeat it as an in-body <h2> title — each email's body opens with
     its own intro/greeting. -->
<tr>
<td class="ec-pad" style="padding:28px 36px 30px;">
{body_content}
</td>
</tr>

{note_html}

<!-- Footer (app badges + donation appeal + clean meta) -->
<tr>
<td class="ec-pad" style="background-color:#f8fafc;padding:28px 32px 32px;border-top:1px solid #e8edf3;text-align:center;">
<div style="margin:0 0 22px;line-height:0;">{_app_badges_html()}</div>
<div style="font-size:15px;color:#1a1d23;font-weight:700;margin:0 0 7px;">Believe in what we're building?</div>
<div style="font-size:13px;color:#6b7280;line-height:1.7;margin:0 auto 18px;max-width:430px;">AdsyClub creates income &amp; employment for everyday people across Bangladesh. Your support — however small — helps us reach more lives. Please consider a donation.</div>
<a href="{DONATE_PLACEHOLDER}" style="display:inline-block;padding:13px 34px;background:{BRAND_GRADIENT};color:#ffffff;text-decoration:none;border-radius:9px;font-size:14px;font-weight:700;"><span style="font-size:15px;vertical-align:-1px;">&#10084;</span>&nbsp;&nbsp;Donate to AdsyClub</a>

<div style="border-top:1px solid #e7e9ee;margin:26px auto 16px;font-size:0;line-height:0;">&nbsp;</div>

<div style="margin:0 0 3px;color:#0f172a;font-size:15px;font-weight:800;letter-spacing:-0.2px;">{SITE_NAME}</div>
<div style="margin:0 0 11px;color:#94a3b8;font-size:11px;">Bangladesh's Social Business Network</div>
<div style="margin:0 0 10px;color:#7b828d;font-size:11px;line-height:1.7;">Need help? <a href="mailto:{SUPPORT_EMAIL}" style="color:{BRAND_COLOR_DARK};text-decoration:none;">{SUPPORT_EMAIL}</a> &middot; <a href="tel:{SUPPORT_PHONE}" style="color:{BRAND_COLOR_DARK};text-decoration:none;">{SUPPORT_PHONE}</a></div>
<div style="margin:0 0 7px;color:#9aa5b4;font-size:11px;">&copy; {year} {SITE_NAME}</div>
<div style="margin:0;font-size:11px;"><a href="{UNSUB_PLACEHOLDER}" style="color:#9aa5b4;text-decoration:underline;">Don't want these emails? Unsubscribe</a></div>
</td>
</tr>

</table>
<div style="color:#aab3c0;font-size:11px;margin-top:18px;">AdsyClub &middot; Bangladesh &middot; <a href="https://www.adsyclub.com" style="color:#8a96a5;text-decoration:none;">https://www.adsyclub.com</a></div>
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
    """In-body CTA buttons are intentionally disabled for USER-facing emails — each
    email's single CTA is now the Donate button in the footer. Kept as a no-op so
    the ~30 existing callers don't each need editing (the page is still reachable
    via the app). ADMIN notification emails use _admin_button() instead, so staff
    keep their quick "Review / View in Admin" action buttons."""
    return ""


def _admin_button(text, url):
    """A real CTA button — used ONLY in admin notification emails so staff can jump
    straight to the relevant admin page and act fast (Review KYC, withdrawals,
    etc.). User-facing emails deliberately use the no-op _button()."""
    if not text or not url:
        return ""
    return (
        '<table role="presentation" cellpadding="0" cellspacing="0" style="margin:18px auto 6px;">'
        '<tr><td style="border-radius:10px;background:#059669;">'
        f'<a href="{url}" style="display:inline-block;padding:12px 28px;color:#ffffff;'
        f'text-decoration:none;font-size:15px;font-weight:600;border-radius:10px;">{text}</a>'
        '</td></tr></table>'
    )


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


_UNSUB_SALT = "email-unsub-v1"


def _norm_email(e):
    return (e or "").strip().lower()


def is_email_suppressed(email):
    """True if this address has unsubscribed or keeps bouncing."""
    e = _norm_email(email)
    if not e:
        return True
    try:
        from .models import EmailSuppression
        return EmailSuppression.objects.filter(email=e).exists()
    except Exception:
        return False


def suppress_email(email, reason="bounced", note=""):
    e = _norm_email(email)
    if not e:
        return
    try:
        from .models import EmailSuppression
        EmailSuppression.objects.get_or_create(
            email=e, defaults={"reason": reason, "note": note[:255]}
        )
        logger.info(f"Email suppressed ({reason}): {e}")
    except Exception as exc:  # never let suppression break a send path
        logger.warning(f"suppress_email failed for {e}: {exc}")


def unsubscribe_token(email):
    from django.core import signing
    return signing.dumps(_norm_email(email), salt=_UNSUB_SALT)


def email_from_unsub_token(token, max_age=60 * 60 * 24 * 365):
    from django.core import signing
    try:
        return _norm_email(signing.loads(token, salt=_UNSUB_SALT, max_age=max_age))
    except Exception:
        return None


def _valid_email_syntax(email):
    from django.core.validators import validate_email
    from django.core.exceptions import ValidationError
    try:
        validate_email((email or "").strip())
        return True
    except ValidationError:
        return False


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
        
        # Show the sender as "AdsyClub <address>" (clean display name).
        raw_from = email_settings['from_email']
        from_addr = parseaddr(raw_from)[1] or raw_from
        from_email = formataddr((SITE_NAME, from_addr))

        # Accept a single address or a list of addresses.
        recipients = to_email if isinstance(to_email, (list, tuple)) else [to_email]
        # Drop blanks + syntactically invalid addresses (can't be delivered at all)
        # and remember those. We intentionally do NOT skip suppressed addresses
        # here: transactional/security mail (OTP, password reset, KYC, withdraw…)
        # must always try, since the user may have fixed a previously-bad address.
        # Marketing/engagement mail skips the suppression list itself before it
        # ever calls _send_email (see send_engagement_email / the CEO backfill).
        clean = []
        for r in recipients:
            if not r:
                continue
            if not _valid_email_syntax(r):
                suppress_email(r, reason="invalid", note="bad address format")
                continue
            clean.append(r)
        if not clean:
            return False

        # Swap the donate + unsubscribe placeholders for unique per-recipient
        # links (single, known recipient only; generic for multi-recipient).
        single = clean[0] if len(clean) == 1 else None
        donate_url = _donate_url_for(single or clean)
        unsub_url = _unsub_url_for(single)
        html_content = (html_content or "").replace(DONATE_PLACEHOLDER, donate_url).replace(UNSUB_PLACEHOLDER, unsub_url)
        text_content = (text_content or "").replace(DONATE_PLACEHOLDER, donate_url).replace(UNSUB_PLACEHOLDER, unsub_url)

        msg = EmailMultiAlternatives(
            subject=subject,
            body=text_content,
            from_email=from_email,
            to=list(clean),
            connection=connection,
        )
        msg.attach_alternative(html_content, "text/html")
        msg.send()

        logger.info(f"Email sent: '{subject}' to {clean}")
        return True
    except SMTPRecipientsRefused as e:
        # The server rejected these recipients outright (wrong/nonexistent
        # address) — stop sending to them forever.
        try:
            for bad in (e.recipients or {}).keys():
                suppress_email(bad, reason="bounced", note="SMTP recipient refused")
        except Exception:
            pass
        logger.error(f"Email refused: '{subject}' to {to_email} - {e}")
        return False
    except Exception as e:
        # Connection/transient errors — NOT the recipient's fault, don't suppress.
        logger.error(f"Email failed: '{subject}' to {to_email} - {e}")
        return False


def _admin_recipients():
    """All admin-notification addresses: the primary EmailSettings.admin_email
    plus every active AdminEmailRecipient row (managers/assistants added from
    Django admin), deduplicated case-insensitively."""
    emails = []
    primary = _get_email_settings().get('admin_email') or ADMIN_EMAIL
    if primary:
        emails.append(primary)
    try:
        from .models import AdminEmailRecipient
        extras = AdminEmailRecipient.objects.filter(
            is_active=True
        ).values_list('email', flat=True)
        emails.extend(extras)
    except Exception as e:  # table missing / db hiccup — never block the email
        logger.warning(f"Could not load extra admin recipients: {e}")
    seen, unique = set(), []
    for e in emails:
        key = e.strip().lower()
        if key and key not in seen:
            seen.add(key)
            unique.append(e.strip())
    return unique


def _dispatch_async(target, *args, **kwargs):
    """Fire-and-forget an email off the request thread (each _send_email opens
    its own SMTP connection, ~1-2s). Used for admin notifications so creating a
    post/order stays snappy."""
    import threading

    def _run():
        try:
            target(*args, **kwargs)
        except Exception as exc:  # pragma: no cover
            logger.error(f"async email dispatch failed: {exc}")
        finally:
            try:
                from django.db import connections
                connections.close_all()
            except Exception:
                pass

    threading.Thread(target=_run, daemon=True).start()


def _action_buttons(approve_url, reject_url):
    """Green Approve + red Reject buttons for admin moderation emails."""
    return f"""
<table role="presentation" cellpadding="0" cellspacing="0" style="margin:8px auto 4px;">
  <tr>
    <td style="padding:6px;">
      <a href="{approve_url}" style="display:inline-block;background:#16a34a;color:#ffffff;text-decoration:none;font-size:15px;font-weight:600;padding:12px 26px;border-radius:10px;">✅ Approve</a>
    </td>
    <td style="padding:6px;">
      <a href="{reject_url}" style="display:inline-block;background:#dc2626;color:#ffffff;text-decoration:none;font-size:15px;font-weight:600;padding:12px 26px;border-radius:10px;">❌ Reject</a>
    </td>
  </tr>
</table>
<p style="text-align:center;color:#9ca3af;font-size:12px;margin:0 0 4px;">নিরাপত্তার জন্য Approve/Reject করতে admin-এ লগইন থাকতে হবে; এরপর একটি confirm পেজ দেখিয়ে তবেই অ্যাকশন হবে।</p>
"""


def send_admin_moderation_email(*, subject, label, intro, rows, model_key=None,
                                pk=None, admin_path="", text_summary=""):
    """Notify the admin of a new item. If model_key+pk are given the email
    carries one-click Approve / Reject buttons; otherwise it's informational
    (e.g. a new order) with a link into the admin.

    rows: list of (key, value) string pairs shown in the details table.
    """
    info = _info_table("".join(_info_row(k, v) for k, v in rows))

    actions = ""
    if model_key and pk:
        try:
            from .moderation import moderation_url
            actions = _action_buttons(
                moderation_url(model_key, pk, "approve"),
                moderation_url(model_key, pk, "reject"),
            )
        except Exception as exc:  # pragma: no cover
            logger.error(f"moderation link build failed: {exc}")

    review = ""
    if admin_path:
        review = (
            f'<p style="text-align:center;margin:10px 0 0;">'
            f'<a href="{SITE_URL}{admin_path}" style="color:{BRAND_COLOR};font-size:13px;'
            f'text-decoration:none;">Admin-এ বিস্তারিত দেখুন →</a></p>'
        )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">{intro}</p>
{info}
{actions}
{review}
"""
    html = _base_template(subject, body)
    # Primary admin + every active AdminEmailRecipient (managers, assistants).
    return _send_email(subject, _admin_recipients(), text_summary or subject, html)


# ============================================================
# USER EMAILS
# ============================================================

def send_welcome_email(user):
    """Send welcome email to newly registered user"""
    name = user.name or user.first_name or user.username or "there"
    subject = "AdsyClub-এ স্বাগতম! 🎉"
    text = f"হ্যালো {name}, AdsyClub-এ স্বাগতম! আপনার অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;"><strong>{SITE_NAME}</strong>-এ স্বাগতম! আপনার অ্যাকাউন্ট সফলভাবে তৈরি হয়েছে। আপনি এখন বাংলাদেশের অন্যতম সোশ্যাল বিজনেস নেটওয়ার্কের সদস্য।</p>

{_info_table(
    _info_row("নাম", name) +
    _info_row("ইমেইল", user.email or "N/A") +
    _info_row("ফোন", user.phone or "N/A") +
    _info_row("রেফারেল কোড", user.referral_code or "N/A")
)}

<p style="color:#374151;font-size:15px;line-height:1.6;margin:16px 0;">AdsyClub-এ আপনি যা যা করতে পারবেন:</p>
<ul style="color:#374151;font-size:14px;line-height:2;padding-left:20px;margin:0 0 16px;">
<li><strong>Business Network</strong> – পেশাদারদের সাথে যুক্ত হোন</li>
<li><strong>eShop</strong> – নতুন পণ্য কিনুন</li>
<li><strong>পুরোনো কেনাবেচা</strong> – ব্যবহৃত জিনিস কেনাবেচা করুন</li>
<li><strong>Workspace Gigs</strong> – কাজ দিন বা কাজ নিন</li>
<li><strong>AdsyConnect</strong> – চ্যাট, ভয়েস ও ভিডিও কল</li>
<li><strong>eLearning</strong> – নতুন স্কিল শিখুন</li>
</ul>
"""

    html = _base_template(subject, body, "এই অ্যাকাউন্টটা যদি আপনি না খুলে থাকেন, আমাদের সাপোর্ট টিমকে জানান।")
    return _send_email(subject, user.email, text, html)


def send_ceo_welcome_email(user):
    """A personal welcome from the CEO — sent to a newly registered user alongside
    the standard welcome email (so a new user gets two: the system welcome + this
    personal note). Uses the founder-signature design (photo + socials)."""
    name = user.name or user.first_name or user.username or "বন্ধু"
    subject = "CEO-র পক্ষ থেকে আন্তরিক অভিনন্দন💚"
    text = (
        f"প্রিয় {name},\n\nAdsyClub পরিবারে আপনাকে পেয়ে আমি সত্যিই অনেক খুশি। আমি Alimul Islam — "
        "AdsyClub-এর প্রতিষ্ঠাতা। আমরা বাংলাদেশের সাধারণ মানুষের জন্য আয়, সহজ সেবা প্রদান, দেশীয় কমিউনিটি, আর কাজের সুযোগ তৈরি করতে "
        "কাজ করছি, আর আজ থেকে আপনিও এই যাত্রার একজন সঙ্গী।\n\nযেকোনো দরকারে সরাসরি আমাকে লিখুন।\n\n"
        f"— Alimul Islam, Founder & CEO, AdsyClub\n{CEO_EMAIL}"
    )
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.75;margin:0 0 16px;">প্রিয় <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.75;margin:0 0 16px;">AdsyClub পরিবারে আপনাকে পেয়ে আমি সত্যিই অনেক খুশি। আমি <strong>Alimul Islam</strong> — AdsyClub-এর প্রতিষ্ঠাতা।</p>
<p style="color:#374151;font-size:15px;line-height:1.75;margin:0 0 16px;">আমরা বাংলাদেশের সাধারণ মানুষের জন্য আয়, সহজ সেবা প্রদান, দেশীয় কমিউনিটি, আর কাজের সুযোগ তৈরি করতে কাজ করছি — আর আজ থেকে আপনিও এই যাত্রার একজন সঙ্গী, যা আমাদের কাছে অনেক বড় ব্যাপার।</p>
<p style="color:#374151;font-size:15px;line-height:1.75;margin:0 0 16px;">শুরু করতে কোথাও আটকে গেলে, কিংবা কোনো পরামর্শ বা অভিযোগ থাকলে — নিচের যেকোনো মাধ্যমে সরাসরি আমাকে লিখুন। আপনার একটা মেসেজও আমাদের আরও ভালো করতে সাহায্য করবে।</p>
<p style="color:#374151;font-size:15px;line-height:1.75;margin:0 0 4px;">ভালো থাকবেন, পাশে থাকবেন। 🌿</p>
{_founder_signature_html()}
"""
    html = _base_template(subject, body)
    ok = _send_email(subject, user.email, text, html)
    # Remember a successful delivery so the one-time backfill never re-sends it.
    if ok:
        try:
            if not user.ceo_welcome_sent:
                user.ceo_welcome_sent = True
                user.save(update_fields=["ceo_welcome_sent"])
        except Exception as exc:  # never let bookkeeping break the send
            logger.warning(f"could not mark ceo_welcome_sent for {user.pk}: {exc}")
    return ok


def send_transfer_sent_email(sender_user, receiver_user, amount, transaction_id):
    """Email to sender after successful fund transfer"""
    name = sender_user.name or sender_user.first_name or sender_user.username
    receiver_name = receiver_user.name or receiver_user.first_name or receiver_user.username
    subject = "ফান্ড ট্রান্সফার সফল হয়েছে"
    text = f"হ্যালো {name}, আপনি {receiver_name}-কে ৳{amount} পাঠিয়েছেন।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার ফান্ড ট্রান্সফার সফলভাবে কমপ্লিট হয়েছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("প্রাপক", receiver_name) +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body, "এটি একটি স্বয়ংক্রিয় নোটিফিকেশন। আপনি যদি এই ট্রান্সফার না করে থাকেন, অবিলম্বে সাপোর্টে যোগাযোগ করুন।")
    return _send_email(subject, sender_user.email, text, html)


def send_transfer_received_email(receiver_user, sender_user, amount, transaction_id):
    """Email to receiver after receiving fund transfer"""
    name = receiver_user.name or receiver_user.first_name or receiver_user.username
    sender_name = sender_user.name or sender_user.first_name or sender_user.username
    subject = "ফান্ড ট্রান্সফার রিসিভ হয়েছে"
    text = f"হ্যালো {name}, আপনি {sender_name}-এর কাছ থেকে ৳{amount} পেয়েছেন।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার AdsyClub ওয়ালেটে একটি ফান্ড ট্রান্সফার এসেছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("প্রেরক", sender_name) +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, receiver_user.email, text, html)


def send_deposit_email(user, amount, transaction_id, payment_method=""):
    """Email to user after successful deposit"""
    name = user.name or user.first_name or user.username
    subject = "ডিপোজিট সফল হয়েছে"
    text = f"হ্যালো {name}, আপনার ৳{amount} ডিপোজিট সফল হয়েছে।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার ডিপোজিট সফলভাবে কমপ্লিট হয়েছে এবং টাকা ওয়ালেটে যোগ হয়েছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("মাধ্যম", payment_method or "Online Payment") +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, text, html)


def send_withdraw_email(user, amount, transaction_id, payment_method="", payment_number=""):
    """Email to user after withdrawal request"""
    name = user.name or user.first_name or user.username
    subject = "উইথড্র রিকোয়েস্ট জমা হয়েছে"
    text = f"হ্যালো {name}, আপনার ৳{amount} উইথড্র রিকোয়েস্ট জমা হয়েছে।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার উইথড্র রিকোয়েস্ট জমা হয়েছে এবং প্রক্রিয়াধীন আছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("মাধ্যম", payment_method or "N/A") +
    _info_row("অ্যাকাউন্ট", payment_number or "N/A") +
    _info_row("স্ট্যাটাস", "প্রক্রিয়াধীন") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ট্রান্সঅ্যাকশন দেখুন", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body, "উইথড্র সাধারণত ২৪–৪৮ ঘণ্টার মধ্যে প্রক্রিয়া করা হয়। কমপ্লিট হলে আপনি একটি নিশ্চিতকরণ পাবেন।")
    return _send_email(subject, user.email, text, html)


def send_withdraw_approved_email(user, amount, transaction_id):
    """Email to user after withdrawal is approved"""
    name = user.name or user.first_name or user.username
    subject = "উইথড্র অ্যাপ্রুভ হয়েছে"
    text = f"হ্যালো {name}, আপনার ৳{amount} উইথড্র অ্যাপ্রুভ হয়েছে।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার উইথড্র রিকোয়েস্ট <strong style="color:{BRAND_COLOR};">অ্যাপ্রুভ</strong> হয়েছে এবং টাকা আপনার অ্যাকাউন্টে পাঠানো হয়েছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভড ✓") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
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
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{buyer_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার গিগ অর্ডার সফলভাবে দেওয়া হয়েছে।</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("বিক্রেতা", seller_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("স্ট্যাটাস", "অপেক্ষমাণ")
)}

{_button("অর্ডার দেখুন", SITE_URL + "/business-network/workspaces")}
"""
    buyer_html = _base_template("গিগ অর্ডার দেওয়া হয়েছে", buyer_body, "The seller will review and accept your order shortly.")
    _send_email("গিগ অর্ডার দেওয়া হয়েছে", buyer.email, f"Your gig order for '{gig_title}' has been placed.", buyer_html)

    # Email to seller
    seller_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{seller_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনি একটি নতুন গিগ অর্ডার পেয়েছেন!</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("ক্রেতা", buyer_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("স্ট্যাটাস", "অপেক্ষমাণ — ব্যবস্থা নিন")
)}

{_button("অর্ডার রিভিউ করুন", SITE_URL + "/business-network/workspaces")}
"""
    seller_html = _base_template("নতুন গিগ অর্ডার এসেছে", seller_body, "Please review and accept or decline this order within 24 hours.")
    _send_email("নতুন গিগ অর্ডার এসেছে", seller.email, f"New order received for '{gig_title}'.", seller_html)


def send_gig_order_completed_email(buyer, seller, gig_title, amount, order_id):
    """Email to both parties when a gig order is completed"""
    buyer_name = buyer.name or buyer.first_name or buyer.username
    seller_name = seller.name or seller.first_name or seller.username

    # Email to buyer
    buyer_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{buyer_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার গিগ অর্ডার <strong style="color:{BRAND_COLOR};">কমপ্লিট</strong> হয়েছে এবং বিক্রেতাকে পেমেন্ট রিলিজ করা হয়েছে।</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("বিক্রেতা", seller_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("স্ট্যাটাস", "কমপ্লিট ✓")
)}

{_button("রিভিউ দিন", SITE_URL + "/business-network/workspaces")}
"""
    buyer_html = _base_template("গিগ অর্ডার কমপ্লিট হয়েছে", buyer_body)
    _send_email("গিগ অর্ডার কমপ্লিট হয়েছে", buyer.email, f"Your gig order for '{gig_title}' is completed.", buyer_html)

    # Email to seller
    seller_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{seller_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">একটি গিগ অর্ডার কমপ্লিট হয়েছে এবং <strong style="color:{BRAND_COLOR};">৳{amount}</strong> আপনার ব্যালেন্সে যোগ হয়েছে!</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("ক্রেতা", buyer_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("স্ট্যাটাস", "Payment Released ✓")
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""
    seller_html = _base_template("পেমেন্ট রিলিজ হয়েছে", seller_body)
    _send_email("পেমেন্ট রিলিজ হয়েছে — গিগ কমপ্লিট", seller.email, f"'{gig_title}' গিগের জন্য ৳{amount} রিলিজ হয়েছে।", seller_html)


def send_gig_order_status_email(recipient_user, gig_title, order_id, new_status, actor_name=""):
    """Generic email for gig order status changes (accepted, declined, delivered, revision, cancelled)"""
    name = recipient_user.name or recipient_user.first_name or recipient_user.username

    status_labels = {
        "accepted": ("অর্ডার অ্যাকসেপ্ট হয়েছে", f"{actor_name} আপনার <strong>{gig_title}</strong> গিগ অর্ডারটি অ্যাকসেপ্ট করেছেন।", BRAND_COLOR),
        "in_progress": ("কাজ চলছে", f"আপনার <strong>{gig_title}</strong> গিগ অর্ডারের কাজ শুরু হয়েছে।", "#3b82f6"),
        "delivered": ("অর্ডার ডেলিভার করা হয়েছে", f"{actor_name} আপনার <strong>{gig_title}</strong> গিগ অর্ডারটি ডেলিভার করেছেন। অনুগ্রহ করে ডেলিভারিটি পর্যালোচনা করুন।", "#8b5cf6"),
        "revision": ("রিভিশন চাওয়া হয়েছে", f"<strong>{gig_title}</strong> গিগ অর্ডারের জন্য একটি রিভিশন চাওয়া হয়েছে।", "#f59e0b"),
        "declined": ("অর্ডার ক্যানসেল হয়েছে", f"{actor_name} <strong>{gig_title}</strong> গিগ অর্ডারটি ক্যানসেল করেছেন।", "#ef4444"),
        "cancelled": ("অর্ডার বাতিল", f"<strong>{gig_title}</strong> গিগ অর্ডারটি বাতিল করা হয়েছে।", "#ef4444"),
    }

    label, desc, color = status_labels.get(new_status, ("অর্ডার আপডেট", f"আপনার গিগ অর্ডারের স্ট্যাটাস আপডেট হয়েছে।", "#6b7280"))
    subject = f"গিগ অর্ডার: {label}"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">{desc}</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("নতুন স্ট্যাটাস",f'<span style="color:{color};font-weight:600;">{new_status.replace("_", " ").title()}</span>')
)}

{_button("অর্ডার দেখুন", SITE_URL + "/business-network/workspaces")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, recipient_user.email, f"Gig order status: {label}", html)


def send_kyc_approved_email(user):
    """Email when KYC is approved"""
    name = user.name or user.first_name or user.username
    subject = "KYC ভেরিফিকেশন অ্যাপ্রুভ হয়েছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার KYC ভেরিফিকেশন <strong style="color:{BRAND_COLOR};">অ্যাপ্রুভ</strong> হয়েছে! এখন আপনি AdsyClub-এর সব ফিচার ব্যবহার করতে পারবেন।</p>

{_button("ড্যাশবোর্ডে যান", SITE_URL + "/business-network")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Hi {name}, Your KYC has been approved.", html)


def send_kyc_rejected_email(user, reason=""):
    """Email when KYC is rejected"""
    name = user.name or user.first_name or user.username
    subject = "KYC ভেরিফিকেশন আপডেট"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">দুঃখিত, এই মুহূর্তে আপনার KYC ভেরিফিকেশন অ্যাপ্রুভ করা যায়নি।</p>
{"<p style='color:#374151;font-size:14px;line-height:1.6;margin:0 0 16px;'><strong>Reason:</strong> " + reason + "</p>" if reason else ""}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">Please resubmit your documents with clear, valid information.</p>

{_button("KYC পুনরায় জমা দিন", SITE_URL + "/my-account")}
"""

    html = _base_template(subject, body, "If you believe this is an error, please contact our support team.")
    return _send_email(subject, user.email, f"Hi {name}, KYC update.", html)


def send_gold_sponsor_email(user, *, subject, heading, message_html,
                            button_text="", button_url="", footer_note=""):
    """Generic Gold Sponsor lifecycle email (renewal reminders, auto-renew
    receipts, expiry & win-back). Fire-and-forget so the lifecycle task is never
    blocked on SMTP, and a no-op if the user has no email address. Email only
    actually delivers once EMAIL_HOST_PASSWORD is configured; push is separate."""
    email = getattr(user, 'email', None)
    if not email:
        return False
    name = (getattr(user, 'name', None) or getattr(user, 'first_name', None)
            or getattr(user, 'username', None) or 'গ্রাহক')
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 12px;">প্রিয় <strong>{name}</strong>,</p>
<p style="color:#111827;font-size:16px;line-height:1.5;margin:0 0 16px;font-weight:600;">{heading}</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">{message_html}</p>
{_button(button_text, button_url) if (button_text and button_url) else ""}
"""
    html = _base_template(subject, body, footer_note)
    _dispatch_async(_send_email, subject, email, f"প্রিয় {name}, {heading}", html)
    return True


def send_account_suspended_email(user, reason=""):
    """Email sent when an account is suspended."""
    name = user.name or user.first_name or user.username
    subject = "আপনার AdsyClub অ্যাকাউন্ট স্থগিত করা হয়েছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার AdsyClub অ্যাকাউন্ট <strong style="color:#DC2626;">স্থগিত</strong> করা হয়েছে। স্থগিত থাকা অবস্থায় আপনি অ্যাপের কোনো সেবা ব্যবহার করতে পারবেন না।</p>
{"<p style='color:#374151;font-size:14px;line-height:1.6;margin:0 0 16px;'><strong>Reason:</strong> " + reason + "</p>" if reason else ""}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">If you believe this is a mistake, please contact our support team.</p>
"""

    html = _base_template(subject, body, "If you believe this is an error, please contact our support team.")
    return _send_email(subject, user.email, f"Hi {name}, your account has been suspended.", html)


def send_account_unsuspended_email(user):
    """Email sent when a suspended account is restored."""
    name = user.name or user.first_name or user.username
    subject = "আপনার AdsyClub অ্যাকাউন্ট পুনরুদ্ধার করা হয়েছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুসংবাদ — আপনার AdsyClub অ্যাকাউন্ট <strong style="color:{BRAND_COLOR};">পুনরুদ্ধার</strong> করা হয়েছে। আপনি আবার অ্যাপটি ব্যবহার করতে পারবেন।</p>

{_button("AdsyClub খুলুন", SITE_URL)}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Hi {name}, your account has been restored.", html)


def send_pro_subscription_email(user, months, amount):
    """Email when Pro subscription is activated"""
    name = user.name or user.first_name or user.username
    subject = "Pro সাবস্ক্রিপশন চালু হয়েছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার <strong style="color:{BRAND_COLOR};">Pro সাবস্ক্রিপশন</strong> চালু হয়েছে! প্রিমিয়াম ফিচারগুলো উপভোগ করুন।</p>

{_info_table(
    _info_row("Plan", f"{months} Month(s)") +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("Activated", timezone.now().strftime("%B %d, %Y"))
)}

{_button("Pro ফিচার দেখুন", SITE_URL + "/business-network")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Pro subscription activated for {months} months.", html)


def send_referral_reward_email(user, reward_amount, claim_type):
    """Email when referral reward is claimed"""
    name = user.name or user.first_name or user.username
    subject = "রেফারেল রিওয়ার্ড যোগ হয়েছে"
    role = "একজন বন্ধুকে রেফার করার জন্য" if claim_type == "referrer" else "রেফারেলের মাধ্যমে সাইন আপ করার জন্য"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">অভিনন্দন! {role} আপনি <strong style="color:{BRAND_COLOR};">৳{reward_amount}</strong> পুরস্কার পেয়েছেন। এটি আপনার ওয়ালেটে যোগ হয়েছে।</p>

{_info_table(
    _info_row("Reward", f"৳{reward_amount}") +
    _info_row("Type", claim_type.title()) +
    _info_row("Date", timezone.now().strftime("%B %d, %Y"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Referral reward of ৳{reward_amount} claimed.", html)


def send_password_reset_email(user, otp):
    """Email with OTP for password reset"""
    name = user.name or user.first_name or user.username
    subject = "পাসওয়ার্ড রিসেট OTP"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার পাসওয়ার্ড রিসেট OTP:</p>

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
    subject = "মোবাইল রিচার্জ সফল হয়েছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার মোবাইল রিচার্জ সফলভাবে কমপ্লিট হয়েছে!</p>

{_info_table(
    _info_row("Recharge Amount", f"৳{amount}") +
    _info_row("Phone Number", phone_number) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">Thank you for using AdsyClub mobile recharge service.</p>
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"Mobile recharge successful: ৳{amount}", html)


def send_password_changed_email(user):
    """Confirm to a user that their account password was changed."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার AdsyClub পাসওয়ার্ড পরিবর্তন করা হয়েছে"
    text = (
        f"হ্যালো {name}, আপনার AdsyClub অ্যাকাউন্টের পাসওয়ার্ড এইমাত্র পরিবর্তন করা হয়েছে। "
        "এটি আপনি না করে থাকলে অবিলম্বে রিসেট করুন ও সাপোর্টে যোগাযোগ করুন।"
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার AdsyClub অ্যাকাউন্টের পাসওয়ার্ড এইমাত্র পরিবর্তন করা হয়েছে।</p>

{_info_table(
    _info_row("Account", user.email or "N/A") +
    _info_row("Changed on", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">If you made this change, no further action is needed.</p>
{_button("Go to AdsyClub", SITE_URL)}
"""

    html = _base_template(
        subject, body,
        "If you did NOT change your password, reset it right away and contact our "
        f"support team at {SUPPORT_EMAIL} or {SUPPORT_PHONE}.",
    )
    return _send_email(subject, user.email, text, html)


def send_product_order_email(seller, order, items):
    """Notify a store owner that they received a new product order."""
    if not seller or not seller.email:
        return False
    name = seller.name or seller.first_name or "there"
    subject = "🛍️ আপনি একটি নতুন অর্ডার পেয়েছেন"

    item_rows = ""
    for it in items:
        product_name = it.product.name if getattr(it, "product", None) else "Product"
        item_rows += _info_row(f"{product_name} × {it.quantity}", f"৳{it.price}")

    text = (
        f"Hi {name}, you received a new order (#{order.order_number}) on AdsyClub. "
        "Please review and process it."
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুসংবাদ — আপনার স্টোরে একটি <strong>নতুন অর্ডার</strong> এসেছে। দ্রুত দেখে প্রক্রিয়া করুন।</p>

{_info_table(
    _info_row("Order No", f"#{order.order_number}") +
    item_rows +
    _info_row("Buyer", order.name or "N/A") +
    _info_row("Phone", order.phone or "N/A") +
    _info_row("ডেলিভারি ঠিকানা", order.address or "N/A") +
    _info_row("পেমেন্ট",order.get_payment_method_display() if hasattr(order, "get_payment_method_display") else (order.payment_method or "N/A"))
)}

{_button("অর্ডার ম্যানেজ করুন", SITE_URL + "/shop-manager")}
"""

    html = _base_template(
        subject, body,
        "Process this order promptly to keep your store rating high. Need help? "
        f"Contact {SUPPORT_EMAIL}.",
    )
    return _send_email(subject, seller.email, text, html)


def send_order_confirmation_email(buyer, order):
    """Order confirmation to the customer with full order + payment details."""
    email = (getattr(buyer, "email", None) if buyer else None) or getattr(order, "email", None)
    if not email:
        return False
    name = (getattr(buyer, "name", None) if buyer else None) or order.name or "there"
    subject = f"অর্ডার নিশ্চিত হয়েছে — #{order.order_number}"

    item_rows = ""
    try:
        order_items = order.items.select_related("product").all()
    except Exception:
        order_items = []
    for it in order_items:
        product_name = it.product.name if getattr(it, "product", None) else "Product"
        item_rows += _info_row(f"{product_name} × {it.quantity}", f"৳{it.price}")

    pay_method = (
        order.get_payment_method_display()
        if hasattr(order, "get_payment_method_display")
        else (order.payment_method or "N/A")
    )
    order_status = (
        order.get_order_status_display()
        if hasattr(order, "get_order_status_display")
        else (order.order_status or "Pending")
    )

    text = (
        f"Hi {name}, your AdsyClub order #{order.order_number} is confirmed. "
        f"Total: ৳{order.total}."
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার অর্ডারের জন্য ধন্যবাদ! 🎉 নিচে আপনার অর্ডার ও পেমেন্টের বিবরণ দেওয়া হলো।</p>

{_info_table(
    _info_row("Order No", f"#{order.order_number}") +
    item_rows +
    _info_row("Delivery fee", f"৳{order.delivery_fee}") +
    _info_row("Total paid", f"৳{order.total}") +
    _info_row("পেমেন্ট মাধ্যম", pay_method) +
    _info_row("স্ট্যাটাস", order_status) +
    _info_row("ডেলিভারি ঠিকানা", order.address or "N/A")
)}

{_button("আমার অর্ডার দেখুন", SITE_URL + "/order/" + str(order.id))}
"""

    html = _base_template(
        subject, body,
        "We'll keep you posted as your order is processed and shipped. "
        f"Need help? Contact {SUPPORT_EMAIL} or {SUPPORT_PHONE}.",
    )
    return _send_email(subject, email, text, html)


def send_withdraw_rejected_email(user, amount, transaction_id, reason=""):
    """Notify a user their withdrawal was rejected and the amount refunded."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "উইথড্র রিকোয়েস্ট বাতিল হয়েছে"
    text = (
        f"Hi {name}, your withdrawal request of ৳{amount} could not be approved "
        f"and the amount has been refunded to your Adsy Pay balance."
    )
    reason_row = _info_row("কারণ", reason) if reason else ""
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">এবার আপনার উইথড্র রিকোয়েস্ট অ্যাপ্রুভ করা যায়নি। সম্পূর্ণ টাকা <strong>আপনার Adsy Pay ব্যালেন্সে ফেরত</strong> দেওয়া হয়েছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("Reference", str(transaction_id)) +
    reason_row +
    _info_row("স্ট্যাটাস", "বাতিল — টাকা ফেরত")
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""
    html = _base_template(
        subject, body,
        f"If you have questions about this, contact {SUPPORT_EMAIL} or {SUPPORT_PHONE}.",
    )
    return _send_email(subject, user.email, text, html)


def send_kyc_received_email(user):
    """Confirm that a KYC submission was received and is under review."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আমরা আপনার ভেরিফিকেশন রিকোয়েস্ট পেয়েছি"
    text = (
        f"Hi {name}, we've received your identity verification (KYC) and it is "
        "now under review. We'll email you once it's processed."
    )
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">ধন্যবাদ — আমরা আপনার পরিচয় যাচাই (KYC) সাবমিশন পেয়েছি। আমাদের টিম এখন এটি পর্যালোচনা করছে।</p>

{_info_table(
    _info_row("স্ট্যাটাস", "পর্যালোচনাধীন") +
    _info_row("Submitted", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">Reviews are usually completed within 24–48 hours. We'll email you as soon as it's done.</p>
"""
    html = _base_template(
        subject, body,
        "You don't need to do anything else right now.",
    )
    return _send_email(subject, user.email, text, html)


def send_post_approved_email(user, title, kind="post", link=""):
    """Notify a user that their post/listing was approved and is now live."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার {kind} এখন লাইভ 🎉"
    text = f"হ্যালো {name}, আপনার {kind} \"{title}\" অ্যাপ্রুভ হয়ে গেছে — এখন AdsyClub-এ লাইভ।"
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুসংবাদ — আপনার {kind} <strong>অ্যাপ্রুভ</strong> হয়েছে এবং এখন AdsyClub-এ লাইভ। 🎉</p>

{_info_table(
    _info_row(kind.capitalize(), title or "—") +
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভড ও লাইভ")
)}

{_button("View it", link or SITE_URL)}
"""
    html = _base_template(subject, body, "Thanks for contributing to the AdsyClub community.")
    return _send_email(subject, user.email, text, html)


def send_post_rejected_email(user, title, kind="post", reason="", link=""):
    """Notify a user that their post/listing was not approved."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার {kind} অ্যাপ্রুভ হয়নি"
    text = f"হ্যালো {name}, আপনার {kind} \"{title}\" অ্যাপ্রুভ হয়নি।"
    reason_row = _info_row("কারণ", reason) if reason else ""
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার সাবমিশনের জন্য ধন্যবাদ। দুঃখিত, এই মুহূর্তে আপনার {kind} <strong>অ্যাপ্রুভ করা যায়নি</strong>।</p>

{_info_table(
    _info_row(kind.capitalize(), title or "—") +
    reason_row +
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভ হয়নি")
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">You're welcome to edit it to meet our guidelines and submit again.</p>
{_button("Review &amp; edit", link or SITE_URL)}
"""
    html = _base_template(
        subject, body,
        f"Questions? Contact {SUPPORT_EMAIL} and we'll be glad to help.",
    )
    return _send_email(subject, user.email, text, html)


def send_post_received_email(user, title, kind="post", link=""):
    """Confirm a post/listing was received and is under review."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার {kind} পর্যালোচনাধীন"
    text = f"হ্যালো {name}, আমরা আপনার {kind} \"{title}\" পেয়েছি এবং এটি এখন পর্যালোচনাধীন।"
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার সাবমিশনের জন্য ধন্যবাদ! আমরা আপনার {kind} পেয়েছি এবং আমাদের টিম এটি পর্যালোচনা করছে। অ্যাপ্রুভড ও লাইভ হওয়ার সঙ্গে সঙ্গে আপনি একটি ইমেইল পাবেন।</p>

{_info_table(
    _info_row(kind.capitalize(), title or "—") +
    _info_row("স্ট্যাটাস", "পর্যালোচনাধীন") +
    _info_row("Submitted", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">Reviews are usually completed within a few hours.</p>
{_button("View submission", link or SITE_URL)}
"""
    html = _base_template(subject, body, "You don't need to do anything else right now.")
    return _send_email(subject, user.email, text, html)


def send_driver_approved_email(user):
    """Notify a rideshare driver that their application was approved."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার ড্রাইভার আবেদন অ্যাপ্রুভ হয়েছে 🚗"
    text = f"হ্যালো {name}, আপনার AdsyClub ড্রাইভার আবেদন অ্যাপ্রুভ হয়েছে। এখন আপনি অনলাইনে গিয়ে রাইড নিতে পারবেন।"
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">অভিনন্দন — আপনার ড্রাইভার আবেদন <strong>অ্যাপ্রুভ</strong> হয়েছে! এখন আপনি অনলাইনে গিয়ে রাইড রিকোয়েস্ট নিতে শুরু করতে পারবেন। 🚗</p>

{_info_table(
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভড") +
    _info_row("Next step", "Go online in the app to receive rides")
)}

{_button("AdsyClub খুলুন", SITE_URL)}
"""
    html = _base_template(subject, body, "Drive safely and provide great service to earn top ratings.")
    return _send_email(subject, user.email, text, html)


def send_driver_rejected_email(user, reason=""):
    """Notify a rideshare driver that their application was not approved."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার ড্রাইভার আবেদনের আপডেট"
    text = f"হ্যালো {name}, আপনার AdsyClub ড্রাইভার আবেদন অ্যাপ্রুভ হয়নি।"
    reason_row = _info_row("কারণ", reason) if reason else ""
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">AdsyClub-এ ড্রাইভার হিসেবে আবেদন করার জন্য ধন্যবাদ। পর্যালোচনার পর এই মুহূর্তে আপনার আবেদন <strong>অ্যাপ্রুভ করা যায়নি</strong>।</p>

{_info_table(
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভ হয়নি") +
    reason_row
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">You may update your details and re-apply.</p>
"""
    html = _base_template(
        subject, body,
        f"For details, contact {SUPPORT_EMAIL} or {SUPPORT_PHONE}.",
    )
    return _send_email(subject, user.email, text, html)


def send_ride_receipt_email(ride):
    """Send the rider a trip receipt when a ride is completed."""
    rider = getattr(ride, "rider", None)
    if not rider or not getattr(rider, "email", ""):
        return False
    name = rider.name or rider.first_name or "there"
    fare = ride.final_fare or ride.fare_estimate or 0
    distance = ride.distance_km
    minutes = int((ride.duration_seconds or 0) / 60)
    pay = (
        ride.get_payment_method_display()
        if hasattr(ride, "get_payment_method_display")
        else (ride.payment_method or "N/A")
    )
    driver = getattr(ride, "assigned_driver", None)
    driver_name = (driver.name or driver.first_name) if driver else ""

    subject = "আপনার রাইড রসিদ 🚗"
    text = f"হ্যালো {name}, AdsyClub-এ রাইড নেওয়ার জন্য ধন্যবাদ। মোট ভাড়া: ৳{fare}।"
    driver_row = _info_row("Driver", driver_name) if driver_name else ""

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">AdsyClub-এ রাইড নেওয়ার জন্য ধন্যবাদ! এই যে আপনার ট্রিপ রসিদ।</p>

{_info_table(
    _info_row("From", ride.pickup_address or "—") +
    _info_row("To", ride.drop_address or "—") +
    _info_row("Distance", f"{distance} km") +
    (_info_row("Duration", f"{minutes} min") if minutes else "") +
    driver_row +
    _info_row("পেমেন্ট",pay) +
    _info_row("মোট ভাড়া",f"<strong>৳{fare}</strong>")
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">Don't forget to rate your driver in the app — it helps keep AdsyClub rides great.</p>
{_button("AdsyClub খুলুন", SITE_URL)}
"""
    html = _base_template(subject, body, "We hope you enjoyed your ride. See you next time!")
    return _send_email(subject, rider.email, text, html)


def send_support_reply_email(ticket, reply_message=""):
    """Notify a ticket owner that support replied to their ticket."""
    user = getattr(ticket, "user", None)
    if not user or not getattr(user, "email", ""):
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার সাপোর্ট টিকেটে নতুন রিপ্লাই"
    msg = (reply_message or "").strip()
    preview = (msg[:240] + "…") if len(msg) > 240 else msg
    text = f"হ্যালো {name}, AdsyClub সাপোর্ট টিম আপনার টিকেট \"{ticket.title}\"-এ রিপ্লাই দিয়েছে।"

    quote = (
        f"""<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f8fafc;border-radius:10px;margin:16px 0;">
<tr><td style="padding:14px 16px;"><p style="margin:0;color:#334155;font-size:14px;line-height:1.6;">{preview}</p></td></tr>
</table>"""
        if preview else ""
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 8px;">আমাদের সাপোর্ট টিম আপনার টিকেট <strong>"{ticket.title}"</strong>-এ রিপ্লাই দিয়েছে:</p>
{quote}
{_button("দেখুন ও রিপ্লাই দিন", SITE_URL + "/support")}
"""
    html = _base_template(
        subject, body,
        "Reply from the app or website to continue the conversation with our team.",
    )
    return _send_email(subject, user.email, text, html)


def send_test_email(to_email=None):
    """Send a test email to verify SMTP configuration"""
    if not to_email:
        email_settings = _get_email_settings()
        to_email = email_settings['admin_email']
    
    subject = "AdsyClub ইমেইল কনফিগারেশন টেস্ট"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার SMTP কনফিগারেশন ঠিকভাবে কাজ করছে কিনা যাচাই করতে এটি একটি টেস্ট ইমেইল।</p>

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
    subject = "নতুন ইউজার রেজিস্ট্রেশন"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">AdsyClub-এ একজন নতুন ইউজার রেজিস্টার করেছেন।</p>

{_info_table(
    _info_row("নাম", name) +
    _info_row("ইমেইল", user.email or "N/A") +
    _info_row("ফোন", user.phone or "N/A") +
    _info_row("Referred By", str(user.refer) if user.refer else "Direct") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_admin_button("View in Admin", SITE_URL + "/admin/base/user/")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, _admin_recipients(), f"New user registered: {name} ({user.email})", html)


def notify_admin_new_recharge(recharge):
    """Notify admin when a user submits a mobile recharge request, so it can be
    processed/approved promptly."""
    user = recharge.user
    name = (user.name or user.first_name or user.username) if user else "Unknown"
    operator = recharge.operator.name if recharge.operator else "N/A"
    subject = "নতুন মোবাইল রিচার্জ রিকোয়েস্ট"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">একজন ইউজার একটি মোবাইল রিচার্জ রিকোয়েস্ট জমা দিয়েছেন যা প্রক্রিয়া করা প্রয়োজন।</p>

{_info_table(
    _info_row("ইউজার", name) +
    _info_row("রিচার্জ নম্বর", recharge.phone_number) +
    _info_row("অপারেটর", operator) +
    _info_row("পরিমাণ", f"৳{recharge.amount}") +
    _info_row("স্ট্যাটাস", recharge.get_status_display()) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_admin_button("View in Admin", SITE_URL + "/admin/mobile_recharge/recharge/")}
"""

    html = _base_template(subject, body)
    return _send_email(
        subject,
        _admin_recipients(),
        f"New recharge request: {recharge.phone_number} (৳{recharge.amount})",
        html,
    )


def notify_admin_withdrawal_request(user, amount, payment_method, payment_number):
    """Notify admin when a withdrawal request is made"""
    name = user.name or user.first_name or user.username
    subject = "নতুন উইথড্র রিকোয়েস্ট"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">একজন ইউজার একটি উইথড্র রিকোয়েস্ট জমা দিয়েছেন।</p>

{_info_table(
    _info_row("ইউজার", name) +
    _info_row("ইমেইল", user.email or "N/A") +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("মাধ্যম", payment_method or "N/A") +
    _info_row("অ্যাকাউন্ট", payment_number or "N/A") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_admin_button("Review in Admin", SITE_URL + "/admin/base/balance/")}
"""

    html = _base_template(subject, body, "Please review and approve/reject this withdrawal request.")
    return _send_email(subject, _admin_recipients(), f"Withdrawal request: ৳{amount} by {name}", html)


def notify_admin_kyc_submission(user):
    """Notify admin when a KYC is submitted"""
    name = user.name or user.first_name or user.username
    subject = "নতুন KYC সাবমিশন"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">একজন ইউজার যাচাইয়ের জন্য KYC ডকুমেন্ট জমা দিয়েছেন।</p>

{_info_table(
    _info_row("ইউজার", name) +
    _info_row("ইমেইল", user.email or "N/A") +
    _info_row("ফোন", user.phone or "N/A") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_admin_button("Review KYC", SITE_URL + "/admin/base/nid/")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, _admin_recipients(), f"KYC submission from {name}", html)


def notify_admin_user_blocked(blocker, blocked_user, reason=""):
    """Notify admin when a user is blocked — required by Apple App Store Guideline 1.2 (UGC moderation)"""
    blocker_name = blocker.name or blocker.first_name or blocker.username or "Unknown"
    blocked_name = blocked_user.name or blocked_user.first_name or blocked_user.username or "Unknown"
    subject = "ইউজার ব্লক রিপোর্ট — ব্যবস্থা প্রয়োজন"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">একজন ইউজার AdsyClub-এ অন্য একজন ইউজারকে ব্লক করেছেন। সম্ভাব্য নীতি লঙ্ঘনের জন্য ব্লককৃত অ্যাকাউন্টটি পর্যালোচনা করুন।</p>

{_info_table(
    _info_row("Reported By (Blocker)", f"{blocker_name} (@{blocker.username})") +
    _info_row("Blocker Email", blocker.email or "N/A") +
    _info_row("Blocked User", f"{blocked_name} (@{blocked_user.username})") +
    _info_row("Blocked Email", blocked_user.email or "N/A") +
    _info_row("Reason", reason or "Not specified") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#ef4444;font-size:14px;line-height:1.6;margin:16px 0;font-weight:600;">⚠️ Please review the blocked user's content and account within 24 hours per our content moderation policy.</p>

{_admin_button("Review Blocked Users", SITE_URL + "/admin/adsyconnect/blockeduser/")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, _admin_recipients(), f"User block report: {blocker_name} blocked {blocked_name}", html)


# ============================================================
# ENGAGEMENT / BRAIN-ENGINE EMAILS
# (helpful, personalised emails sent by engagement.tasks.run_email_engine —
#  the email counterpart of the push nudge/promo brain)
# ============================================================

def _engagement_product_cards(limit=3):
    """Render up to `limit` random live products as 'discover' cards so emails
    can showcase real, dynamic content from the eShop. Returns '' on any
    error / no products so a content hiccup never blocks the email."""
    try:
        from base.models import Product
        try:
            from base.views import public_product_queryset
            qs = public_product_queryset(Product.objects.all())
        except Exception:
            qs = Product.objects.all()
        products = list(qs.order_by("?")[:limit])
        if not products:
            return ""
        cards = ""
        for p in products:
            name = (getattr(p, "name", "") or "পণ্য")[:60]
            price = (getattr(p, "sale_price", None) or getattr(p, "regular_price", None)
                     or getattr(p, "price", None))
            slug = (getattr(p, "slug", "") or "").strip()
            url = f"{SITE_URL}/product-details/{slug}" if slug else f"{SITE_URL}/eshop"
            img = ""
            try:
                main = p.image.first()
                if main and getattr(main, "image", None):
                    img = main.image.url
                    if not img.startswith("http"):
                        img = f"{SITE_URL}{img}"
            except Exception:
                pass
            img_html = (
                f'<img src="{img}" width="56" height="56" style="border-radius:8px;object-fit:cover;display:block;" />'
                if img else ""
            )
            price_html = (
                f'<div style="color:{BRAND_COLOR};font-weight:700;font-size:14px;">৳{price}</div>'
                if price else ""
            )
            cards += f"""
<a href="{url}" style="display:block;text-decoration:none;border:1px solid #e5e7eb;border-radius:10px;padding:10px;margin:0 0 8px;">
  <table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr>
    <td width="56" valign="top">{img_html}</td>
    <td valign="top" style="padding-left:10px;">
      <div style="color:#111827;font-size:14px;font-weight:600;">{name}</div>
      {price_html}
    </td>
  </tr></table>
</a>"""
        return f'<div style="margin:14px 0;">{cards}</div>'
    except Exception:
        return ""


def _engagement_area_cards(limit=6):
    """A row of real service-area names from the geo DB — for rideshare emails, so
    they feel local and specific. '' on any error / no areas."""
    try:
        from cities.models import Upazila
        names = [
            n for n in Upazila.objects.order_by("?").values_list("name_eng", flat=True)[:limit]
            if n and n.strip()
        ]
        if not names:
            return ""
        chips = "".join(
            '<span style="display:inline-block;background:#f1f5f9;color:#334155;'
            'border-radius:14px;padding:5px 12px;margin:0 6px 6px 0;font-size:13px;">'
            f'📍 {n.strip()}</span>'
            for n in names
        )
        return (
            '<div style="margin:14px 0;">'
            '<div style="color:#6b7280;font-size:13px;margin:0 0 8px;">যেসব এলাকায় রাইড পাওয়া যাচ্ছে:</div>'
            f'{chips}</div>'
        )
    except Exception:
        return ""


def _engagement_content_html(feature):
    """Dynamic, feature-appropriate content block for an engagement email —
    real eShop products, real rideshare service areas, etc."""
    if feature == "eshop":
        return _engagement_product_cards()
    if feature == "rideshare":
        return _engagement_area_cards()
    return ""


def send_engagement_email(user, *, subject, heading, body_html,
                          button_text="", button_url="", content_feature=None):
    """Generic brain-engine email: a personal heading + helpful body, optional
    dynamic feature-appropriate content (real eShop products, rideshare service
    areas, ...), and a CTA. Fire-and-forget; no-op without an email."""
    email = getattr(user, "email", None)
    if not email:
        return False
    # Respect unsubscribes + skip bounced/invalid addresses (engagement mail
    # only — transactional mail does not call this function).
    if is_email_suppressed(email):
        return False
    name = (getattr(user, "name", None) or getattr(user, "first_name", None) or "বন্ধু")
    cards = _engagement_content_html(content_feature)
    # The base template already shows `subject` as the big <h2> title at the
    # top, so repeating it as an in-body heading is a duplicate. Only render
    # the heading paragraph when it actually differs from the subject.
    heading_html = ""
    if heading and heading.strip() and heading.strip() != (subject or "").strip():
        heading_html = (
            '<p style="color:#111827;font-size:16px;line-height:1.5;'
            f'margin:0 0 14px;font-weight:600;">{heading}</p>'
        )
    # Marketing/followup emails KEEP their action CTA (it's the point of the
    # email) — the global _button() is disabled for transactional mail, so render
    # the CTA inline here.
    cta = ""
    if button_text and button_url:
        cta = (f'<div style="text-align:center;margin:26px 0 4px;">'
               f'<a href="{button_url}" style="display:inline-block;padding:13px 36px;background:{BRAND_GRADIENT};'
               f'color:#ffffff;text-decoration:none;border-radius:10px;font-size:15px;font-weight:700;">{button_text}</a></div>')
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 12px;">প্রিয় <strong>{name}</strong>,</p>
{heading_html}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">{body_html}</p>
{cards}
{cta}
"""
    # The base footer already carries a one-click Unsubscribe link, so the note
    # above it just explains why they're getting the email (no duplicate link).
    footer_note = "আপনি AdsyClub-এর সদস্য বলে এই ইমেইলটি পাচ্ছেন।"
    html = _base_template(subject, body, footer_note)
    return _send_email(subject, email, f"{name}, {heading}", html)
