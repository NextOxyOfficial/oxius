"""One-click admin moderation from email.

Each pending item (Amar Sheba post, Sale post, MicroGig, Workspace gig) sends the
admin an email with Approve / Reject buttons carrying a signed, expiring token.

Security: the link only *identifies* the item + action — performing it still
requires an authenticated **staff** session. So a forwarded/leaked email is
useless to anyone who isn't logged into the admin (they're bounced to the admin
login). The confirm page's POST is CSRF-protected, and the GET (which never
changes state) is safe against email link pre-fetching.
"""

from django.apps import apps
from django.contrib.auth.views import redirect_to_login
from django.core import signing
from django.http import HttpResponse
from django.middleware.csrf import get_token
from django.utils.html import escape

SITE_URL = "https://adsyclub.com"
_SALT = "adsyclub.moderation.v1"
_MAX_AGE = 21 * 24 * 3600  # links valid for 21 days

# model "app_label.ModelName" -> how to approve/reject it
MODERATION_TARGETS = {
    "base.ClassifiedCategoryPost": {
        "field": "service_status", "approve": "approved", "reject": "rejected",
        "label": "Amar Sheba পোস্ট",
    },
    "sale.SalePost": {
        "field": "status", "approve": "active", "reject": "rejected",
        "label": "Sale মার্কেটপ্লেস পোস্ট",
    },
    "base.MicroGigPost": {
        "field": "gig_status", "approve": "approved", "reject": "rejected",
        "label": "MicroGig",
    },
    "workspace.Gig": {
        "field": "status", "approve": "active", "reject": "rejected",
        "label": "Workspace গিগ",
    },
}


def model_key_for(obj):
    return f"{obj._meta.app_label}.{obj.__class__.__name__}"


def notify_admin_pending(obj, extra_rows=None):
    """Async-email the admin about a newly-pending moderatable item, with
    one-click Approve / Reject. Safe to call from a model's save(); the slow
    SMTP part runs off the request thread."""
    from django.utils import timezone
    from base.email_service import _dispatch_async, send_admin_moderation_email

    key = model_key_for(obj)
    cfg = MODERATION_TARGETS.get(key)
    if not cfg:
        return
    user = getattr(obj, "user", None) or getattr(obj, "owner", None)
    uname = "—"
    uemail = ""
    if user is not None:
        uname = (getattr(user, "name", "") or getattr(user, "first_name", "")
                 or getattr(user, "email", "") or "—")
        uemail = getattr(user, "email", "") or ""
    title = str(getattr(obj, "title", None) or getattr(obj, "name", None) or obj.pk)

    rows = [("User", uname)]
    if uemail:
        rows.append(("Email", uemail))
    rows.append(("Title", title))
    if getattr(obj, "price", None) is not None:
        rows.append(("Price", f"৳{obj.price}"))
    rows += (extra_rows or [])
    rows.append(("Submitted", timezone.now().strftime("%b %d, %Y %I:%M %p")))

    admin_path = f"/admin/{obj._meta.app_label}/{obj.__class__.__name__.lower()}/{obj.pk}/change/"
    _dispatch_async(
        send_admin_moderation_email,
        subject=f"নতুন {cfg['label']} — রিভিউ দরকার ⏳",
        label=cfg["label"],
        intro=f"একটি নতুন {cfg['label']} জমা পড়েছে, অ্যাপ্রুভালের অপেক্ষায় আছে। নিচ থেকে এক ক্লিকে Approve বা Reject করতে পারেন।",
        rows=rows,
        model_key=key,
        pk=str(obj.pk),
        admin_path=admin_path,
        text_summary=f"New {cfg['label']} pending review: {title}",
    )


def notify_admin_info(*, subject, label, intro, rows, admin_path, text_summary):
    """Informational admin email (no approve/reject) — e.g. a new eShop order or
    product. Sent off the request thread."""
    from base.email_service import _dispatch_async, send_admin_moderation_email
    _dispatch_async(
        send_admin_moderation_email,
        subject=subject, label=label, intro=intro, rows=rows,
        admin_path=admin_path, text_summary=text_summary,
    )


def make_token(model_key, pk, action):
    return signing.dumps({"m": model_key, "pk": str(pk), "a": action}, salt=_SALT)


def moderation_url(model_key, pk, action):
    """Full email-safe link the admin clicks to approve/reject."""
    return f"{SITE_URL}/api/moderate/{make_token(model_key, pk, action)}/"


def _shell(title, message, emoji="ℹ️", color="#374151", extra=""):
    return HttpResponse(
        f"""<!doctype html><html lang="bn"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)}</title></head>
<body style="font-family:system-ui,-apple-system,Segoe UI,Roboto,Arial,sans-serif;background:#f3f4f6;margin:0;padding:40px 16px;">
<div style="max-width:480px;margin:0 auto;background:#fff;border-radius:16px;padding:32px;text-align:center;box-shadow:0 6px 24px rgba(0,0,0,.07);">
<div style="font-size:44px;line-height:1;margin-bottom:12px;">{emoji}</div>
<h2 style="color:{color};margin:0 0 8px;font-size:20px;">{escape(title)}</h2>
<div style="color:#374151;font-size:15px;line-height:1.6;">{message}</div>
{extra}
<div style="margin-top:22px;"><a href="{SITE_URL}/admin/" style="color:#6366F1;font-size:13px;text-decoration:none;">Admin প্যানেল খুলুন →</a></div>
</div></body></html>""",
    )


def moderate(request, token):
    # Must be a logged-in admin. A forwarded/leaked email link is then useless to
    # anyone else — they get bounced to the admin login.
    if not (request.user.is_authenticated and request.user.is_staff):
        return redirect_to_login(request.get_full_path(), login_url="/admin/login/")

    try:
        data = signing.loads(token, salt=_SALT, max_age=_MAX_AGE)
    except signing.SignatureExpired:
        return _shell("লিংকের মেয়াদ শেষ", "এই লিংকের মেয়াদ শেষ হয়ে গেছে। Admin প্যানেল থেকে রিভিউ করুন।", "⏳", "#6b7280")
    except signing.BadSignature:
        return _shell("ভুল লিংক", "এই লিংকটি বৈধ নয়।", "⚠️", "#dc2626")

    cfg = MODERATION_TARGETS.get(data.get("m"))
    if not cfg:
        return _shell("অজানা আইটেম", "এই আইটেম টাইপ সাপোর্টেড নয়।", "⚠️", "#dc2626")

    model = apps.get_model(data["m"])
    obj = model.objects.filter(pk=data["pk"]).first()
    if obj is None:
        return _shell("আইটেম নেই", "আইটেমটি আর খুঁজে পাওয়া যাচ্ছে না (সম্ভবত ডিলিট করা হয়েছে)।", "🔍", "#6b7280")

    action = "approve" if data.get("a") == "approve" else "reject"
    field = cfg["field"]
    target = cfg[action]
    current = getattr(obj, field)
    item_title = escape(str(getattr(obj, "title", None) or getattr(obj, "name", None) or obj.pk))
    verb = "Approve" if action == "approve" else "Reject"
    color = "#16a34a" if action == "approve" else "#dc2626"

    if request.method == "POST":
        if current == target:
            return _shell("আগেই হয়ে গেছে", f"“{item_title}” ইতিমধ্যে <b>{escape(target)}</b>।", "✔️", "#6b7280")
        setattr(obj, field, target)
        obj.save()  # triggers the model's own approved/rejected user-email
        if action == "approve":
            return _shell("Approved ✅", f"“{item_title}” <b>approve</b> করা হয়েছে।", "✅", "#16a34a")
        return _shell("Rejected", f"“{item_title}” <b>reject</b> করা হয়েছে।", "❌", "#dc2626")

    # GET: show a confirm page (so an email pre-fetch can't change state).
    if current == target:
        return _shell(
            f"{cfg['label']}", f"“{item_title}” ইতিমধ্যে <b>{escape(target)}</b> অবস্থায় আছে।",
            "✔️", "#6b7280",
        )
    confirm_btn = (
        f"""<form method="post" style="margin-top:18px;">
<input type="hidden" name="csrfmiddlewaretoken" value="{get_token(request)}">
<button type="submit" style="background:{color};color:#fff;border:0;border-radius:10px;
padding:13px 30px;font-size:15px;font-weight:600;cursor:pointer;">{verb} নিশ্চিত করুন</button></form>"""
    )
    msg = (
        f"<p style='font-size:16px;font-weight:600;color:#111827;margin:0 0 4px;'>{item_title}</p>"
        f"<p style='color:#6b7280;font-size:13px;margin:0;'>{escape(cfg['label'])} · বর্তমান স্ট্যাটাস: {escape(str(current))}</p>"
        f"<p style='color:#374151;font-size:14px;margin:16px 0 0;'>আপনি এটি <b style='color:{color};'>{verb}</b> করতে যাচ্ছেন।</p>"
    )
    return _shell(f"{verb} — {cfg['label']}", msg, "🛡️", "#111827", extra=confirm_btn)
