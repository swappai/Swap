"""Skills CRUD endpoints."""

from collections import defaultdict
from typing import List
from fastapi import APIRouter, HTTPException, Query

from app.schemas import SkillCreate, SkillUpdate, SkillResponse
from app.cosmos_db import get_cosmos_service
from app.embeddings import get_embedding_service
from app.azure_search import get_skills_search_service
from app.cache import get_cache_service

router = APIRouter(prefix="/skills", tags=["skills"])


def _build_embedding_text(data: dict) -> str:
    """Build text for embedding from skill data."""
    title = data.get("title", "")
    description = data.get("description", "")
    category = data.get("category", "")
    difficulty = data.get("difficulty", "")
    return f"{title} - {description}. Category: {category}. Level: {difficulty}"


def _rebuild_profile_skills(cosmos, uid: str) -> None:
    """Rebuild the profile skills_to_offer string from individual skill docs."""
    skills = cosmos.get_skills_by_user(uid)
    skill_strings = [
        f"{s['title']} ({s.get('difficulty', '')})" for s in skills if s.get("title")
    ]
    skills_to_offer = ", ".join(skill_strings) if skill_strings else ""
    cosmos.update_profile(uid, {"skills_to_offer": skills_to_offer})


@router.post("", response_model=SkillResponse)
def create_skill(
    skill: SkillCreate,
    uid: str = Query(..., description="UID of the user posting the skill"),
):
    """Create a new skill and index it for search."""
    cosmos = get_cosmos_service()
    embedding_service = get_embedding_service()
    skills_search = get_skills_search_service()

    # Verify user exists
    profile = cosmos.get_profile(uid)
    if not profile:
        raise HTTPException(status_code=404, detail="User profile not found")

    # Create skill doc in Cosmos
    skill_data = skill.model_dump()
    skill_doc = cosmos.create_skill(uid, skill_data)

    # Generate embedding and upsert to search index
    embed_text = _build_embedding_text(skill_doc)
    skill_vec = embedding_service.encode(embed_text)

    skills_search.upsert_skill(
        skill_id=skill_doc["id"],
        skill_vec=skill_vec,
        payload={
            "posted_by": skill_doc.get("posted_by", ""),
            "title": skill_doc.get("title", ""),
            "description": skill_doc.get("description", ""),
            "category": skill_doc.get("category", ""),
            "difficulty": skill_doc.get("difficulty", ""),
            "estimated_hours": skill_doc.get("estimated_hours", 1),
            "delivery": skill_doc.get("delivery", "Remote Only"),
            "tags": skill_doc.get("tags", []),
            "poster_name": profile.get("display_name") or profile.get("full_name", ""),
            "poster_city": profile.get("city", ""),
            "poster_swap_credits": profile.get("swap_credits", 0),
            "poster_average_rating": profile.get("average_rating", 0),
            "poster_review_count": profile.get("review_count", 0),
            "poster_account_type": profile.get("account_type", "person"),
        },
    )

    # Update profile skills_to_offer for backward compat
    _rebuild_profile_skills(cosmos, uid)

    return SkillResponse(**skill_doc)


@router.put("/{skill_id}", response_model=SkillResponse)
def update_skill(
    skill_id: str,
    skill: SkillUpdate,
    uid: str = Query(..., description="UID of the skill poster"),
):
    """Update an existing skill and re-index it for search."""
    cosmos = get_cosmos_service()
    embedding_service = get_embedding_service()
    skills_search = get_skills_search_service()

    # Verify user exists
    profile = cosmos.get_profile(uid)
    if not profile:
        raise HTTPException(status_code=404, detail="User profile not found")

    # Update skill doc in Cosmos (only non-None fields)
    update_data = skill.model_dump(exclude_none=True)
    if not update_data:
        raise HTTPException(status_code=400, detail="No fields to update")

    updated_doc = cosmos.update_skill(skill_id, uid, update_data)
    if not updated_doc:
        raise HTTPException(status_code=404, detail="Skill not found")

    # Re-generate embedding and upsert to search index
    embed_text = _build_embedding_text(updated_doc)
    skill_vec = embedding_service.encode(embed_text)

    skills_search.upsert_skill(
        skill_id=updated_doc["id"],
        skill_vec=skill_vec,
        payload={
            "posted_by": updated_doc.get("posted_by", ""),
            "title": updated_doc.get("title", ""),
            "description": updated_doc.get("description", ""),
            "category": updated_doc.get("category", ""),
            "difficulty": updated_doc.get("difficulty", ""),
            "estimated_hours": updated_doc.get("estimated_hours", 1),
            "delivery": updated_doc.get("delivery", "Remote Only"),
            "tags": updated_doc.get("tags", []),
            "poster_name": profile.get("display_name") or profile.get("full_name", ""),
            "poster_city": profile.get("city", ""),
            "poster_swap_credits": profile.get("swap_credits", 0),
            "poster_average_rating": profile.get("average_rating", 0),
            "poster_review_count": profile.get("review_count", 0),
            "poster_account_type": profile.get("account_type", "person"),
        },
    )

    # Rebuild profile skills_to_offer for backward compat
    _rebuild_profile_skills(cosmos, uid)

    return SkillResponse(**updated_doc)


@router.get("/user/{uid}", response_model=List[SkillResponse])
def get_skills_by_user(uid: str):
    """List all skills posted by a user."""
    cosmos = get_cosmos_service()
    skills = cosmos.get_skills_by_user(uid)
    return [SkillResponse(**s) for s in skills]


@router.get("/{skill_id}", response_model=SkillResponse)
def get_skill(
    skill_id: str,
    uid: str = Query(..., description="UID of the skill poster (partition key)"),
):
    """Get a single skill by ID."""
    cosmos = get_cosmos_service()
    skill = cosmos.get_skill(skill_id, uid)
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")
    return SkillResponse(**skill)


@router.delete("/{skill_id}")
def delete_skill(
    skill_id: str,
    uid: str = Query(..., description="UID of the skill poster"),
):
    """Delete a skill from Cosmos and search index."""
    cosmos = get_cosmos_service()
    skills_search = get_skills_search_service()

    skill = cosmos.get_skill(skill_id, uid)
    if not skill:
        raise HTTPException(status_code=404, detail="Skill not found")

    cosmos.delete_skill(skill_id, uid)
    skills_search.delete_skill(skill_id)

    # Rebuild profile skills_to_offer
    _rebuild_profile_skills(cosmos, uid)

    return {"message": "Skill deleted"}


@router.post("/admin/dedup-index")
def dedup_skills_index():
    """Remove duplicate documents from the skills search index.

    Duplicates are identified by (posted_by, title) and (poster_name, title).
    Keeps one document per group and deletes the rest.
    Also flushes skill search cache after dedup.
    """
    skills_search = get_skills_search_service()
    client = skills_search.search_client

    # Fetch all documents
    results = client.search(
        search_text="*",
        select=["id", "skill_id", "posted_by", "title", "poster_name"],
        top=1000,
    )

    docs = [
        {
            "id": r["id"],
            "posted_by": r.get("posted_by", ""),
            "title": r.get("title", ""),
            "poster_name": r.get("poster_name", ""),
        }
        for r in results
    ]

    # Pass 1: Group by (posted_by, title)
    groups: dict = defaultdict(list)
    for doc in docs:
        key = f"{doc['posted_by']}::{doc['title']}"
        groups[key].append(doc)

    to_delete = []
    surviving = []
    for key, group in groups.items():
        if len(group) > 1:
            to_delete.extend({"id": d["id"]} for d in group[1:])
            surviving.append(group[0])
        else:
            surviving.append(group[0])

    # Pass 2: Group by (poster_name, title) to catch seed duplicates
    display_groups: dict = defaultdict(list)
    for doc in surviving:
        key = f"{doc['poster_name']}::{doc['title']}"
        display_groups[key].append(doc)

    for key, group in display_groups.items():
        if len(group) > 1:
            to_delete.extend({"id": d["id"]} for d in group[1:])

    if not to_delete:
        # Still flush cache in case stale duplicates are cached
        cache_service = get_cache_service()
        cache_service.clear_pattern("skill_search:*")
        return {"message": "No duplicates found", "total_docs": len(docs)}

    for i in range(0, len(to_delete), 100):
        client.delete_documents(to_delete[i:i + 100])

    # Flush skill search cache so stale results with duplicates are cleared
    cache_service = get_cache_service()
    cleared = cache_service.clear_pattern("skill_search:*")

    return {
        "message": f"Deleted {len(to_delete)} duplicate documents",
        "total_docs": len(docs),
        "duplicates_removed": len(to_delete),
        "cache_keys_cleared": cleared,
    }
