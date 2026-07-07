"""
AdsyClub Email Service
Professional email templates with white/light gray theme.
All transactional emails for users and admin notifications.
"""
import logging
import random
from datetime import timedelta
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
  .ec-wrap {{ padding-left:4px !important; padding-right:4px !important; padding-top:16px !important; }}
  .ec-pad {{ padding-left:16px !important; padding-right:16px !important; }}
  /* CTA buttons stretch full-width on phones for an easy tap target. */
  .ec-btn-wrap {{ width:100% !important; }}
  .ec-btn {{ display:block !important; }}
  .ec-btn a {{ display:block !important; text-align:center !important; }}
  /* Key column narrows so values keep room on small screens. */
  .ec-k {{ width:104px !important; }}
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
<td class="ec-k" style="padding:8px 12px;color:#6b7280;font-size:14px;border-bottom:1px solid #f3f4f6;width:140px;">{label}</td>
<td style="padding:8px 12px;color:#111827;font-size:14px;font-weight:500;border-bottom:1px solid #f3f4f6;word-break:break-word;">{value}</td>
</tr>"""


def _info_table(rows_html):
    """Wrapper for info table"""
    return f"""<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#f9fafb;border-radius:8px;overflow:hidden;border:1px solid #e5e7eb;margin:16px 0;">
{rows_html}
</table>"""


def _button(text, url):
    """In-body action as a quiet right-aligned text-and-arrow link — big
    filled buttons read as generic; this stays professional and scannable."""
    return f"""<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:14px 0 4px;">
<tr><td align="right">
<a href="{url}" style="color:#059669;font-size:14px;font-weight:700;text-decoration:none;">{text}&nbsp;&#8594;</a>
</td></tr>
</table>"""


_PROMO_SERVICES = [
    ("eshop", "eShop", "\u09a6\u09b0\u0995\u09be\u09b0\u09bf \u09aa\u09a3\u09cd\u09af \u09b8\u09c7\u09b0\u09be \u09a6\u09be\u09ae\u09c7", "/eshop", "#EA580C"),
    ("bn", "Business Network", "\u09aa\u09c7\u09b6\u09be\u09a6\u09be\u09b0\u09a6\u09c7\u09b0 \u0995\u09ae\u09bf\u0989\u09a8\u09bf\u099f\u09bf \u2014 \u09aa\u09cb\u09b8\u09cd\u099f, \u09ab\u09b2\u09cb, \u09a8\u09c7\u099f\u0993\u09af\u09bc\u09be\u09b0\u09cd\u0995", "/business-network", "#2563EB"),
    ("earn", "\u09ae\u09be\u0987\u0995\u09cd\u09b0\u09cb \u0997\u09bf\u0997\u09b8", "\u099b\u09cb\u099f \u099b\u09cb\u099f \u099f\u09be\u09b8\u09cd\u0995 \u0995\u09b0\u09c7 \u0987\u09a8\u0995\u09be\u09ae", "/#earn", "#7C3AED"),
    ("sheba", "\u0986\u09ae\u09be\u09b0 \u09b8\u09c7\u09ac\u09be", "\u09ac\u09bf\u099c\u09cd\u099e\u09be\u09aa\u09a8 \u09a6\u09bf\u09a8, \u0995\u09cd\u09b0\u09c7\u09a4\u09be \u0996\u09c1\u0981\u099c\u09c1\u09a8", "/", "#0D9488"),
    ("recharge", "\u09ae\u09cb\u09ac\u09be\u0987\u09b2 \u09b0\u09bf\u099a\u09be\u09b0\u09cd\u099c", "\u09af\u09c7\u0995\u09cb\u09a8\u09cb \u09a8\u09ae\u09cd\u09ac\u09b0\u09c7 \u0987\u09a8\u09b8\u09cd\u099f\u09cd\u09af\u09be\u09a8\u09cd\u099f \u09b0\u09bf\u099a\u09be\u09b0\u09cd\u099c", "/mobile-recharge", "#DC2626"),
]

_PROMO_HEADING = "AdsyClub-\u098f \u0986\u09b0\u0993 \u09af\u09be \u09af\u09be \u0986\u099b\u09c7"


def _promo_list_html(items):
    """Variant A: slim rows with a colored keyline per service."""
    rows = "".join(
        f'''<tr><td style="padding:7px 0;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr>
<td width="3" style="background-color:{color};border-radius:3px;font-size:0;">&nbsp;</td>
<td style="padding:2px 0 2px 12px;">
<a href="{SITE_URL}{path}" style="text-decoration:none;">
<span style="color:#0F172A;font-size:13.5px;font-weight:700;">{title}</span>
<span style="color:#64748B;font-size:13px;"> &mdash; {desc}</span></a>
</td></tr></table></td></tr>'''
        for key, title, desc, path, color in items
    )
    return f'''<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:22px 0 0;border-top:1px solid #E5E7EB;">
<tr><td style="padding:16px 0 6px;color:#0F172A;font-size:14px;font-weight:700;">{_PROMO_HEADING}</td></tr>
{rows}
</table>'''


def _promo_grid_html(items):
    """Variant B: two tinted cards side by side."""
    cells = "".join(
        f'''<td width="50%" valign="top" style="padding:5px;">
<a href="{SITE_URL}{path}" style="text-decoration:none;display:block;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#F8FAFC;border:1px solid #E5E7EB;border-radius:12px;">
<tr><td style="padding:14px;">
<div style="color:{color};font-size:14px;font-weight:800;">{title}</div>
<div style="color:#475569;font-size:12.5px;line-height:1.5;margin-top:4px;">{desc}</div>
</td></tr></table></a></td>'''
        for key, title, desc, path, color in items[:2]
    )
    return f'''<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:22px 0 0;border-top:1px solid #E5E7EB;">
<tr><td style="padding:16px 0 4px;color:#0F172A;font-size:14px;font-weight:700;">{_PROMO_HEADING}</td></tr>
</table>
<table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr>{cells}</tr></table>'''


def _promo_spotlight_html(items):
    """Variant C: one service in a full-width tinted spotlight."""
    key, title, desc, path, color = items[0]
    return f'''<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:22px 0 0;">
<tr><td style="background-color:#F8FAFC;border:1px solid #E5E7EB;border-left:4px solid {color};border-radius:12px;padding:16px 18px;">
<div style="color:#64748B;font-size:11px;font-weight:700;letter-spacing:0.6px;text-transform:uppercase;">AdsyClub</div>
<div style="color:{color};font-size:16px;font-weight:800;margin-top:3px;">{title}</div>
<div style="color:#475569;font-size:13px;line-height:1.55;margin-top:4px;">{desc}</div>
<div style="margin-top:8px;"><a href="{SITE_URL}{path}" style="color:{color};font-size:13px;font-weight:700;text-decoration:none;">\u09a6\u09c7\u0996\u09c7 \u09a8\u09bf\u09a8&nbsp;&#8594;</a></div>
</td></tr></table>'''


def _service_promo_html(exclude=""):
    """Cross-sell block appended to transactional mail. The layout is picked
    at send time from three variants so mails never look templated-identical."""
    items = [svc for svc in _PROMO_SERVICES if svc[0] != exclude]
    random.shuffle(items)
    variant = random.choice([_promo_list_html, _promo_grid_html, _promo_spotlight_html])
    return variant(items[:3])


def _product_showcase_html(limit=2, heading="\u0986\u09aa\u09a8\u09be\u09b0 \u099c\u09a8\u09cd\u09af \u09ac\u09be\u099b\u09be\u0987"):
    """Real eShop products WITH photos, rendered as a two-card row. Pulled
    live from the catalog at send time — every mail doubles as a storefront."""
    try:
        from .models import Product

        candidates = list(
            Product.objects.filter(is_active=True, image__isnull=False)
            .distinct()
            .order_by("-created_at")[:16]
        )
        if not candidates:
            return ""
        picks = random.sample(candidates, min(limit, len(candidates)))
        cards = ""
        for prod in picks:
            media = prod.image.all().first()
            img_url = ""
            if media is not None and getattr(media, "image", None):
                try:
                    img_url = media.image.url
                except Exception:
                    img_url = ""
            if not img_url:
                continue
            price = prod.sale_price if (prod.sale_price or 0) > 0 else prod.regular_price
            link = f"{SITE_URL}/eshop/{prod.slug or prod.id}"
            name = (prod.name or "")[:48]
            cards += f'''<td width="50%" valign="top" style="padding:5px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="border:1px solid #E5E7EB;border-radius:12px;overflow:hidden;background-color:#ffffff;">
<tr><td><a href="{link}"><img src="{img_url}" width="100%" height="140" alt="{name}" style="display:block;width:100%;height:140px;object-fit:cover;border:0;"></a></td></tr>
<tr><td style="padding:10px 12px 12px;">
<a href="{link}" style="text-decoration:none;">
<div style="color:#0F172A;font-size:13px;font-weight:700;line-height:1.35;">{name}</div>
<div style="color:#059669;font-size:14px;font-weight:800;margin-top:5px;">\u09f3{price}</div>
</a></td></tr>
</table></td>'''
        if not cards:
            return ""
        return f'''<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:22px 0 0;border-top:1px solid #E5E7EB;">
<tr><td style="padding:16px 0 4px;">
<span style="color:#0F172A;font-size:14px;font-weight:700;">{heading}</span>
<a href="{SITE_URL}/eshop" style="float:right;color:#059669;font-size:12.5px;font-weight:700;text-decoration:none;">\u09b8\u09ac \u09a6\u09c7\u0996\u09c1\u09a8&nbsp;&#8594;</a>
</td></tr></table>
<table role="presentation" width="100%" cellspacing="0" cellpadding="0"><tr>{cards}</tr></table>'''
    except Exception:
        return ""


def _people_row_html(people, heading):
    """Row of round profile photos + first names — the social layer inside
    the inbox. Links go straight to each Business Network profile."""
    cells = ""
    for u in people[:4]:
        img_url = ""
        if getattr(u, "image", None):
            try:
                img_url = u.image.url
            except Exception:
                img_url = ""
        if img_url:
            avatar = f'<img src="{img_url}" width="52" height="52" alt="" style="display:block;width:52px;height:52px;border-radius:50%;object-fit:cover;border:0;">'
        else:
            initial = ((getattr(u, "first_name", "") or getattr(u, "username", "") or "?")[:1]).upper()
            avatar = f'<table role="presentation" cellspacing="0" cellpadding="0"><tr><td width="52" height="52" align="center" style="width:52px;height:52px;border-radius:50%;background-color:#E0E7FF;color:#4338CA;font-size:20px;font-weight:700;">{initial}</td></tr></table>'
        first = ((getattr(u, "name", "") or getattr(u, "first_name", "") or getattr(u, "username", "") or "").split(" ") or [""])[0][:12]
        cells += f'''<td align="center" valign="top" style="padding:8px 6px;">
<a href="{SITE_URL}/business-network/profile/{u.id}" style="text-decoration:none;color:#0F172A;">
{avatar}
<div style="font-size:12px;font-weight:600;margin-top:6px;color:#0F172A;">{first}</div>
</a></td>'''
    if not cells:
        return ""
    return f'''<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin:18px 0 0;">
<tr><td style="padding:0 0 4px;color:#0F172A;font-size:14px;font-weight:700;">{heading}</td></tr>
</table>
<table role="presentation" cellspacing="0" cellpadding="0"><tr>{cells}</tr></table>'''


def send_welcome_email(user):
    """Send welcome email to newly registered user"""
    name = user.name or user.first_name or user.username or "there"
    subject = "AdsyClub-এ স্বাগতম!"
    text = f"হ্যালো {name}, AdsyClub-এ স্বাগতম! আপনার অ্যাকাউন্ট রেডি হয়ে গেছে — এখনই ঢুকে ঘুরে দেখুন।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;"><strong>{SITE_NAME}</strong>-এ স্বাগতম! আপনার অ্যাকাউন্ট রেডি হয়ে গেছে — এখন আপনিও বাংলাদেশের অন্যতম সোশ্যাল বিজনেস নেটওয়ার্কের একজন। চলুন, শুরু করা যাক!</p>

{_info_table(
    _info_row("নাম", name) +
    _info_row("ইমেইল", user.email or "N/A") +
    _info_row("ফোন", user.phone or "N/A") +
    _info_row("রেফারেল কোড", user.referral_code or "N/A")
)}

<p style="color:#374151;font-size:15px;line-height:1.6;margin:16px 0;">AdsyClub-এ আপনি যা যা করতে পারবেন:</p>
<ul style="color:#374151;font-size:14px;line-height:2;padding-left:20px;margin:0 0 16px;">
<li><strong>Business Network</strong> – পেশাদারদের সাথে যুক্ত হোন</li>
<li><strong>eShop</strong> – দরকারি পণ্য কিনুন সেরা দামে</li>
<li><strong>পুরোনো কেনাবেচা</strong> – ব্যবহৃত জিনিস কেনাবেচা করুন</li>
<li><strong>Workspace Gigs</strong> – কাজ দিন বা কাজ নিন</li>
<li><strong>AdsyConnect</strong> – চ্যাট, ভয়েস ও ভিডিও কল</li>
<li><strong>eLearning</strong> – নতুন স্কিল শিখুন</li>
</ul>
{_product_showcase_html(2)}
"""

    html = _base_template(subject, body, "এই অ্যাকাউন্টটা যদি আপনি না খুলে থাকেন, আমাদের সাপোর্ট টিমকে জানান।")
    return _send_email(subject, user.email, text, html)


def send_profile_completion_email(user):
    """Confirmation mail sent when the user finishes the mandatory profile
    step (name + phone + date of birth) right after registration. Unlike the
    welcome mail — which goes out before the phone exists — this one carries
    the phone number, the live completion percentage and exactly which steps
    are still left."""
    from .serializers import compute_profile_completion

    name = user.name or user.first_name or user.username or "there"
    percentage, missing = compute_profile_completion(user)

    subject = f"প্রোফাইল আপডেট হয়ে গেছে — {percentage}% কমপ্লিট ✅"
    text = (
        f"হ্যালো {name}, আপনার প্রোফাইল আপডেট হয়ে গেছে। "
        f"এখন {percentage}% কমপ্লিট — বাকিটুকুও সেরে ফেলুন!"
    )

    if missing:
        missing_items = "".join(
            f'<li style="margin:0 0 6px;">{step.get("label", step.get("key", ""))}</li>'
            for step in missing
        )
        missing_block = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:16px 0 8px;"><strong>যা এখনো বাকি আছে:</strong></p>
<ul style="color:#374151;font-size:14px;line-height:1.7;padding-left:20px;margin:0 0 16px;">
{missing_items}
</ul>
<p style="color:#6B7280;font-size:13.5px;line-height:1.6;margin:0 0 16px;">প্রোফাইল ১০০% করে ফেললে আপনাকে আরও বিশ্বাসযোগ্য দেখাবে, আর {SITE_NAME}-এর সব ফিচার পুরোপুরি খুলে যাবে। এক মিনিটেই হয়ে যায়!</p>
"""
    else:
        missing_block = """
<p style="color:#047857;font-size:15px;line-height:1.6;margin:16px 0;"><strong>দারুণ! আপনার প্রোফাইল ১০০% কমপ্লিট</strong> এখন AdsyClub-এর সব ফিচার আপনার হাতের মুঠোয়।</p>
"""

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার <strong>{SITE_NAME}</strong> প্রোফাইল আপডেট হয়ে গেছে। আপনার তথ্যগুলো এক নজরে দেখে নিন:</p>

{_info_table(
    _info_row("নাম", name) +
    _info_row("ইমেইল", user.email or "N/A") +
    _info_row("ফোন", user.phone or "N/A")
)}

<p style="color:#374151;font-size:15px;line-height:1.6;margin:16px 0 8px;"><strong>প্রোফাইল সম্পূর্ণতা: {percentage}%</strong></p>
<div style="background:#E5E7EB;border-radius:999px;height:10px;overflow:hidden;margin:0 0 4px;">
  <div style="background:#10B981;height:10px;width:{percentage}%;border-radius:999px;"></div>
</div>
{missing_block}
"""

    html = _base_template(
        subject,
        body,
        "এই পরিবর্তন যদি আপনি না করে থাকেন, এখনই পাসওয়ার্ড বদলে আমাদের সাপোর্ট টিমকে জানান।",
    )
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
    ok = _send_email(subject, user.email, text, html, wait=True)
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
    subject = "টাকা পাঠানো হয়ে গেছে ✅"
    text = f"হ্যালো {name}, {receiver_name}-কে ৳{amount} পাঠানো হয়ে গেছে। বিস্তারিত অ্যাপে দেখে নিন।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার টাকা পাঠানো হয়ে গেছে — বিস্তারিত নিচে দেখে নিন 👇</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("প্রাপক", receiver_name) +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
{_service_promo_html("")}
"""

    html = _base_template(subject, body, "এই ট্রান্সফারটা আপনি না করে থাকলে এখনই আমাদের সাপোর্ট টিমকে জানান।")
    return _send_email(subject, sender_user.email, text, html)


def send_transfer_received_email(receiver_user, sender_user, amount, transaction_id):
    """Email to receiver after receiving fund transfer"""
    name = receiver_user.name or receiver_user.first_name or receiver_user.username
    sender_name = sender_user.name or sender_user.first_name or sender_user.username
    subject = "আপনার ওয়ালেটে টাকা চলে এসেছে 💰"
    text = f"হ্যালো {name}, {sender_name} আপনাকে ৳{amount} পাঠিয়েছেন — টাকা ওয়ালেটে চলে এসেছে।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুখবর! আপনার AdsyClub ওয়ালেটে টাকা চলে এসেছে। বিস্তারিত নিচে দেখে নিন 👇</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("প্রেরক", sender_name) +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
{_service_promo_html("")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, receiver_user.email, text, html)


def send_deposit_email(user, amount, transaction_id, payment_method=""):
    """Email to user after successful deposit"""
    name = user.name or user.first_name or user.username
    subject = "ডিপোজিট হয়ে গেছে ✅"
    text = f"হ্যালো {name}, আপনার ৳{amount} ডিপোজিট হয়ে গেছে — টাকা ওয়ালেটে যোগ হয়ে গেছে।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার ডিপোজিট হয়ে গেছে — টাকা ওয়ালেটে যোগ হয়ে গেছে, এখনই ব্যবহার করতে পারবেন</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("মাধ্যম", payment_method or "Online Payment") +
    _info_row("Transaction ID", str(transaction_id)[:12]) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
{_service_promo_html("")}
{_product_showcase_html(2)}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, text, html)


def send_withdraw_email(user, amount, transaction_id, payment_method="", payment_number=""):
    """Email to user after withdrawal request"""
    name = user.name or user.first_name or user.username
    subject = "উইথড্রর অনুরোধ পেয়েছি — প্রসেস হচ্ছে"
    text = f"হ্যালো {name}, আপনার ৳{amount} উইথড্রর অনুরোধ পেয়ে গেছি — প্রসেস হচ্ছে। হয়ে গেলেই জানিয়ে দেব।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার উইথড্রর অনুরোধ পেয়ে গেছি, এখন প্রসেস হচ্ছে। হয়ে গেলেই মেইলে জানিয়ে দেব 👍</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("মাধ্যম", payment_method or "N/A") +
    _info_row("অ্যাকাউন্ট", payment_number or "N/A") +
    _info_row("স্ট্যাটাস", "প্রসেস হচ্ছে") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ট্রান্সঅ্যাকশন দেখুন", SITE_URL + "/deposit-withdraw")}
"""

    html = _base_template(subject, body, "উইথড্র সাধারণত ২৪–৪৮ ঘণ্টার মধ্যেই হয়ে যায়। কমপ্লিট হলে একটা কনফার্মেশন মেইল পেয়ে যাবেন।")
    return _send_email(subject, user.email, text, html)


def send_withdraw_approved_email(user, amount, transaction_id):
    """Email to user after withdrawal is approved"""
    name = user.name or user.first_name or user.username
    subject = "উইথড্র হয়ে গেছে — টাকা পাঠিয়ে দিয়েছি ✅"
    text = f"হ্যালো {name}, আপনার ৳{amount} উইথড্র অ্যাপ্রুভ হয়ে গেছে — টাকা আপনার অ্যাকাউন্টে পাঠিয়ে দিয়েছি।"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুখবর! আপনার উইথড্রর অনুরোধ <strong style="color:{BRAND_COLOR};">অ্যাপ্রুভ</strong> হয়ে গেছে — টাকা আপনার অ্যাকাউন্টে পাঠিয়ে দেওয়া হয়েছে</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভড ✓") +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
{_service_promo_html("")}
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
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার গিগ অর্ডার হয়ে গেছে ✅ বিক্রেতা কনফার্ম করলেই কাজ শুরু হয়ে যাবে।</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("বিক্রেতা", seller_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("স্ট্যাটাস", "কনফার্মেশনের অপেক্ষায়")
)}

{_button("অর্ডার দেখুন", SITE_URL + "/business-network/workspaces")}
"""
    buyer_html = _base_template("গিগ অর্ডার হয়ে গেছে ✅", buyer_body, "বিক্রেতা শিগগিরই আপনার অর্ডারটা দেখে অ্যাকসেপ্ট করবেন — আপডেট পেয়ে যাবেন মেইলে।")
    _send_email("গিগ অর্ডার হয়ে গেছে ✅", buyer.email, f"'{gig_title}' গিগের অর্ডার হয়ে গেছে — বিক্রেতা কনফার্ম করলেই কাজ শুরু।", buyer_html)

    # Email to seller
    seller_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{seller_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">দারুণ খবর — আপনার গিগে নতুন একটা অর্ডার এসেছে! দ্রুত দেখে নিন।</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("ক্রেতা", buyer_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("Order ID", str(order_id)[:12]) +
    _info_row("স্ট্যাটাস", "আপনার সাড়ার অপেক্ষায়")
)}

{_button("অর্ডার রিভিউ করুন", SITE_URL + "/business-network/workspaces")}
"""
    seller_html = _base_template("নতুন গিগ অর্ডার এসেছে", seller_body, "২৪ ঘণ্টার মধ্যে অর্ডারটা দেখে অ্যাকসেপ্ট বা ডিক্লাইন করে দিন — ক্রেতা অপেক্ষায় আছেন।")
    _send_email("নতুন গিগ অর্ডার এসেছে", seller.email, f"'{gig_title}' গিগে নতুন অর্ডার এসেছে — দেখে নিন।", seller_html)


def send_gig_order_completed_email(buyer, seller, gig_title, amount, order_id):
    """Email to both parties when a gig order is completed"""
    buyer_name = buyer.name or buyer.first_name or buyer.username
    seller_name = seller.name or seller.first_name or seller.username

    # Email to buyer
    buyer_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{buyer_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার গিগ অর্ডার <strong style="color:{BRAND_COLOR};">কমপ্লিট</strong> হয়ে গেছে, বিক্রেতাকে পেমেন্টও পাঠিয়ে দিয়েছি। কাজটা কেমন লাগল — একটা রিভিউ দিয়ে দিন</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("বিক্রেতা", seller_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("স্ট্যাটাস", "কমপ্লিট ✓")
)}

{_button("রিভিউ দিন", SITE_URL + "/business-network/workspaces")}
{_service_promo_html("earn")}
"""
    buyer_html = _base_template("গিগ অর্ডার কমপ্লিট হয়ে গেছে", buyer_body)
    _send_email("গিগ অর্ডার কমপ্লিট হয়ে গেছে", buyer.email, f"'{gig_title}' গিগের অর্ডারটা কমপ্লিট হয়ে গেছে — একটা রিভিউ দিয়ে দিন।", buyer_html)

    # Email to seller
    seller_body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{seller_name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">কাজ শেষ! গিগ অর্ডারটা কমপ্লিট হয়ে গেছে আর <strong style="color:{BRAND_COLOR};">৳{amount}</strong> আপনার ব্যালেন্সে যোগ হয়ে গেছে</p>

{_info_table(
    _info_row("গিগ", gig_title) +
    _info_row("ক্রেতা", buyer_name) +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("স্ট্যাটাস", "Payment Released ✓")
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
{_service_promo_html("earn")}
"""
    seller_html = _base_template("পেমেন্ট চলে এসেছে", seller_body)
    _send_email("পেমেন্ট চলে এসেছে — গিগ কমপ্লিট", seller.email, f"'{gig_title}' গিগের ৳{amount} আপনার ব্যালেন্সে যোগ হয়ে গেছে।", seller_html)


def send_gig_order_status_email(recipient_user, gig_title, order_id, new_status, actor_name=""):
    """Generic email for gig order status changes (accepted, declined, delivered, revision, cancelled)"""
    name = recipient_user.name or recipient_user.first_name or recipient_user.username

    status_labels = {
        "accepted": ("অর্ডার অ্যাকসেপ্ট হয়ে গেছে ✅", f"{actor_name} আপনার <strong>{gig_title}</strong> গিগ অর্ডারটা অ্যাকসেপ্ট করেছেন — কাজ শুরু হচ্ছে!", BRAND_COLOR),
        "in_progress": ("কাজ চলছে", f"আপনার <strong>{gig_title}</strong> গিগ অর্ডারের কাজ শুরু হয়ে গেছে। আপডেট পেতে থাকবেন।", "#3b82f6"),
        "delivered": ("অর্ডার ডেলিভার হয়ে গেছে", f"{actor_name} আপনার <strong>{gig_title}</strong> গিগ অর্ডারটা ডেলিভার করে দিয়েছেন। একটু দেখে নিন — সব ঠিকঠাক আছে কি না।", "#8b5cf6"),
        "revision": ("রিভিশন চাওয়া হয়েছে", f"<strong>{gig_title}</strong> গিগ অর্ডারে একটা রিভিশন চাওয়া হয়েছে — দেখে নিন কী বদলাতে হবে।", "#f59e0b"),
        "declined": ("অর্ডার ক্যানসেল হয়ে গেছে", f"{actor_name} <strong>{gig_title}</strong> গিগ অর্ডারটা ক্যানসেল করেছেন।", "#ef4444"),
        "cancelled": ("অর্ডার বাতিল হয়েছে", f"<strong>{gig_title}</strong> গিগ অর্ডারটা বাতিল হয়ে গেছে।", "#ef4444"),
    }

    label, desc, color = status_labels.get(new_status, ("অর্ডার আপডেট", f"আপনার গিগ অর্ডারের স্ট্যাটাস বদলেছে — দেখে নিন।", "#6b7280"))
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
    subject = "KYC অ্যাপ্রুভ হয়ে গেছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">দারুণ খবর — আপনার KYC ভেরিফিকেশন <strong style="color:{BRAND_COLOR};">অ্যাপ্রুভ</strong> হয়ে গেছে! এখন AdsyClub-এর সব ফিচার আপনার জন্য খোলা।</p>

{_button("ড্যাশবোর্ডে যান", SITE_URL + "/business-network")}
{_service_promo_html("")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"হ্যালো {name}, আপনার KYC অ্যাপ্রুভ হয়ে গেছে — সব ফিচার এখন খোলা!", html)


def send_kyc_rejected_email(user, reason=""):
    """Email when KYC is rejected"""
    name = user.name or user.first_name or user.username
    subject = "KYC ভেরিফিকেশন আপডেট"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">একটু সমস্যা হয়েছে — এবার আপনার KYC ভেরিফিকেশন অ্যাপ্রুভ করা যায়নি।</p>
{"<p style='color:#374151;font-size:14px;line-height:1.6;margin:0 0 16px;'><strong>কারণ:</strong> " + reason + "</p>" if reason else ""}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">চিন্তার কিছু নেই — ঝকঝকে পরিষ্কার ছবি আর সঠিক তথ্য দিয়ে আবার জমা দিন, আমরা দ্রুত দেখে নেব।</p>

{_button("KYC আবার জমা দিন", SITE_URL + "/my-account")}
"""

    html = _base_template(subject, body, "কোনো ভুল হয়েছে মনে হলে আমাদের সাপোর্ট টিমকে জানান — আমরা পাশে আছি।")
    return _send_email(subject, user.email, f"হ্যালো {name}, এবার আপনার KYC অ্যাপ্রুভ করা যায়নি — একটু ঠিক করে আবার জমা দিন।", html)


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
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার AdsyClub অ্যাকাউন্টটা আপাতত <strong style="color:#DC2626;">স্থগিত</strong> করা হয়েছে। স্থগিত থাকা অবস্থায় অ্যাপের সেবাগুলো ব্যবহার করা যাবে না।</p>
{"<p style='color:#374151;font-size:14px;line-height:1.6;margin:0 0 16px;'><strong>কারণ:</strong> " + reason + "</p>" if reason else ""}
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">যদি মনে করেন এটা ভুল করে হয়েছে, আমাদের সাপোর্ট টিমে যোগাযোগ করুন — আমরা বিষয়টা দেখব।</p>
"""

    html = _base_template(subject, body, "এটা ভুল মনে হলে আমাদের সাপোর্ট টিমে যোগাযোগ করুন।")
    return _send_email(subject, user.email, f"হ্যালো {name}, আপনার AdsyClub অ্যাকাউন্ট আপাতত স্থগিত করা হয়েছে। ভুল মনে হলে সাপোর্টে জানান।", html)


def send_account_unsuspended_email(user):
    """Email sent when a suspended account is restored."""
    name = user.name or user.first_name or user.username
    subject = "আপনার অ্যাকাউন্ট আবার চালু হয়ে গেছে"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুখবর — আপনার AdsyClub অ্যাকাউন্ট <strong style="color:{BRAND_COLOR};">আবার চালু হয়ে গেছে</strong>! আগের মতোই সব ফিচার ব্যবহার করতে পারবেন। ফিরে আসায় ভালো লাগছে 💚</p>

{_button("AdsyClub খুলুন", SITE_URL)}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"হ্যালো {name}, আপনার AdsyClub অ্যাকাউন্ট আবার চালু হয়ে গেছে — চলে আসুন!", html)


def send_pro_subscription_email(user, months, amount):
    """Email when Pro subscription is activated"""
    name = user.name or user.first_name or user.username
    subject = "আপনার Pro চালু হয়ে গেছে ⭐"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">অভিনন্দন — আপনার <strong style="color:{BRAND_COLOR};">Pro সাবস্ক্রিপশন</strong> চালু হয়ে গেছে! এখন থেকে প্রিমিয়াম ফিচারগুলো আপনার হাতের মুঠোয় — জমিয়ে ব্যবহার করুন।</p>

{_info_table(
    _info_row("প্ল্যান", f"{months} মাস") +
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("চালু হয়েছে", timezone.now().strftime("%B %d, %Y"))
)}

{_button("Pro ফিচার দেখুন", SITE_URL + "/business-network")}
{_service_promo_html("bn")}
{_product_showcase_html(2)}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"হ্যালো {name}, আপনার {months} মাসের Pro সাবস্ক্রিপশন চালু হয়ে গেছে ⭐", html)


def send_referral_reward_email(user, reward_amount, claim_type):
    """Email when referral reward is claimed"""
    name = user.name or user.first_name or user.username
    subject = "রেফারেল রিওয়ার্ড চলে এসেছে 🎁"
    role = "বন্ধুকে রেফার করার জন্য" if claim_type == "referrer" else "রেফারেলের মাধ্যমে সাইন আপ করার জন্য"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">দারুণ! {role} আপনি <strong style="color:{BRAND_COLOR};">৳{reward_amount}</strong> রিওয়ার্ড পেয়ে গেছেন — টাকাটা ওয়ালেটে যোগ হয়ে গেছে। যত রেফার, তত ইনকাম!</p>

{_info_table(
    _info_row("রিওয়ার্ড", f"৳{reward_amount}") +
    _info_row("ধরন", claim_type.title()) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y"))
)}

{_button("আরও রেফার করুন", SITE_URL + "/refer-a-friend")}
{_service_promo_html("")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"৳{reward_amount} রেফারেল রিওয়ার্ড আপনার ওয়ালেটে যোগ হয়ে গেছে 🎁 আরও রেফার করুন, আরও ইনকাম করুন!", html)


def send_password_reset_email(user, otp):
    """Email with OTP for password reset"""
    name = user.name or user.first_name or user.username
    subject = "আপনার পাসওয়ার্ড রিসেট OTP 🔐"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">পাসওয়ার্ড রিসেটের অনুরোধ পেয়েছি। নিচের OTP কোডটা ব্যবহার করুন:</p>

<div style="text-align:center;margin:24px 0;">
<span style="display:inline-block;padding:16px 40px;background-color:#f3f4f6;border:2px solid #e5e7eb;border-radius:12px;font-size:32px;font-weight:700;letter-spacing:8px;color:#111827;">{otp}</span>
</div>

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:0;text-align:center;">কোডটা ১০ মিনিট পর্যন্ত কাজ করবে। কাউকে শেয়ার করবেন না — AdsyClub টিমও কখনো আপনার OTP চাইবে না।</p>
"""

    html = _base_template(subject, body, "পাসওয়ার্ড রিসেট আপনি না চেয়ে থাকলে এই ইমেইলটা এড়িয়ে যান — আপনার অ্যাকাউন্ট নিরাপদেই আছে।")
    return _send_email(subject, user.email, f"আপনার AdsyClub OTP: {otp} — ১০ মিনিট পর্যন্ত কাজ করবে। কাউকে শেয়ার করবেন না।", html)


def send_mobile_recharge_email(user, amount, phone_number):
    """Email after successful mobile recharge"""
    name = user.name or user.first_name or user.username
    subject = "রিচার্জ হয়ে গেছে ✅"

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার মোবাইল রিচার্জ হয়ে গেছে 📱 বিস্তারিত নিচে দেখে নিন:</p>

{_info_table(
    _info_row("রিচার্জের পরিমাণ", f"৳{amount}") +
    _info_row("নম্বর", phone_number) +
    _info_row("তারিখ", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">AdsyClub দিয়ে রিচার্জ করার জন্য ধন্যবাদ — পরের রিচার্জটাও এখানেই সেরে ফেলুন!</p>
{_service_promo_html("recharge")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, f"হ্যালো {name}, {phone_number} নম্বরে ৳{amount} রিচার্জ হয়ে গেছে ✅", html)


def send_password_changed_email(user):
    """Confirm to a user that their account password was changed."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার AdsyClub পাসওয়ার্ড বদলানো হয়েছে 🔐"
    text = (
        f"হ্যালো {name}, আপনার AdsyClub অ্যাকাউন্টের পাসওয়ার্ড এইমাত্র বদলানো হয়েছে। "
        "এটা আপনি না করে থাকলে এখনই রিসেট করে সাপোর্টে জানান।"
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">আপনার AdsyClub অ্যাকাউন্টের পাসওয়ার্ড এইমাত্র বদলানো হয়েছে।</p>

{_info_table(
    _info_row("অ্যাকাউন্ট", user.email or "N/A") +
    _info_row("কখন", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">এটা যদি আপনি নিজেই করে থাকেন, তাহলে আর কিছু করতে হবে না — নিশ্চিন্ত থাকুন।</p>
{_button("AdsyClub-এ যান", SITE_URL)}
"""

    html = _base_template(
        subject, body,
        "পাসওয়ার্ডটা আপনি না বদলে থাকলে এখনই রিসেট করুন আর আমাদের জানান — "
        f"{SUPPORT_EMAIL} বা {SUPPORT_PHONE}।",
    )
    return _send_email(subject, user.email, text, html)


def send_product_order_email(seller, order, items):
    """Notify a store owner that they received a new product order."""
    if not seller or not seller.email:
        return False
    name = seller.name or seller.first_name or "there"
    subject = "🛍️ আপনার স্টোরে নতুন অর্ডার এসেছে!"

    item_rows = ""
    for it in items:
        product_name = it.product.name if getattr(it, "product", None) else "Product"
        item_rows += _info_row(f"{product_name} × {it.quantity}", f"৳{it.price}")

    text = (
        f"হ্যালো {name}, আপনার স্টোরে নতুন অর্ডার (#{order.order_number}) এসেছে — "
        "দ্রুত দেখে প্রসেস করে ফেলুন।"
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">দারুণ খবর — আপনার স্টোরে <strong>নতুন অর্ডার</strong> এসেছে! দ্রুত দেখে প্রসেস করে ফেলুন।</p>

{_info_table(
    _info_row("অর্ডার নম্বর", f"#{order.order_number}") +
    item_rows +
    _info_row("ক্রেতা", order.name or "N/A") +
    _info_row("ফোন", order.phone or "N/A") +
    _info_row("ডেলিভারি ঠিকানা", order.address or "N/A") +
    _info_row("পেমেন্ট",order.get_payment_method_display() if hasattr(order, "get_payment_method_display") else (order.payment_method or "N/A"))
)}

{_button("অর্ডার ম্যানেজ করুন", SITE_URL + "/shop-manager")}
"""

    html = _base_template(
        subject, body,
        "তাড়াতাড়ি অর্ডার প্রসেস করলে স্টোরের রেটিং ভালো থাকে, ক্রেতাও খুশি হন। "
        f"সাহায্য লাগলে: {SUPPORT_EMAIL}।",
    )
    return _send_email(subject, seller.email, text, html)


def send_order_confirmation_email(buyer, order):
    """Order confirmation to the customer with full order + payment details."""
    email = (getattr(buyer, "email", None) if buyer else None) or getattr(order, "email", None)
    if not email:
        return False
    name = (getattr(buyer, "name", None) if buyer else None) or order.name or "there"
    subject = f"অর্ডার কনফার্ম হয়ে গেছে — #{order.order_number}"

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
        f"হ্যালো {name}, আপনার AdsyClub অর্ডার #{order.order_number} কনফার্ম হয়ে গেছে। "
        f"মোট: ৳{order.total}। প্রসেস হলেই জানিয়ে দেব।"
    )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">অর্ডারের জন্য ধন্যবাদ! আপনার অর্ডার কনফার্ম হয়ে গেছে — বিবরণ নিচে দেখে নিন।</p>

{_info_table(
    _info_row("অর্ডার নম্বর", f"#{order.order_number}") +
    item_rows +
    _info_row("ডেলিভারি চার্জ", f"৳{order.delivery_fee}") +
    _info_row("মোট", f"৳{order.total}") +
    _info_row("পেমেন্ট মাধ্যম", pay_method) +
    _info_row("স্ট্যাটাস", order_status) +
    _info_row("ডেলিভারি ঠিকানা", order.address or "N/A")
)}

{_button("অর্ডার ট্র্যাক করুন", SITE_URL + "/order/" + str(order.id))}
{_service_promo_html("eshop")}
{_product_showcase_html(2)}
"""

    html = _base_template(
        subject, body,
        "অর্ডার প্রসেস ও শিপ হওয়ার সাথে সাথে আপনাকে জানিয়ে দেব। "
        f"দরকারে: {SUPPORT_EMAIL} বা {SUPPORT_PHONE}।",
    )
    return _send_email(subject, email, text, html)


def send_withdraw_rejected_email(user, amount, transaction_id, reason=""):
    """Notify a user their withdrawal was rejected and the amount refunded."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "উইথড্র করা যায়নি — টাকা ফেরত দিয়ে দিয়েছি"
    text = (
        f"হ্যালো {name}, আপনার ৳{amount} উইথড্র এবার অ্যাপ্রুভ করা যায়নি — "
        f"পুরো টাকা আপনার Adsy Pay ব্যালেন্সে ফেরত চলে গেছে।"
    )
    reason_row = _info_row("কারণ", reason) if reason else ""
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">এবার আপনার উইথড্রর অনুরোধটা অ্যাপ্রুভ করা যায়নি। চিন্তার কিছু নেই — পুরো টাকা <strong>আপনার Adsy Pay ব্যালেন্সে ফেরত</strong> চলে গেছে।</p>

{_info_table(
    _info_row("পরিমাণ", f"৳{amount}") +
    _info_row("রেফারেন্স", str(transaction_id)) +
    reason_row +
    _info_row("স্ট্যাটাস", "বাতিল — টাকা ফেরত ✓")
)}

{_button("ব্যালেন্স দেখুন", SITE_URL + "/deposit-withdraw")}
"""
    html = _base_template(
        subject, body,
        f"কোনো প্রশ্ন থাকলে জানান: {SUPPORT_EMAIL} বা {SUPPORT_PHONE}।",
    )
    return _send_email(subject, user.email, text, html)


def send_kyc_received_email(user):
    """Confirm that a KYC submission was received and is under review."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার KYC পেয়ে গেছি — রিভিউ চলছে"
    text = (
        f"হ্যালো {name}, আপনার KYC জমা পেয়ে গেছি — রিভিউ চলছে। "
        "হয়ে গেলেই মেইলে জানিয়ে দেব।"
    )
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">ধন্যবাদ — আপনার পরিচয় যাচাইয়ের (KYC) কাগজপত্র পেয়ে গেছি। আমাদের টিম এখন দেখছে, হয়ে গেলেই জানিয়ে দেব 👍</p>

{_info_table(
    _info_row("স্ট্যাটাস", "রিভিউ চলছে") +
    _info_row("জমা পড়েছে", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">সাধারণত ২৪–৪৮ ঘণ্টার মধ্যেই রিভিউ হয়ে যায়। হয়ে গেলেই ইমেইল পেয়ে যাবেন।</p>
"""
    html = _base_template(
        subject, body,
        "এখন আপনার আর কিছু করতে হবে না — শুধু একটু অপেক্ষা।",
    )
    return _send_email(subject, user.email, text, html)


def send_post_approved_email(user, title, kind="post", link=""):
    """Notify a user that their post/listing was approved and is now live."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার {kind} এখন লাইভ"
    text = f"হ্যালো {name}, আপনার {kind} \"{title}\" অ্যাপ্রুভ হয়ে গেছে — এখন AdsyClub-এ লাইভ। সবাই দেখতে পাচ্ছে!"
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সুখবর — আপনার {kind} <strong>অ্যাপ্রুভ</strong> হয়ে গেছে, এখন AdsyClub-এ লাইভ! সবাই এখন দেখতে পাচ্ছে।</p>

{_info_table(
    _info_row(kind.capitalize(), title or "—") +
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভড ও লাইভ")
)}

{_button("দেখে নিন", link or SITE_URL)}
"""
    html = _base_template(subject, body, "AdsyClub কমিউনিটিতে অবদান রাখার জন্য ধন্যবাদ!")
    return _send_email(subject, user.email, text, html)


def send_post_rejected_email(user, title, kind="post", reason="", link=""):
    """Notify a user that their post/listing was not approved."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার {kind} অ্যাপ্রুভ হয়নি"
    text = f"হ্যালো {name}, এবার আপনার {kind} \"{title}\" অ্যাপ্রুভ করা যায়নি — একটু এডিট করে আবার জমা দিন।"
    reason_row = _info_row("কারণ", reason) if reason else ""
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সাবমিশনের জন্য ধন্যবাদ। দুঃখিত, এবার আপনার {kind} <strong>অ্যাপ্রুভ করা যায়নি</strong>।</p>

{_info_table(
    _info_row(kind.capitalize(), title or "—") +
    reason_row +
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভ হয়নি")
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">গাইডলাইন মেনে একটু এডিট করে আবার জমা দিন — আমরা দ্রুত দেখে নেব।</p>
{_button("এডিট করে আবার দিন", link or SITE_URL)}
"""
    html = _base_template(
        subject, body,
        f"কোনো প্রশ্ন থাকলে {SUPPORT_EMAIL}-এ লিখুন — আমরা সাহায্য করব।",
    )
    return _send_email(subject, user.email, text, html)


def send_post_received_email(user, title, kind="post", link=""):
    """Confirm a post/listing was received and is under review."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = f"আপনার {kind} পেয়ে গেছি — রিভিউ চলছে"
    text = f"হ্যালো {name}, আপনার {kind} \"{title}\" পেয়ে গেছি — রিভিউ চলছে। লাইভ হলেই জানিয়ে দেব।"
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">সাবমিশনের জন্য ধন্যবাদ! আপনার {kind} পেয়ে গেছি, আমাদের টিম এখন দেখছে। অ্যাপ্রুভ হয়ে লাইভ হলেই ইমেইলে জানিয়ে দেব 👍</p>

{_info_table(
    _info_row(kind.capitalize(), title or "—") +
    _info_row("স্ট্যাটাস", "রিভিউ চলছে") +
    _info_row("জমা পড়েছে", timezone.now().strftime("%B %d, %Y %I:%M %p"))
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">সাধারণত কয়েক ঘণ্টার মধ্যেই রিভিউ হয়ে যায়।</p>
{_button("সাবমিশন দেখুন", link or SITE_URL)}
"""
    html = _base_template(subject, body, "আপাতত আপনার আর কিছু করতে হবে না।")
    return _send_email(subject, user.email, text, html)


def send_driver_approved_email(user):
    """Notify a rideshare driver that their application was approved."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার ড্রাইভার আবেদন অ্যাপ্রুভ হয়েছে 🚗"
    text = f"হ্যালো {name}, আপনার AdsyClub ড্রাইভার আবেদন অ্যাপ্রুভ হয়ে গেছে! অ্যাপে অনলাইন হয়ে রাইড নেওয়া শুরু করে দিন।"
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">অভিনন্দন — আপনার ড্রাইভার আবেদন <strong>অ্যাপ্রুভ</strong> হয়ে গেছে! এখন অ্যাপে অনলাইন হয়ে রাইড নেওয়া শুরু করে দিন। 🚗</p>

{_info_table(
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভড") +
    _info_row("পরের ধাপ", "অ্যাপে গিয়ে অনলাইন হোন — রাইড রিকোয়েস্ট আসতে থাকবে")
)}

{_button("AdsyClub খুলুন", SITE_URL)}
"""
    html = _base_template(subject, body, "নিরাপদে চালান, ভালো সার্ভিস দিন — রেটিংও বাড়বে, ইনকামও।")
    return _send_email(subject, user.email, text, html)


def send_driver_rejected_email(user, reason=""):
    """Notify a rideshare driver that their application was not approved."""
    if not user or not user.email:
        return False
    name = user.name or user.first_name or "there"
    subject = "আপনার ড্রাইভার আবেদনের আপডেট"
    text = f"হ্যালো {name}, এবার আপনার AdsyClub ড্রাইভার আবেদন অ্যাপ্রুভ করা যায়নি — তথ্য আপডেট করে আবার আবেদন করতে পারবেন।"
    reason_row = _info_row("কারণ", reason) if reason else ""
    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">AdsyClub-এ ড্রাইভার হতে আবেদন করার জন্য ধন্যবাদ। রিভিউয়ের পর এবার আপনার আবেদনটা <strong>অ্যাপ্রুভ করা যায়নি</strong>।</p>

{_info_table(
    _info_row("স্ট্যাটাস", "অ্যাপ্রুভ হয়নি") +
    reason_row
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">তথ্যগুলো আপডেট করে আবার আবেদন করতে পারবেন — দরজা খোলা আছে।</p>
"""
    html = _base_template(
        subject, body,
        f"বিস্তারিত জানতে: {SUPPORT_EMAIL} বা {SUPPORT_PHONE}।",
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
    text = f"হ্যালো {name}, AdsyClub-এ রাইড নেওয়ার জন্য ধন্যবাদ! মোট ভাড়া: ৳{fare}। রসিদটা মেইলেই রইল।"
    driver_row = _info_row("ড্রাইভার", driver_name) if driver_name else ""

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">হ্যালো <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 16px;">AdsyClub-এ রাইড নেওয়ার জন্য ধন্যবাদ! এই যে আপনার ট্রিপের রসিদ 🧾</p>

{_info_table(
    _info_row("কোথা থেকে", ride.pickup_address or "—") +
    _info_row("কোথায়", ride.drop_address or "—") +
    _info_row("দূরত্ব", f"{distance} কিমি") +
    (_info_row("সময়", f"{minutes} মিনিট") if minutes else "") +
    driver_row +
    _info_row("পেমেন্ট",pay) +
    _info_row("মোট ভাড়া",f"<strong>৳{fare}</strong>")
)}

<p style="color:#6b7280;font-size:14px;line-height:1.6;margin:16px 0;">অ্যাপে ড্রাইভারকে একটা রেটিং দিয়ে দিন — এতে AdsyClub রাইড সবার জন্য আরও ভালো হয়।</p>
{_button("AdsyClub খুলুন", SITE_URL)}
"""
    html = _base_template(subject, body, "আশা করি রাইডটা ভালো লেগেছে — আবার দেখা হবে!")
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
    text = f"হ্যালো {name}, AdsyClub সাপোর্ট টিম আপনার টিকেট \"{ticket.title}\"-এ রিপ্লাই দিয়েছে — দেখে নিন।"

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
        "কথোপকথন চালিয়ে যেতে অ্যাপ বা ওয়েবসাইট থেকে রিপ্লাই দিন — আমরা আছি।",
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
    return _send_email(subject, to_email, "Test email from AdsyClub", html, wait=True)


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



def send_bn_digest_email(user):
    """Weekly Business Network community digest — the social-network pull:
    who followed you, how your posts performed, and faces you may know.
    Every block links back into the app to bring the user home."""
    if not getattr(user, "email", ""):
        return False
    from django.contrib.auth import get_user_model
    from business_network.models import (
        BusinessNetworkFollowerModel,
        BusinessNetworkPostLike,
    )

    User = get_user_model()
    name = user.name or user.first_name or user.username or "there"
    week_ago = timezone.now() - timedelta(days=7)

    follower_rows = list(
        BusinessNetworkFollowerModel.objects.filter(
            following=user, created_at__gte=week_ago
        ).select_related("follower").order_by("-created_at")[:8]
    )
    new_followers = [r.follower for r in follower_rows]
    follower_count = len(follower_rows)
    likes_count = BusinessNetworkPostLike.objects.filter(
        post__author=user, created_at__gte=week_ago
    ).count()

    following_ids = list(
        BusinessNetworkFollowerModel.objects.filter(follower=user)
        .values_list("following_id", flat=True)
    )
    suggestion_pool = list(
        User.objects.exclude(id=user.id)
        .exclude(id__in=following_ids)
        .exclude(image="")
        .exclude(image=None)
        .filter(is_active=True)
        .order_by("-date_joined")[:20]
    )
    random.shuffle(suggestion_pool)
    suggestions = suggestion_pool[:4]

    subject = "\u098f\u0987 \u09b8\u09aa\u09cd\u09a4\u09be\u09b9\u09c7 \u0986\u09aa\u09a8\u09be\u09b0 \u09a8\u09c7\u099f\u0993\u09af\u09bc\u09be\u09b0\u09cd\u0995\u09c7 \u09af\u09be \u09b9\u09b2\u09cb"
    text = (
        f"\u09b9\u09cd\u09af\u09be\u09b2\u09cb {name}, \u098f\u0987 \u09b8\u09aa\u09cd\u09a4\u09be\u09b9\u09c7 \u0986\u09aa\u09a8\u09be\u09b0 {follower_count} \u099c\u09a8 \u09a8\u09a4\u09c1\u09a8 \u09ab\u09b2\u09cb\u09af\u09bc\u09be\u09b0 \u098f\u09ac\u0982 \u09aa\u09cb\u09b8\u09cd\u099f\u09c7 {likes_count}\u099f\u09be \u09b2\u09be\u0987\u0995 \u098f\u09b8\u09c7\u099b\u09c7\u0964"
    )

    stat_cells = f"""<tr>
<td width="50%" style="padding:5px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#EFF6FF;border-radius:12px;"><tr><td style="padding:14px;text-align:center;">
<div style="color:#2563EB;font-size:22px;font-weight:800;">{follower_count}</div>
<div style="color:#475569;font-size:12px;font-weight:600;margin-top:2px;">\u09a8\u09a4\u09c1\u09a8 \u09ab\u09b2\u09cb\u09af\u09bc\u09be\u09b0</div>
</td></tr></table></td>
<td width="50%" style="padding:5px;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color:#FDF2F8;border-radius:12px;"><tr><td style="padding:14px;text-align:center;">
<div style="color:#DB2777;font-size:22px;font-weight:800;">{likes_count}</div>
<div style="color:#475569;font-size:12px;font-weight:600;margin-top:2px;">\u09aa\u09cb\u09b8\u09cd\u099f\u09c7 \u09b2\u09be\u0987\u0995</div>
</td></tr></table></td>
</tr>"""

    followers_block = ""
    if new_followers:
        followers_block = _people_row_html(
            new_followers,
            "\u09af\u09be\u09b0\u09be \u098f\u0987 \u09b8\u09aa\u09cd\u09a4\u09be\u09b9\u09c7 \u0986\u09aa\u09a8\u09be\u0995\u09c7 \u09ab\u09b2\u09cb \u0995\u09b0\u09b2\u09c7\u09a8",
        )

    suggestions_block = ""
    if suggestions:
        suggestions_block = _people_row_html(
            suggestions,
            "\u09aa\u09b0\u09bf\u099a\u09bf\u09a4 \u09b9\u09a4\u09c7 \u09aa\u09be\u09b0\u09c7\u09a8",
        )

    body = f"""
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 14px;">\u09b9\u09cd\u09af\u09be\u09b2\u09cb <strong>{name}</strong>,</p>
<p style="color:#374151;font-size:15px;line-height:1.6;margin:0 0 14px;">\u0986\u09aa\u09a8\u09be\u09b0 Business Network \u0995\u09ae\u09bf\u0989\u09a8\u09bf\u099f\u09bf\u09a4\u09c7 \u098f\u0987 \u09b8\u09aa\u09cd\u09a4\u09be\u09b9\u09c7 \u09af\u09be \u09af\u09be \u09b9\u09b2\u09cb \u2014 \u098f\u0995 \u09a8\u099c\u09b0\u09c7 \u09a6\u09c7\u0996\u09c7 \u09a8\u09bf\u09a8\u0964</p>

<table role="presentation" width="100%" cellspacing="0" cellpadding="0">{stat_cells}</table>

{followers_block}
{suggestions_block}

{_button("\u0995\u09ae\u09bf\u0989\u09a8\u09bf\u099f\u09bf\u09a4\u09c7 \u09ab\u09bf\u09b0\u09c7 \u0986\u09b8\u09c1\u09a8", SITE_URL + "/business-network")}
{_service_promo_html("bn")}
"""

    html = _base_template(subject, body)
    return _send_email(subject, user.email, text, html)

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
