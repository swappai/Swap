"""
One-time script to fix poster_account_type in the skill search index.

For each business user, triggers a no-op PATCH on their skills so the
backend re-reads the profile's account_type and writes it to the search index.

Usage:
    python fix_skill_account_types.py

Requires the backend to be running (uses its REST API).
"""

import requests
import sys

API_BASE = "http://localhost:8000"

# List of known business user emails. Add more as needed.
BUSINESS_EMAILS = [
    # e.g. "business@example.com",
]


def fix_account_types():
    if not BUSINESS_EMAILS:
        print("No business emails configured. Edit BUSINESS_EMAILS in this script.")
        sys.exit(1)

    for email in BUSINESS_EMAILS:
        print(f"\n--- Processing {email} ---")

        # Look up profile by email
        resp = requests.get(f"{API_BASE}/profiles/email/{email}")
        if resp.status_code != 200:
            print(f"  Profile not found for {email}, skipping")
            continue

        profile = resp.json()
        uid = profile["uid"]
        account_type = profile.get("account_type", "person")
        print(f"  uid={uid}, account_type={account_type}")

        # Get their skills
        resp = requests.get(f"{API_BASE}/skills/user/{uid}")
        if resp.status_code != 200:
            print(f"  Could not fetch skills for {uid}")
            continue

        skills = resp.json()
        if not skills:
            print(f"  No skills found for {uid}")
            continue

        # PATCH each skill with a no-op update to trigger search index refresh
        for skill in skills:
            skill_id = skill.get("id")
            title = skill.get("title", "")
            print(f"  Patching skill {skill_id} ({title})...")
            patch_resp = requests.patch(
                f"{API_BASE}/skills/{skill_id}",
                json={"title": title},
                params={"uid": uid},
            )
            if patch_resp.status_code == 200:
                print(f"    OK")
            else:
                print(f"    Failed: {patch_resp.status_code} {patch_resp.text}")

    print("\nDone.")


if __name__ == "__main__":
    fix_account_types()
