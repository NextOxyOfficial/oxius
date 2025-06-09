from django.db.models.signals import post_save, post_delete
from django.dispatch import receiver
from .models import Review, ProductRatingStats, ReviewHelpful


@receiver(post_save, sender=Review)
def update_product_rating_stats_on_review_save(sender, instance, created, **kwargs):
    """Update product rating stats when a review is created or updated"""
    # Get or create the rating stats for this product
    stats, created_stats = ProductRatingStats.objects.get_or_create(
        product=instance.product
    )
    
    # Update the stats
    stats.update_stats()


@receiver(post_delete, sender=Review)
def update_product_rating_stats_on_review_delete(sender, instance, **kwargs):
    """Update product rating stats when a review is deleted"""
    try:
        stats = ProductRatingStats.objects.get(product=instance.product)
        stats.update_stats()
    except ProductRatingStats.DoesNotExist:
        pass


@receiver(post_save, sender=ReviewHelpful)
def update_review_helpful_count_on_save(sender, instance, created, **kwargs):
    """Update review helpful count when a helpful vote is added"""
    if created:
        review = instance.review
        review.helpful_count = review.helpful_votes.count()
        review.save(update_fields=['helpful_count'])


@receiver(post_delete, sender=ReviewHelpful)
def update_review_helpful_count_on_delete(sender, instance, **kwargs):
    """Update review helpful count when a helpful vote is removed"""
    review = instance.review
    review.helpful_count = review.helpful_votes.count()
    review.save(update_fields=['helpful_count'])
