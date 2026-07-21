from http.cookies import SimpleCookie


def get_cookie_value(cookie_header, name):
    if not cookie_header:
        return ""

    cookie = SimpleCookie()
    cookie.load(cookie_header)
    morsel = cookie.get(name)
    return morsel.value.strip() if morsel else ""


def handler(event, context):
    headers = event.get("headers") or {}
    authorization = headers.get("authorization") or headers.get("Authorization") or ""
    cookie_header = headers.get("cookie") or headers.get("Cookie") or ""
    bearer_token = authorization.removeprefix("Bearer ").strip()
    cookie_token = get_cookie_value(cookie_header, "accessToken")
    token = bearer_token or cookie_token

    return {
        "isAuthorized": bool(token),
        "context": {
            "principalId": "xops-user" if token else "anonymous"
        },
    }
