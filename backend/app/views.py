from rest_framework import serializers, viewsets
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Booking, Room
from .serializers import BookingSerializer, RoomSerializer


class RoomViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Room.objects.all()
    serializer_class = RoomSerializer
    permission_classes = (IsAuthenticated,)

    def get_queryset(self):
        queryset = Room.objects.all()
        start_value = self.request.query_params.get('start_time')
        end_value = self.request.query_params.get('end_time')
        if not start_value and not end_value:
            return queryset
        if not start_value or not end_value:
            raise serializers.ValidationError(
                {'detail': 'start_time and end_time must be provided together.'}
            )

        field = serializers.DateTimeField()
        start = field.run_validation(start_value)
        end = field.run_validation(end_value)
        if start >= end:
            raise serializers.ValidationError(
                {'detail': 'end_time must be later than start_time.'}
            )

        overlapping_bookings = Booking.objects.filter(
            status=Booking.Status.CONFIRMED,
            start_time__lt=end,
            end_time__gt=start,
        )
        return queryset.exclude(bookings__in=overlapping_bookings).distinct()


class BookingViewSet(viewsets.ModelViewSet):
    serializer_class = BookingSerializer
    permission_classes = (IsAuthenticated,)

    def get_queryset(self):
        return Booking.objects.filter(user=self.request.user).select_related('room')

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        booking = self.get_object()
        booking.status = Booking.Status.CANCELLED
        booking.save(update_fields=['status'])
        return Response(self.get_serializer(booking).data)
