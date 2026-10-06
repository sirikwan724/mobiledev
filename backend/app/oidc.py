def userinfo(claims, user):
    """Claims ที่ /userinfo/ ส่งกลับให้ Flutter หลังล็อกอินสำเร็จ."""
    claims['name'] = user.get_username()
    claims['email'] = user.email
    return claims
