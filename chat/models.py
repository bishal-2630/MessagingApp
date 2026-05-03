from django.db import models

class Messages(models.Model):
    sender = models.CharField(max_length=100)
    content = models.TextField()
    image = models.ImageField(upload_to='messages/', null=True, blank=True)

    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.sender}: {self.content[:20]}"
    
