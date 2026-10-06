"""
URL configuration for config project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/6.1/topics/http/urls/
"""
from django.contrib import admin
from django.contrib.auth import views as auth_views
from django.urls import include, path

from .auth_views import OIDCAdminLoginView

urlpatterns = [
    # Present the familiar Admin login page for OIDC, without granting regular
    # users access to the Admin site itself.
    path('admin/login/', OIDCAdminLoginView.as_view(), name='oidc_admin_login'),
    path('admin/', admin.site.urls),
    # หน้า login/logout สำหรับผู้ใช้ทั่วไป (ไม่ต้องเป็น staff) ที่ OIDC Authorize จะพาไป
    path(
        'accounts/login/',
        auth_views.LoginView.as_view(template_name='admin/login.html'),
        name='login',
    ),
    path('accounts/logout/', auth_views.LogoutView.as_view(next_page='login'), name='logout'),
    # OIDC Authorization Server (django-oidc-provider):
    # /authorize/ /token/ /userinfo/ /jwks/ /.well-known/openid-configuration
    path('', include('oidc_provider.urls', namespace='oidc_provider')),
    path('api/', include('app.urls')),
]
