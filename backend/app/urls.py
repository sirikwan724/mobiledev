from django.urls import include, path
from rest_framework.routers import DefaultRouter

from .views import BookingViewSet, RoomViewSet

router = DefaultRouter()
router.register('rooms', RoomViewSet, basename='room')
router.register('bookings', BookingViewSet, basename='booking')

urlpatterns = [
    path('', include(router.urls)),
]
