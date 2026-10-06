from datetime import timedelta

from django.contrib.auth.models import User
from django.utils import timezone
from oidc_provider.models import Client, ResponseType, Token
from rest_framework.test import APITestCase

from .models import Room


class BookingApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user('alice', password='pw')
        self.room = Room.objects.create(name='Lab 1', capacity=30)
        self.start = timezone.now() + timedelta(days=1)

    def payload(self, offset_h=0, hours=2):
        s = self.start + timedelta(hours=offset_h)
        return {'room': self.room.id, 'start_time': s.isoformat(),
                'end_time': (s + timedelta(hours=hours)).isoformat()}

    def test_requires_auth(self):
        self.assertEqual(self.client.get('/api/bookings/').status_code, 401)

    def test_create_and_overlap_rejected(self):
        self.client.force_authenticate(self.user)
        self.assertEqual(self.client.post('/api/bookings/', self.payload(), format='json').status_code, 201)
        self.assertEqual(self.client.post('/api/bookings/', self.payload(1), format='json').status_code, 400)
        self.assertEqual(self.client.post('/api/bookings/', self.payload(2), format='json').status_code, 201)

    def test_cancel_frees_slot(self):
        self.client.force_authenticate(self.user)
        b = self.client.post('/api/bookings/', self.payload(), format='json').data
        self.client.post(f"/api/bookings/{b['id']}/cancel/")
        self.assertEqual(self.client.post('/api/bookings/', self.payload(), format='json').status_code, 201)


class OIDCAccessTokenAuthenticationTests(APITestCase):
    """ตรวจว่า Resource Server (Booking API) ยอมรับ Access Token จริงที่ออกโดย OIDC Provider เท่านั้น."""

    def setUp(self):
        self.user = User.objects.create_user('student01', password='test1234')
        rt, _ = ResponseType.objects.get_or_create(value='code', defaults={'description': 'code'})
        self.oidc_client = Client.objects.create(
            name='flutter-web-app', client_id='flutter-web-app', client_type='public',
        )
        self.oidc_client.redirect_uris = ['http://localhost:50000/callback']
        self.oidc_client.save()
        self.oidc_client.response_types.set([rt])

    def _make_token(self, expired=False):
        return Token.objects.create(
            user=self.user, client=self.oidc_client,
            access_token='atk-' + ('x' * 10),
            refresh_token='rtk-' + ('x' * 10),
            expires_at=timezone.now() + (timedelta(hours=-1) if expired else timedelta(hours=1)),
        )

    def test_no_token_rejected(self):
        self.assertEqual(self.client.get('/api/rooms/').status_code, 401)

    def test_valid_oidc_access_token_accepted(self):
        token = self._make_token()
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        self.assertEqual(self.client.get('/api/rooms/').status_code, 200)

    def test_unknown_token_rejected(self):
        self.client.credentials(HTTP_AUTHORIZATION='Bearer does-not-exist')
        self.assertEqual(self.client.get('/api/rooms/').status_code, 401)

    def test_expired_token_rejected(self):
        token = self._make_token(expired=True)
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token.access_token}')
        self.assertEqual(self.client.get('/api/rooms/').status_code, 401)
