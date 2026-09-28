"""Send the «يوجد تحديث جديد» push to every app install (FCM topic).

Run by .github/workflows/shorebird.yml after a patch is published. Reads the
Firebase service-account JSON from $FIREBASE_SA (never printed) and sends one
FCM HTTP v1 message to the topic the app subscribes to (kAppUpdatesTopic in
lib/core/ota/ota_updater.dart). data.type=app_update makes the app open its
update pop-up instead of showing a normal notification.
"""
import json
import os
import sys

import requests
from google.auth.transport.requests import Request
from google.oauth2 import service_account

TOPIC = "app-updates"
CHANNEL = "hoberadius_push"  # the app's Android notification channel


def main() -> int:
    info = json.loads(os.environ["FIREBASE_SA"])
    creds = service_account.Credentials.from_service_account_info(
        info, scopes=["https://www.googleapis.com/auth/firebase.messaging"]
    )
    creds.refresh(Request())
    url = f"https://fcm.googleapis.com/v1/projects/{info['project_id']}/messages:send"
    # What's new: items separated by " | " (workflow input «notes»).
    items = [i.strip() for i in os.environ.get("NOTES", "").split("|") if i.strip()]
    if items:
        body = "\n".join("• " + i for i in items[:4])
        if len(items) > 4:
            body += f"\n… و{len(items) - 4} أخرى"
    else:
        body = "اضغط لتثبيت التحديث الجديد لتطبيق HobeRadius."
    message = {
        "message": {
            "topic": TOPIC,
            "notification": {
                "title": "يوجد تحديث جديد",
                "body": body,
            },
            "data": {"type": "app_update", "notes": " | ".join(items)},
            "android": {
                "priority": "high",
                # Long «what's new» lists expand in the notification shade.
                "notification": {"channel_id": CHANNEL, "notification_count": 1},
            },
        }
    }
    r = requests.post(
        url,
        headers={"Authorization": f"Bearer {creds.token}"},
        json=message,
        timeout=30,
    )
    print("FCM", r.status_code, r.text[:300])
    return 0 if r.ok else 1


if __name__ == "__main__":
    sys.exit(main())
