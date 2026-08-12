# -*- coding: utf-8 -*-
"""The only safe way to move money in or out of a user's wallet.

WHY THIS EXISTS

`User.balance` is written from 34 places across 8 modules. Roughly a third of
them already do it correctly — a conditional `UPDATE ... WHERE balance >= x`
with an `F()` expression, which is atomic and cannot go negative. The rest do:

    balance = user.balance      # read
    if balance >= price: ...    # check
    user.balance = balance - price
    user.save()                 # write

Two requests interleaved there both read the same balance, both pass the check,
and the second write silently discards the first deduction. That is how one
balance funds two purchases, and how a double-tapped approve pays a worker
twice.

The correct pattern was not unknown — `Balance.save()` uses it for transfers
and for the withdrawal hold, with a comment explaining the exact bug it avoids,
and then does read-modify-write for the refund and the deposit eight lines
later. The knowledge existed; the shared function did not. This is that
function.

WHAT IT GUARANTEES

* Atomic — one statement, evaluated by the database, never by Python.
* Never negative — a debit that would overdraw fails and returns False rather
  than writing a negative balance.
* Server-authoritative amounts — callers pass a Decimal they computed from
  trusted records; this module refuses zero, negative and non-numeric input.
* Auditable — every movement carries a `reason`, logged, so a balance change
  can always be traced back to the operation that caused it.

WHAT IT DELIBERATELY DOES NOT DO

It does not write `Balance` ledger rows. `Balance.save()` is itself what
performs money movement today, so writing one from here would recurse. Keeping
this module purely about the balance column is what makes it safe to call from
inside `Balance.save()`.
"""
import logging
from decimal import ROUND_HALF_UP, Decimal, InvalidOperation

from django.db import transaction
from django.db.models import F

logger = logging.getLogger(__name__)


class WalletError(Exception):
    """A refused wallet operation. Never raised for insufficient funds —
    that is an expected outcome and comes back as a return value."""


def to_money(value):
    """A Decimal with two places, or a WalletError.

    Floats are accepted but routed through str() first: Decimal(0.1) is
    0.1000000000000000055511151231257827, and money arithmetic with that is
    how rounding drift starts.
    """
    try:
        amount = Decimal(str(value))
    except (InvalidOperation, TypeError, ValueError):
        raise WalletError("Invalid money amount: %r" % (value,))
    if amount != amount:  # NaN
        raise WalletError("Invalid money amount: NaN")
    # ROUND_HALF_UP explicitly. Decimal's default is ROUND_HALF_EVEN (banker's
    # rounding), which sends 10.005 to 10.00 — statistically tidy and, for a
    # user looking at a wallet, simply wrong. Currency rounds half away from
    # zero, and leaving it implicit means the behaviour changes if anyone ever
    # touches the decimal context.
    return amount.quantize(Decimal("0.01"), rounding=ROUND_HALF_UP)


def _validate(user_id, amount):
    if not user_id:
        raise WalletError("A wallet operation needs a user")
    amount = to_money(amount)
    if amount <= 0:
        # A zero or negative credit is a debit in disguise, and vice versa.
        # Refusing here means a sign error surfaces as an exception at the
        # call site instead of silently moving money the wrong way.
        raise WalletError("Amount must be greater than zero, got %s" % amount)
    return amount


def debit(user_id, amount, *, reason, allow_negative=False):
    """Take [amount] from a user's wallet. Returns True if it happened.

    Returns **False** when the balance is insufficient — that is an ordinary
    outcome, not an error, and the caller decides what to tell the user. The
    check and the write are one statement, so two concurrent debits cannot both
    pass it.
    """
    from .models import User

    amount = _validate(user_id, amount)

    query = User.objects.filter(pk=user_id)
    if not allow_negative:
        # The guard IS the concurrency control: whichever UPDATE reaches the
        # row second re-evaluates balance >= amount against the already
        # decremented value and matches zero rows.
        query = query.filter(balance__gte=amount)

    with transaction.atomic():
        changed = query.update(balance=F("balance") - amount)

    if changed:
        logger.info("WALLET debit user=%s amount=%s reason=%s",
                    user_id, amount, reason)
    else:
        logger.info("WALLET debit REFUSED (insufficient) user=%s amount=%s "
                    "reason=%s", user_id, amount, reason)
    return bool(changed)


def credit(user_id, amount, *, reason):
    """Add [amount] to a user's wallet. Returns True if the user existed."""
    from .models import User

    amount = _validate(user_id, amount)

    with transaction.atomic():
        changed = User.objects.filter(pk=user_id).update(
            balance=F("balance") + amount
        )

    if not changed:
        # A credit to a user who no longer exists is money that vanished. This
        # used to log an error and return False, which every caller inside a
        # claim-then-credit block quietly ignored: the claim committed, the
        # payout did not, and the only trace was a log line. Insufficient funds
        # is an expected outcome and still comes back as a return value — a
        # missing recipient is a bug, so it raises and rolls the claim back.
        logger.error("WALLET credit LOST — no such user=%s amount=%s reason=%s",
                     user_id, amount, reason)
        raise WalletError(
            "Cannot credit %s to user %s: no such user" % (amount, user_id))

    logger.info("WALLET credit user=%s amount=%s reason=%s",
                user_id, amount, reason)
    return True


def transfer(from_user_id, to_user_id, amount, *, reason):
    """Move money between two wallets, both sides or neither.

    Refuses a self-transfer: the sender and the receiver would be two Python
    objects over one database row, and the second save would write back the
    pre-deduction balance plus the amount — minting money.
    """
    amount = _validate(from_user_id, amount)
    if not to_user_id:
        raise WalletError("A transfer needs a recipient")
    if str(from_user_id) == str(to_user_id):
        raise WalletError("Cannot transfer to the same wallet")

    with transaction.atomic():
        if not debit(from_user_id, amount, reason=reason):
            return False
        credit(to_user_id, amount, reason=reason)
    return True


def move_pending(user_id, amount, *, to_balance, reason):
    """Settle escrow: move [amount] between pending_balance and balance.

    Micro-gig money is reserved into `pending_balance` when a task is submitted
    and released into `balance` when it is approved. Doing that as two separate
    read-modify-writes is what let a double-tapped approval pay twice.
    """
    from .models import User

    amount = _validate(user_id, amount)

    with transaction.atomic():
        if to_balance:
            # Release: pending -> balance. The pending guard is what makes a
            # second, concurrent release match zero rows.
            changed = User.objects.filter(
                pk=user_id, pending_balance__gte=amount
            ).update(
                pending_balance=F("pending_balance") - amount,
                balance=F("balance") + amount,
            )
        else:
            # Reserve: balance -> pending.
            changed = User.objects.filter(
                pk=user_id, balance__gte=amount
            ).update(
                balance=F("balance") - amount,
                pending_balance=F("pending_balance") + amount,
            )

    logger.info("WALLET pending %s user=%s amount=%s reason=%s ok=%s",
                "release" if to_balance else "reserve",
                user_id, amount, reason, bool(changed))
    return bool(changed)


def credit_pending(user_id, amount, *, reason):
    """Put [amount] into a user's pending_balance from OUTSIDE their wallet.

    `move_pending` shuffles money between a user's own two columns. This is for
    escrow that arrives from somewhere else entirely — a micro-gig's funding
    pot reserving a payout for a worker who has not earned it yet. The worker's
    own balance is untouched; only the money already deducted from the funding
    pot lands here.
    """
    from .models import User

    amount = _validate(user_id, amount)

    with transaction.atomic():
        changed = User.objects.filter(pk=user_id).update(
            pending_balance=F("pending_balance") + amount
        )

    if changed:
        logger.info("WALLET pending credit user=%s amount=%s reason=%s",
                    user_id, amount, reason)
    else:
        logger.error("WALLET pending credit LOST — no such user=%s amount=%s "
                     "reason=%s", user_id, amount, reason)
    return bool(changed)


def buy_diamonds(user_id, cost, diamonds, *, reason):
    """Exchange wallet balance for diamonds in a single statement.

    Diamonds are a second currency living on the same row, and the two columns
    have to move together or not at all — a debit that succeeds while the grant
    fails takes money for nothing, and the reverse mints diamonds. One UPDATE
    touching both columns makes that indivisible without a lock.

    `cost` may be zero for a promotional pack: the diamonds are granted and no
    money moves. Returns False when the balance is insufficient, which is an
    ordinary outcome rather than an error.
    """
    from .models import User

    if not user_id:
        raise WalletError("A wallet operation needs a user")

    cost = to_money(cost)
    if cost < 0:
        raise WalletError("Diamond cost cannot be negative, got %s" % cost)
    diamonds = int(diamonds or 0)

    query = User.objects.filter(pk=user_id)
    if cost > 0:
        # The guard IS the concurrency control, exactly as in debit().
        query = query.filter(balance__gte=cost)

    with transaction.atomic():
        changed = query.update(
            balance=F("balance") - cost,
            diamond_balance=F("diamond_balance") + diamonds,
        )

    if changed:
        logger.info("WALLET diamonds user=%s cost=%s diamonds=%s reason=%s",
                    user_id, cost, diamonds, reason)
    else:
        logger.info("WALLET diamonds REFUSED (insufficient) user=%s cost=%s "
                    "reason=%s", user_id, cost, reason)
    return bool(changed)


def discard_pending(user_id, amount, *, reason):
    """Take [amount] back OUT of pending_balance without paying the user.

    The mirror of `credit_pending`: a reserved payout being returned to the pot
    it came from because the work was rejected. The guard is the concurrency
    control — a second attempt to discard the same reservation re-evaluates
    pending_balance >= amount against the already decremented value, matches no
    rows, and returns False rather than driving pending negative.
    """
    from .models import User

    amount = _validate(user_id, amount)

    with transaction.atomic():
        changed = User.objects.filter(
            pk=user_id, pending_balance__gte=amount
        ).update(pending_balance=F("pending_balance") - amount)

    logger.info("WALLET pending discard user=%s amount=%s reason=%s ok=%s",
                user_id, amount, reason, bool(changed))
    return bool(changed)
