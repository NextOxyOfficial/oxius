from django.db import models
class Country(models.Model):
    name_eng = models.CharField(max_length=100)
    name_ban = models.CharField(max_length=100)

    def __str__(self):
        return f"{self.name_eng} - {self.name_eng}"
class Region(models.Model):
    name_eng = models.CharField(max_length=100)
    name_ban = models.CharField(max_length=100)
    country = models.ForeignKey(Country, on_delete=models.CASCADE)
    def __str__(self):
        return f"{self.name_eng} - {self.name_eng}"

class City(models.Model):
    name_eng = models.CharField(max_length=100)
    name_ban = models.CharField(max_length=100)
    region = models.ForeignKey(Region, on_delete=models.CASCADE)
    zip = models.CharField(max_length=100, null=True, blank=True)
    def __str__(self):
        return f"{self.name_eng} - {self.name_eng}"

class Upazila(models.Model):
    name_eng = models.CharField(max_length=100)
    name_ban = models.CharField(max_length=100)
    city = models.ForeignKey(City, on_delete=models.CASCADE)
    def __str__(self):
        return f"{self.name_eng} - {self.name_eng}"