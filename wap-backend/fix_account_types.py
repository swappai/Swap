"""Fix script: find seeded business profiles missing account_type and patch them."""

import requests

BASE_URL = "https://app-swapai-backend.azurewebsites.net"
TIMEOUT = 30

# Business profiles from seed_users.py: (name, email)
BUSINESSES = [
    ("Hog Wash Supercenter", "hogwash@example.com"),
    ("Community Bakery", "communitybakery@example.com"),
    ("The Root Cafe", "therootcafe@example.com"),
    ("Rock City Outfitters", "rockcity@example.com"),
    ("Blue Cake Company", "bluecake@example.com"),
    ("Arkansas Graphics", "arkgraphics@example.com"),
    ("Natural State Smoothies", "nssmoothies@example.com"),
    ("Philander Smith College Bookstore", "pscbookstore@example.com"),
]


def fix():
    fixed = 0
    skipped = 0
    failed = 0

    for name, email in BUSINESSES:
        # Look up profile by email
        resp = requests.get(f"{BASE_URL}/profiles/email/{email}", timeout=TIMEOUT)
        if resp.status_code == 404:
            print(f"· Not found: {name} ({email})")
            skipped += 1
            continue
        if resp.status_code != 200:
            print(f"✗ Lookup failed for {name}: {resp.status_code}")
            failed += 1
            continue

        profile = resp.json()
        uid = profile["uid"]
        current_type = profile.get("account_type", "")

        if current_type == "business":
            print(f"· Already business: {name}")
            skipped += 1
            continue

        # Patch to business
        patch_resp = requests.patch(
            f"{BASE_URL}/profiles/{uid}",
            json={"account_type": "business"},
            timeout=TIMEOUT,
        )
        if patch_resp.status_code == 200:
            print(f"✓ Fixed: {name} ({uid}) → business")
            fixed += 1
        else:
            print(f"✗ Patch failed for {name}: {patch_resp.status_code} {patch_resp.text[:200]}")
            failed += 1

    print(f"\nDone! Fixed: {fixed}, Already correct/not found: {skipped}, Failed: {failed}")


if __name__ == "__main__":
    fix()
