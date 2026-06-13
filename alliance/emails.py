"""Render + send Alliance outreach emails.

One-to-one business outreach emails, built in three clear parts:
  • HEADER    — clean AdsyClub logo + tagline (no colored accent bar)
  • BODY      — the message (written in the draft's language) + a professional,
                icon-based signature with social links
  • FOOTER    — a donation appeal with a Donate button (icon + text), AdsyClub
                meta and a short compliant unsubscribe block.

The chrome (signature + footer) is ALWAYS English by design — only the message
body follows the draft's language (en/bn). The Donate button carries a
per-recipient link (/donate?o=<draft id>) so the donation page can greet the
recipient by name in their language. Sends via the SMTP configured in Django
admin (base.EmailSettings), Reply-To = the CEO."""

import logging
from email.utils import formataddr, parseaddr

from django.core.mail import EmailMultiAlternatives, get_connection
from django.utils.html import strip_tags

from base.email_service import _get_email_settings, _logo_url, SITE_NAME, SITE_URL

logger = logging.getLogger(__name__)

CEO_EMAIL = "ceo@adsyclub.com"
WHATSAPP = "+8801957045438"
WHATSAPP_LINK = "https://wa.me/8801957045438"
SITE = "https://adsyclub.com"
DONATE_URL = f"{SITE}/donate"
FROM_DISPLAY = "Alimul Islam - CEO, AdsyClub"

# Founder photo shown to the LEFT of the signature. The file lives in the repo at
# frontend/public/static/frontend/images/founder.jpg and is served from this URL
# in production. (Email clients load images only from a public URL, so a LOCAL
# test won't render it until the asset is live on adsyclub.com.)
FOUNDER_PHOTO = "https://adsyclub.com/static/frontend/images/founder.jpg"

ACCENT = "#4f46e5"  # indigo — links + Donate button

# Founder social profiles — shown as icons in the signature.
# TODO: confirm the real handles/URLs with the founder before real sends.
FACEBOOK_URL = "https://fb.com/AlimulOfficial"
TWITTER_URL = "https://x.com/AlimulOfficial"
LINKEDIN_URL = "https://www.linkedin.com/in/md-alimul-islam-299435115/"

# App store links (so recipients can install the app from the signature).
ANDROID_URL = "https://play.google.com/store/apps/details?id=com.oxius.app"
IOS_URL = "https://apps.apple.com/us/app/adsyclub/id6760218370"

# Icons (hosted PNG so they render across mail clients — Gmail strips inline SVG).
# TODO: optionally self-host on adsyclub.com/static before scaling outreach.
ICON_EMAIL = "https://img.icons8.com/ios-filled/100/737a86/new-post.png"
ICON_WHATSAPP = "https://img.icons8.com/color/96/whatsapp--v1.png"
ICON_WEB = "https://img.icons8.com/ios-filled/100/737a86/domain.png"
ICON_FB = "https://img.icons8.com/color/96/facebook-new.png"
ICON_TW = "https://img.icons8.com/color/96/twitterx--v1.png"
ICON_LI = "https://img.icons8.com/color/96/linkedin.png"
ICON_GOOGLEPLAY = "https://img.icons8.com/color/96/google-play.png"
ICON_APPSTORE = "https://img.icons8.com/color/96/apple-app-store--v1.png"


def _donate_url(draft):
    did = getattr(draft, "id", None)
    return f"{DONATE_URL}?o={did}" if did else DONATE_URL


# ── HEADER ───────────────────────────────────────────────────────────────────
def _header_html():
    logo = _logo_url()
    return f"""
<tr>
<td class="ec-pad" style="padding:34px 44px 22px;text-align:center;">
<img src="{logo}" alt="{SITE_NAME}" height="40" style="height:40px;width:auto;border:0;display:inline-block;outline:none;text-decoration:none;">
<div style="margin:12px 0 0;color:#9aa1ac;font-size:11px;letter-spacing:2.5px;text-transform:uppercase;font-weight:600;">Social Business Network</div>
</td>
</tr>
<tr><td class="ec-pad" style="padding:0 44px;"><div style="border-top:1px solid #eef0f3;font-size:0;line-height:0;">&nbsp;</div></td></tr>
"""


# ── BODY signature (always English, icon-based + social) ─────────────────────
def _contact_row(icon, value_html):
    return (f'<tr>'
            f'<td style="padding:5px 12px 5px 0;vertical-align:middle;width:18px;">'
            f'<img src="{icon}" width="17" height="17" alt="" style="display:block;border:0;"></td>'
            f'<td style="padding:5px 0;font-size:13px;color:#5b626d;vertical-align:middle;">{value_html}</td>'
            f'</tr>')


def _social_icon(url, icon, alt):
    return (f'<td style="padding-right:11px;">'
            f'<a href="{url}" target="_blank" style="text-decoration:none;">'
            f'<img src="{icon}" width="30" height="30" alt="{alt}" style="display:block;border:0;"></a></td>')


def _app_badge(url, icon, label):
    """A store badge: bordered pill with icon + real text label (the text shows
    even when the recipient's client blocks images)."""
    return (f'<a href="{url}" target="_blank" style="display:inline-block;text-decoration:none;'
            f'border:1px solid #e3e5e9;border-radius:8px;padding:7px 13px;margin:0 8px 8px 0;background:#ffffff;">'
            f'<img src="{icon}" width="18" height="18" alt="" style="vertical-align:middle;border:0;">'
            f'<span style="color:#4b515b;font-size:12px;font-weight:600;vertical-align:middle;">&nbsp;&nbsp;{label}</span></a>')


def _signature_html():
    contacts = (
        _contact_row(ICON_EMAIL, f'<a href="mailto:{CEO_EMAIL}" style="color:{ACCENT};text-decoration:none;">{CEO_EMAIL}</a>')
        + _contact_row(ICON_WHATSAPP, f'<a href="{WHATSAPP_LINK}" style="color:{ACCENT};text-decoration:none;">{WHATSAPP}</a>')
        + _contact_row(ICON_WEB, f'<a href="https://www.adsyclub.com" style="color:{ACCENT};text-decoration:none;">https://www.adsyclub.com</a>')
    )
    socials = (
        _social_icon(FACEBOOK_URL, ICON_FB, "Facebook")
        + _social_icon(LINKEDIN_URL, ICON_LI, "LinkedIn")
    )
    # Founder photo on the left of the name/title/contacts (full image, rounded
    # square so nothing is clipped). Only rendered when FOUNDER_PHOTO is hosted.
    photo_cell = (
        f'<td style="width:130px;vertical-align:top;padding-right:18px;">'
        f'<img src="{FOUNDER_PHOTO}" width="112" height="112" alt="Alimul Islam" '
        f'style="width:112px;height:112px;border-radius:8px;display:block;border:0;"></td>'
    ) if FOUNDER_PHOTO else ""
    return f"""
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-top:30px;">
<tr><td style="border-top:1px solid #ecedf1;padding-top:24px;">
  <table role="presentation" cellspacing="0" cellpadding="0"><tr>
    {photo_cell}
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


# ── FOOTER (donation appeal + compliance, always English) ────────────────────
def _footer_html(donate_url, unsub_url):
    app_badges = (
        _app_badge(ANDROID_URL, ICON_GOOGLEPLAY, "Available on Android")
        + _app_badge(IOS_URL, ICON_APPSTORE, "Available on iOS")
    )
    return f"""
<tr>
<td class="ec-pad" style="background-color:#f7f8fa;border-top:1px solid #ecedf1;padding:30px 44px 34px;text-align:center;">
  <div style="margin:0 0 22px;line-height:0;">{app_badges}</div>
  <div style="font-size:15px;color:#1a1d23;font-weight:700;letter-spacing:-0.1px;margin:0 0 7px;">Believe in what we're building?</div>
  <div style="font-size:13px;color:#6b7280;line-height:1.65;margin:0 auto 20px;max-width:440px;">AdsyClub creates income &amp; employment for everyday people across Bangladesh. Your support — however small — helps us reach more lives. Please consider a donation.</div>
  <a href="{donate_url}" style="display:inline-block;padding:13px 34px;background-color:{ACCENT};color:#ffffff;text-decoration:none;border-radius:9px;font-size:14px;font-weight:700;">
    <span style="font-size:15px;vertical-align:-1px;">&#10084;</span>&nbsp;&nbsp;Donate to AdsyClub
  </a>

  <div style="border-top:1px solid #e7e9ee;margin:28px auto 18px;font-size:0;line-height:0;">&nbsp;</div>

  <div style="font-size:14px;color:#2c3138;font-weight:700;letter-spacing:-0.2px;">AdsyClub</div>
  <div style="font-size:11px;color:#9aa1ac;margin:3px 0 12px;">Bangladesh's Social Business Network</div>
  <div style="font-size:11px;color:#aeb4be;line-height:1.65;">
    You're receiving this as a one-to-one business message from AdsyClub.<br>
    Prefer not to hear from us? <a href="{unsub_url}" style="color:#8a93a0;text-decoration:underline;">Unsubscribe</a>.
  </div>
</td>
</tr>
"""


# ── Wrapper ──────────────────────────────────────────────────────────────────
def _outreach_template(title, body_content, donate_url, unsub_url):
    return f"""<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<meta name="x-apple-disable-message-reformatting">
<title>{title}</title>
<style>
@media only screen and (max-width:600px) {{
  .ec-wrap {{ padding:18px 8px !important; }}
  .ec-pad {{ padding-left:26px !important; padding-right:26px !important; }}
}}
</style>
</head>
<body style="margin:0;padding:0;background-color:#f4f5f7;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,'Helvetica Neue',Arial,sans-serif;-webkit-font-smoothing:antialiased;">
<table role="presentation" width="100%" cellspacing="0" cellpadding="0" class="ec-wrap" style="background-color:#f4f5f7;padding:36px 16px;">
<tr><td align="center">
<table role="presentation" width="600" cellspacing="0" cellpadding="0" style="width:600px;max-width:600px;background-color:#ffffff;border-radius:14px;overflow:hidden;border:1px solid #e7e9ed;">

{_header_html()}

<tr>
<td class="ec-pad" style="padding:30px 44px 36px;color:#2c3138;font-size:15px;line-height:1.72;">
{body_content}
</td>
</tr>

{_footer_html(donate_url, unsub_url)}

</table>
<div style="color:#aab2bd;font-size:11px;margin-top:18px;line-height:1.6;">AdsyClub &middot; Bangladesh &middot; <a href="https://www.adsyclub.com" style="color:#8b93a0;text-decoration:none;">https://www.adsyclub.com</a></div>
</td></tr>
</table>
</body>
</html>"""


def _unsub_url(draft):
    """Unique unsubscribe link for the recipient (reuses the shared token), in
    the draft's language so the unsubscribe page matches the recipient."""
    email = getattr(draft, "to_email", "") or ""
    lang = getattr(draft, "language", "en") or "en"
    if email:
        from base.email_service import unsubscribe_token
        return f"{SITE}/api/email/unsubscribe/?t={unsubscribe_token(email)}&lang={lang}"
    return f"{SITE}/api/email/unsubscribe/"


def _body_to_html(raw):
    """Accept EITHER ready-made HTML or plain text. If it already contains block
    HTML tags, use it as-is (assistant-prepared drafts); otherwise treat it as
    plain text typed in the admin and convert it to styled paragraphs — a blank
    line starts a new paragraph, a single newline becomes a line break."""
    import re
    from django.utils.html import escape

    raw = (raw or "").strip()
    if not raw:
        return ""
    if re.search(r"<(p|div|br|table|ul|ol|h[1-6]|span)\b", raw, re.I):
        return raw  # already HTML — leave it untouched
    style = "color:#374151;font-size:15px;line-height:1.75;margin:0 0 16px;"
    out = []
    for para in re.split(r"\n\s*\n", raw):
        para = para.strip()
        if not para:
            continue
        out.append(f'<p style="{style}">{escape(para).replace(chr(10), "<br>")}</p>')
    return "\n".join(out)


def render_outreach_email(draft):
    """Return (subject, html, text) for an OutreachDraft (or any object with
    .subject / .body_html / .id). Chrome is always English; only the body language
    varies (set by the author). The body may be plain text OR HTML (see
    _body_to_html) — so the admin can just type normal text."""
    body = _body_to_html(getattr(draft, "body_html", "") or "")
    subject = getattr(draft, "subject", "") or ""
    donate_url = _donate_url(draft)
    unsub_url = _unsub_url(draft)
    html = _outreach_template(subject, body + _signature_html(), donate_url, unsub_url)
    text = strip_tags(body) + (
        f"\n\n--\nAlimul Islam\nFounder & CEO, AdsyClub\n{CEO_EMAIL}\n"
        f"WhatsApp: {WHATSAPP}\n{SITE}\n"
        f"Android: {ANDROID_URL}\niOS: {IOS_URL}\n"
        f"Facebook: {FACEBOOK_URL}\nTwitter: {TWITTER_URL}\nLinkedIn: {LINKEDIN_URL}\n\n"
        f"Support AdsyClub: {donate_url}\n"
        f"Unsubscribe: {unsub_url}"
    )
    return subject, html, text


def _send_rendered(subject, html, text, to_email):
    """Low-level send via the Django-admin SMTP (base.EmailSettings). Raises on
    failure. Shared by real sends and test sends so they behave identically."""
    cfg = _get_email_settings()
    connection = get_connection(
        host=cfg["host"],
        port=cfg["port"],
        use_tls=cfg["use_tls"],
        username=cfg["host_user"],
        password=cfg["host_password"],
    )
    from_addr = parseaddr(cfg["from_email"])[1] or cfg["host_user"]
    from_email = formataddr((FROM_DISPLAY, from_addr))

    msg = EmailMultiAlternatives(
        subject=subject,
        body=text,
        from_email=from_email,
        to=[to_email],
        reply_to=[CEO_EMAIL],
        connection=connection,
    )
    msg.attach_alternative(html, "text/html")
    msg.send()


def send_outreach(draft):
    """Send one outreach draft to its recipient via the configured SMTP."""
    subject, html, text = render_outreach_email(draft)
    _send_rendered(subject, html, text, draft.to_email)
    logger.info("Alliance outreach sent: '%s' -> %s", subject, draft.to_email)
    return True


def send_test_email(subject, body_html, test_email, draft_id=None):
    """Send a TEST of the exact rendered email to `test_email` (the founder's own
    inbox). Identical to the real email — NO [TEST] prefix. When `draft_id` is
    given, the Donate button carries the same personalized link the recipient
    would get. Uses the same SMTP as a real send."""
    class _Draft:
        pass

    d = _Draft()
    d.subject = subject or ""
    d.body_html = body_html or ""
    d.id = draft_id
    _subject, html, text = render_outreach_email(d)
    _send_rendered(_subject, html, text, test_email)
    logger.info("Alliance TEST sent: '%s' -> %s", _subject, test_email)
    return True
