from rest_framework import serializers
from .models import Booking, Room


class RoomSerializer(serializers.ModelSerializer):
    class Meta:
        model = Room
        fields = ['id', 'name', 'location', 'capacity', 'description']


class BookingSerializer(serializers.ModelSerializer):
    room_name = serializers.CharField(source='room.name', read_only=True)

    class Meta:
        model = Booking
        fields = ['id', 'room', 'room_name', 'start_time', 'end_time', 'purpose', 'status', 'created_at']
        read_only_fields = ['status', 'created_at']

    def validate(self, attrs):
        start = attrs.get('start_time', getattr(self.instance, 'start_time', None))
        end = attrs.get('end_time', getattr(self.instance, 'end_time', None))
        room = attrs.get('room', getattr(self.instance, 'room', None))
        if start >= end:
            raise serializers.ValidationError('end_time must be after start_time')
        overlapping = Booking.objects.filter(
            room=room, status=Booking.Status.CONFIRMED,
            start_time__lt=end, end_time__gt=start,
        )
        if self.instance:
            overlapping = overlapping.exclude(pk=self.instance.pk)
        if overlapping.exists():
            raise serializers.ValidationError('This room is already booked for that time')
        return attrs
