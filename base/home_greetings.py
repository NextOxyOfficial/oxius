"""Home-screen greeting rotator — a small ordered list the app cycles through
under the user's name:

  1. a time-of-day wish (শুভ সকাল / দুপুর / সন্ধ্যা / রাত্রি)
  2. today's Bengali (Bongabdo) date — e.g. "১৫ ফাল্গুন ১৪৩১"
  3. every ACTIVE HomeGreeting the admin has added, in order

Admin adds/edits messages from Django admin — no app release needed; the app
just re-fetches this list.

GET /api/home-greetings/  ->  {"items": ["শুভ রাত্রি 🌙", "১৫ ফাল্গুন ১৪৩১", ...]}
"""
import calendar
import datetime

from django.utils import timezone
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

_BN_DIGITS = {ord(str(i)): d for i, d in enumerate("০১২৩৪৫৬৭৮৯")}

# Revised Bangladesh calendar (2019): New Year = 14 April. First five months
# 31 days, next six 30, Choitro 30 — with Falgun 31 in a Gregorian leap year.
BENGALI_MONTHS = [
    "বৈশাখ", "জ্যৈষ্ঠ", "আষাঢ়", "শ্রাবণ", "ভাদ্র", "আশ্বিন",
    "কার্তিক", "অগ্রহায়ণ", "পৌষ", "মাঘ", "ফাল্গুন", "চৈত্র",
]


def _to_bn(n):
    return str(n).translate(_BN_DIGITS)


def bengali_date(g_date):
    """Gregorian date → Bangladesh-revised Bengali date string."""
    year = g_date.year
    new_year = datetime.date(year, 4, 14)
    if g_date >= new_year:
        b_year = year - 593
        start_year = year
        days = (g_date - new_year).days
    else:
        b_year = year - 594
        start_year = year - 1
        days = (g_date - datetime.date(start_year, 4, 14)).days

    lengths = [31, 31, 31, 31, 31, 30, 30, 30, 30, 30, 30, 30]
    # Falgun (index 10) spans ~mid-Feb → mid-Mar of start_year+1.
    if calendar.isleap(start_year + 1):
        lengths[10] = 31

    month = 0
    d = days
    for i, ln in enumerate(lengths):
        if d < ln:
            month = i
            break
        d -= ln
    day = d + 1
    return f"{_to_bn(day)} {BENGALI_MONTHS[month]} {_to_bn(b_year)}"


def time_greeting(now=None):
    now = now or timezone.localtime()
    h = now.hour
    if 5 <= h < 12:
        return "শুভ সকাল ☀️"
    if 12 <= h < 16:
        return "শুভ দুপুর 🌤️"
    if 16 <= h < 18:
        return "শুভ বিকাল 🌇"
    if 18 <= h < 20:
        return "শুভ সন্ধ্যা 🌆"
    return "শুভ রাত্রি 🌙"


@api_view(["GET"])
@permission_classes([AllowAny])
def home_greetings(request):
    from .models import HomeGreeting

    now = timezone.localtime()
    items = [time_greeting(now), bengali_date(now.date())]
    for m in HomeGreeting.objects.filter(is_active=True).order_by("order", "id"):
        text = (m.text or "").strip()
        if text:
            items.append(text)
    return Response({"items": items})
