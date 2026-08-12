# -*- coding: utf-8 -*-
"""One row per externally-identified payment. The row IS the permission to credit.

WHY THIS TABLE EXISTS

Crediting a ShurjoPay deposit was guarded like this:

    existing = Balance.objects.filter(merchant_invoice_no=inv, ...).first()
    if existing:
        return already_processed
    Balance.objects.create(...)          # <- this is what moves the money

Two requests carrying the same genuine payment both run the SELECT before
either runs the INSERT, both see nothing, and both credit. `merchant_invoice_no`
carries no unique index, so the database had no opinion either. One payment,
two credits, repeatable by firing the same request concurrently.

A check followed by a write is not idempotency. The only thing that makes an
operation happen exactly once under concurrency is a single atomic statement the
database arbitrates — here, an INSERT against a UNIQUE constraint. Whoever
inserts the claim row is the one request allowed to credit; everyone else gets
IntegrityError, which means "already processed", not "error".

WHY A NEW TABLE RATHER THAN A CONSTRAINT ON `Balance`

Adding `unique=True` to `Balance.merchant_invoice_no` is the obvious move and it
is the wrong one for this system:

  * That column is `CharField(default="", blank=True, null=True)` and every
    non-ShurjoPay Balance row carries "" or NULL. In Postgres NULLs do not
    collide, but empty strings do — so a unique index would fail to build
    against production data the moment two rows share "". The migration would
    abort partway through a deploy on a live money table.
  * It would also constrain rows that have nothing to do with payment identity
    (withdrawals, transfers, referral rewards all live in that table).

A dedicated table starts empty, so its migration cannot fail on existing data,
and it constrains exactly the thing that needs constraining: the identity of an
external payment. It also keeps this app free of any import from `base`, so
there is no circular dependency and no coupling to the wallet work.
"""
from django.db import IntegrityError, models, transaction


class ProcessedPayment(models.Model):
    """A claim on one external payment. Created once, never updated in place.

    `account_id` and `balance_id` are plain char columns, not foreign keys, on
    purpose: this table must survive independently of whatever the payment
    credited, and an FK would tie its migrations to `base`.
    """

    provider = models.CharField(max_length=32, default="shurjopay")
    # The gateway's own identifier for the payment. For ShurjoPay this is
    # merchant_invoice_no, which is what the gateway echoes back on verify.
    invoice_no = models.CharField(max_length=190)

    account_id = models.CharField(max_length=64, blank=True, default="")
    balance_id = models.CharField(
        max_length=64, blank=True, default="",
        help_text="The Balance row this payment created, once it exists.",
    )
    amount = models.DecimalField(max_digits=12, decimal_places=2, default=0)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=["provider", "invoice_no"],
                name="uniq_processed_payment_provider_invoice",
            ),
        ]
        indexes = [
            models.Index(fields=["account_id", "-created_at"],
                         name="paid_account_recent_idx"),
        ]
        verbose_name = "processed payment"
        verbose_name_plural = "processed payments"

    def __str__(self):
        return f"{self.provider}:{self.invoice_no}"

    # ── the claim ───────────────────────────────────────────────────────────

    @classmethod
    def claim(cls, *, provider, invoice_no, account_id="", amount=0):
        """Try to become the one request allowed to credit this payment.

        Returns (claim, created). `created=False` means another request — quite
        possibly one running right now on another worker — already owns it and
        the caller must NOT move any money.

        The INSERT runs in its own atomic block so that the IntegrityError,
        which is an expected outcome here rather than a failure, cannot poison
        an enclosing transaction.
        """
        if not invoice_no:
            raise ValueError("A payment claim needs an invoice number")

        try:
            with transaction.atomic():
                claim = cls.objects.create(
                    provider=provider,
                    invoice_no=str(invoice_no),
                    account_id=str(account_id or ""),
                    amount=amount or 0,
                )
            return claim, True
        except IntegrityError:
            # Lost the race. The winner may not have committed its Balance row
            # yet, so the caller must treat this as "already processed" and
            # must not fall back to crediting.
            existing = cls.objects.filter(
                provider=provider, invoice_no=str(invoice_no)
            ).first()
            return existing, False

    @classmethod
    def release(cls, *, provider, invoice_no):
        """Give the claim back after a failed credit, so a retry can succeed.

        Only correct when the credit definitively did NOT happen — otherwise
        this reopens the double-credit window it exists to close.
        """
        return cls.objects.filter(
            provider=provider, invoice_no=str(invoice_no)
        ).delete()
