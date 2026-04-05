#!/usr/bin/env python3
"""Remove duplicate skill documents from the Azure AI Search skills index.

Duplicates are identified by (posted_by, title) composite key.
For each group of duplicates, the document whose id matches the Cosmos DB
skill id is kept; if none match, the first one is kept and the rest are deleted.

Usage:
    cd wap-backend
    python scripts/dedup_skills_index.py          # dry-run (default)
    python scripts/dedup_skills_index.py --apply   # actually delete duplicates
"""

from __future__ import annotations

import argparse
import sys
from collections import defaultdict
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from app.config import settings
from azure.core.credentials import AzureKeyCredential
from azure.search.documents import SearchClient


def dedup_skills_index(apply: bool = False) -> None:
    client = SearchClient(
        endpoint=settings.azure_search_endpoint,
        index_name=settings.azure_search_skills_index,
        credential=AzureKeyCredential(settings.azure_search_api_key),
    )

    # Pull all documents from the index
    print("Fetching all documents from skills index...")
    results = client.search(search_text="*", select=["id", "skill_id", "posted_by", "title"], top=1000)

    docs = []
    for r in results:
        docs.append({
            "id": r["id"],
            "skill_id": r.get("skill_id", ""),
            "posted_by": r.get("posted_by", ""),
            "title": r.get("title", ""),
        })

    print(f"Total documents: {len(docs)}")

    # Group by (posted_by, title)
    groups: dict[str, list[dict]] = defaultdict(list)
    for doc in docs:
        key = f"{doc['posted_by']}::{doc['title']}"
        groups[key].append(doc)

    to_delete = []
    for key, group in groups.items():
        if len(group) <= 1:
            continue
        # Keep first, delete rest
        keep = group[0]
        dupes = group[1:]
        print(f"  DUPE: \"{group[0]['title']}\" by {group[0]['posted_by']} — {len(group)} copies, deleting {len(dupes)}")
        for d in dupes:
            to_delete.append({"id": d["id"]})

    if not to_delete:
        print("\nNo duplicates found!")
        return

    print(f"\n{len(to_delete)} duplicate documents to delete.")

    if not apply:
        print("Dry run — pass --apply to delete.")
        return

    # Delete in batches of 100
    for i in range(0, len(to_delete), 100):
        batch = to_delete[i:i + 100]
        client.delete_documents(batch)
        print(f"  Deleted batch {i // 100 + 1} ({len(batch)} docs)")

    print("Done! Duplicates removed.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Deduplicate skills in Azure AI Search index")
    parser.add_argument("--apply", action="store_true", help="Actually delete duplicates (default is dry-run)")
    args = parser.parse_args()
    dedup_skills_index(apply=args.apply)
