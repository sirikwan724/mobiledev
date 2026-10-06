from urllib.parse import urlsplit

from django.contrib.auth import views as auth_views


class OIDCAdminLoginView(auth_views.LoginView):
    """Use Django's admin login page for OIDC without granting admin access."""

    template_name = 'admin/login.html'
    extra_context = {'title': 'Log in'}

    def form_valid(self, form):
        redirect_path = urlsplit(self.get_success_url()).path.rstrip('/')
        is_oidc_authorization = redirect_path == '/authorize'
        if not form.get_user().is_staff and not is_oidc_authorization:
            form.add_error(None, 'บัญชีนี้ใช้ได้สำหรับเข้าสู่ระบบแอปผ่าน OIDC เท่านั้น')
            return self.form_invalid(form)
        return super().form_valid(form)
