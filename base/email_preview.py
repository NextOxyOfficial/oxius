"""Admin email-template previews.

Renders the REAL email HTML for each template (using sample data) without
sending anything, by temporarily capturing ``email_service._send_email``. Used
by the "Email templates" admin page so you can see exactly what reaches the
customer and tune the design.
"""


class _SampleUser:
    """Duck-typed stand-in for a User, with every attribute the templates use."""
    email = "customer@example.com"
    first_name = "Rahim"
    last_name = "Uddin"
    name = "Rahim Uddin"
    username = "rahim"
    phone = "01700000000"
    balance = 5250
    pending_balance = 0
    referral_code = "ADSY1234"
    diamond_balance = 100

    def get_full_name(self):
        return "Rahim Uddin"


class _SampleSeller(_SampleUser):
    email = "seller@example.com"
    first_name = "Karim"
    last_name = "Hossain"
    name = "Karim Hossain"

    def get_full_name(self):
        return "Karim Hossain"


def _registry():
    """(key, label, render_callable) for every previewable email."""
    from . import email_service as es

    u = _SampleUser()
    s = _SampleSeller()
    return [
        ("welcome", "Welcome", lambda: es.send_welcome_email(u)),
        ("deposit", "Deposit confirmation", lambda: es.send_deposit_email(u, 1000, "TXN10001", "bKash")),
        ("withdraw", "Withdraw requested", lambda: es.send_withdraw_email(u, 500, "TXN10002", "bKash", "01700000000")),
        ("withdraw_approved", "Withdraw approved", lambda: es.send_withdraw_approved_email(u, 500, "TXN10002")),
        ("transfer_sent", "Transfer sent", lambda: es.send_transfer_sent_email(u, s, 250, "TXN10003")),
        ("transfer_received", "Transfer received", lambda: es.send_transfer_received_email(u, s, 250, "TXN10003")),
        ("gig_placed", "Gig order placed", lambda: es.send_gig_order_placed_email(u, s, "Logo Design", 1500, "ORD1001")),
        ("gig_completed", "Gig order completed", lambda: es.send_gig_order_completed_email(u, s, "Logo Design", 1500, "ORD1001")),
        ("gig_status", "Gig order status update", lambda: es.send_gig_order_status_email(u, "Logo Design", "ORD1001", "accepted", "Karim Hossain")),
        ("kyc_approved", "KYC approved", lambda: es.send_kyc_approved_email(u)),
        ("kyc_rejected", "KYC rejected", lambda: es.send_kyc_rejected_email(u, "Submitted document was unclear.")),
        ("suspended", "Account suspended", lambda: es.send_account_suspended_email(u, "Policy violation.")),
        ("unsuspended", "Account restored", lambda: es.send_account_unsuspended_email(u)),
        ("pro_subscription", "Pro subscription", lambda: es.send_pro_subscription_email(u, 1, 499)),
        ("referral_reward", "Referral reward", lambda: es.send_referral_reward_email(u, 100, "signup")),
        ("password_reset", "Password reset OTP", lambda: es.send_password_reset_email(u, "123456")),
        ("mobile_recharge", "Mobile recharge", lambda: es.send_mobile_recharge_email(u, 50, "01700000000")),
    ]


def email_template_choices():
    return [(key, label) for key, label, _ in _registry()]


def render_email_preview(key):
    """Return (subject, html) for the template `key`, captured without sending."""
    from . import email_service as es

    reg = {k: fn for k, _, fn in _registry()}
    fn = reg.get(key)
    if fn is None:
        return ("", "<p style='font-family:sans-serif;padding:24px;'>Unknown template.</p>")

    captured = []
    original_send = es._send_email

    def _capture(subject, to_email, text_content, html_content):
        captured.append((subject, html_content))
        return True  # don't actually send

    es._send_email = _capture
    try:
        fn()
    except Exception as e:  # show the error instead of a blank page
        return ("Preview error", f"<pre style='padding:24px;color:#b91c1c;'>{e}</pre>")
    finally:
        es._send_email = original_send

    if captured:
        return captured[0]
    return ("", "<p style='font-family:sans-serif;padding:24px;'>This template produced no email.</p>")
