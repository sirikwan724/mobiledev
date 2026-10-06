from oidc_provider.models import Token
from rest_framework.authentication import BaseAuthentication
from rest_framework.exceptions import AuthenticationFailed


class OIDCAccessTokenAuthentication(BaseAuthentication):
    """
    ตรวจสอบ Access Token ที่ออกโดย django-oidc-provider (OIDC Authorization Server)
    แนบมาใน Header: Authorization: Bearer <access_token>

    ทำให้ Booking API เป็น Resource Server ที่ใช้ token ชุดเดียวกับที่ Flutter
    ได้จากขั้นตอน OIDC Authorization Code Flow (สัปดาห์ที่ 12).
    """

    keyword = 'Bearer'

    def authenticate(self, request):
        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith(f'{self.keyword} '):
            return None

        access_token = auth_header[len(self.keyword) + 1:].strip()
        if not access_token:
            return None

        try:
            token = Token.objects.select_related('user').get(access_token=access_token)
        except Token.DoesNotExist:
            raise AuthenticationFailed('Invalid access token')

        if token.has_expired():
            raise AuthenticationFailed('Access token has expired')

        if token.user is None or not token.user.is_active:
            raise AuthenticationFailed('User inactive or not found')

        return (token.user, token)

    def authenticate_header(self, request):
        return self.keyword
