"""Send the location-targeted "services near you" nudge as BOTH a push and an
email to a single test recipient, using the busiest real area as sample data.

Prints only a short ASCII status line (the Bangla content goes out in the
push/email itself), which survives flaky SSH output capture.

    python manage.py send_area_test --email alimulislam50@gmail.com
"""
from django.core.management.base import BaseCommand


class Command(BaseCommand):
    help = "Send a test area-services push + email to one user."

    def add_arguments(self, parser):
        parser.add_argument("--email", default="alimulislam50@gmail.com")

    def handle(self, *args, **opts):
        from django.contrib.auth import get_user_model
        from engagement.nudges import _area_services_build
        from engagement.services import build_area_service_index
        from base.email_service import send_engagement_email
        from base.fcm_service import send_fcm_notification_async
        from base.models import FCMToken

        User = get_user_model()
        user = User.objects.filter(email__iexact=opts["email"]).first()
        if not user:
            self.stdout.write("AREATEST user_not_found")
            return

        # Busiest live area as concrete sample (so the message isn't empty even
        # if this user's own area has no posts).
        idx = build_area_service_index()
        best_cats, best_area = [], None
        for lvl in ("upazila", "city", "state"):
            for key, cats in idx[lvl].items():
                if len(cats) > len(best_cats):
                    best_cats, best_area = cats, key
        area_label = (best_area or "এলাকা").title()
        area_services = [{"cat": c, "n": n} for c, n in best_cats[:3]]

        class _S:
            pending = {"area_label": area_label, "area_services": area_services}

        title, body = _area_services_build(_S(), user)

        tokens = list(
            FCMToken.objects.filter(user=user, is_active=True).values_list(
                "token", flat=True
            )
        )
        push_sent = 0
        for tk in tokens:
            try:
                send_fcm_notification_async(
                    fcm_token=tk,
                    title=title,
                    body=body,
                    data={
                        "type": "engagement",
                        "deep_link": "https://adsyclub.com/classified-categories",
                    },
                )
                push_sent += 1
            except Exception:
                pass

        try:
            email_ok = bool(
                send_engagement_email(
                    user,
                    subject=title,
                    heading=title,
                    body_html="<p>" + body + "</p>",
                    button_text="আমার সেবা দেখুন",
                    button_url="https://adsyclub.com/classified-categories",
                    content_feature="rideshare",
                )
            )
        except Exception:
            email_ok = False

        self.stdout.write(
            "AREATEST cats=%d push=%d/%d email=%s"
            % (len(area_services), push_sent, len(tokens), int(email_ok))
        )
