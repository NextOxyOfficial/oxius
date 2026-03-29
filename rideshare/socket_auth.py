from urllib.parse import parse_qs

from channels.db import database_sync_to_async
from channels.middleware import BaseMiddleware
from django.contrib.auth.models import AnonymousUser
from rest_framework_simplejwt.tokens import AccessToken

from base.models import User


@database_sync_to_async
def get_user_for_token(token):
    try:
        validated = AccessToken(token)
        user_id = validated.get("user_id")
        return User.objects.get(id=user_id)
    except Exception:
        return AnonymousUser()


class JwtAuthMiddleware(BaseMiddleware):
    async def __call__(self, scope, receive, send):
        query_string = parse_qs(scope.get("query_string", b"").decode())
        token = None
        if query_string.get("token"):
            token = query_string["token"][0]

        if not token:
            headers = dict(scope.get("headers", []))
            cookie_header = headers.get(b"cookie", b"").decode()
            cookies = {}
            for chunk in cookie_header.split(";"):
                if "=" in chunk:
                    key, value = chunk.split("=", 1)
                    cookies[key.strip()] = value.strip()
            token = cookies.get("adsyclub-jwt")

        scope["user"] = await get_user_for_token(token) if token else AnonymousUser()
        return await super().__call__(scope, receive, send)
