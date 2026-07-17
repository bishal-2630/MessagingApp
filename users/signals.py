from django.db.models.signals  import post_save
from django.dispatch import receiver
from .models import User, Profile

@receiver(post_save, sender=User)
def create_profile(sender,instance,created,**kwargs):
    if created:
        Profile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_profile(sender, instance, **kwargs):
    # Use get_or_create to safely handle users that existed before the Profile model (e.g. superuser)
    profile, _ = Profile.objects.get_or_create(user=instance)
    profile.save()