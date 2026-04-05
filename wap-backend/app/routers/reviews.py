"""Review management endpoints for completed swaps."""

from typing import Optional, List
from datetime import datetime, timezone

from fastapi import APIRouter, HTTPException, Query

from app.schemas import (
    ReviewCreate,
    ReviewResponse,
    ReviewListResponse,
)
from app.cosmos_db import get_cosmos_service

router = APIRouter(prefix="/reviews", tags=["reviews"])


def _enrich_review(review_data: dict, cosmos) -> ReviewResponse:
    """Enrich review with reviewer profile info."""
    reviewer_uid = review_data.get("reviewer_uid")
    reviewer_name = None
    reviewer_photo = None

    if reviewer_uid:
        profile = cosmos.get_profile(reviewer_uid)
        if profile:
            reviewer_name = profile.get("display_name") or profile.get("full_name")
            reviewer_photo = profile.get("photo_url")

    created_at = review_data.get("created_at", "")
    if hasattr(created_at, "isoformat"):
        created_at = created_at.isoformat()

    return ReviewResponse(
        id=review_data.get("id", ""),
        swap_request_id=review_data.get("swap_request_id", ""),
        reviewer_uid=reviewer_uid or "",
        reviewed_uid=review_data.get("reviewed_uid", ""),
        rating=review_data.get("rating", 0),
        review_text=review_data.get("review_text"),
        skill_exchanged=review_data.get("skill_exchanged"),
        hours_exchanged=review_data.get("hours_exchanged"),
        created_at=str(created_at),
        reviewer_name=reviewer_name,
        reviewer_photo=reviewer_photo,
    )


@router.post("", response_model=ReviewResponse)
def submit_review(
    review: ReviewCreate,
    uid: str = Query(..., description="UID of the reviewer"),
):
    """
    Submit a review for a completed swap.

    - Can only review swaps you participated in
    - Can only review swaps with 'completed' status
    - Can only submit one review per swap
    """
    cosmos = get_cosmos_service()

    # Get the swap request
    swap_data = cosmos.get_swap_request_by_id(review.swap_request_id)
    if not swap_data:
        raise HTTPException(status_code=404, detail="Swap request not found")

    requester_uid = swap_data.get("requester_uid")
    recipient_uid = swap_data.get("recipient_uid")

    # Verify user was a participant
    if uid not in [requester_uid, recipient_uid]:
        raise HTTPException(status_code=403, detail="You can only review swaps you participated in")

    # Verify swap is completed
    if swap_data.get("status") != "completed":
        raise HTTPException(status_code=400, detail="Can only review completed swaps")

    # Determine who is being reviewed
    reviewed_uid = recipient_uid if uid == requester_uid else requester_uid

    # Check if user already submitted a review for this swap
    if cosmos.check_review_exists(review.swap_request_id, uid):
        raise HTTPException(status_code=400, detail="You have already reviewed this swap")

    # Get completion data for hours exchanged
    completion = swap_data.get("completion", {})
    final_hours = completion.get("final_hours", 1.0)

    # Determine skill exchanged (what the reviewer received)
    if uid == requester_uid:
        skill_exchanged = swap_data.get("requester_need")
    else:
        skill_exchanged = swap_data.get("requester_offer")

    # Create review document
    review_doc = cosmos.create_review(reviewed_uid, {
        "swap_request_id": review.swap_request_id,
        "reviewer_uid": uid,
        "rating": review.rating,
        "review_text": review.review_text,
        "skill_exchanged": skill_exchanged,
        "hours_exchanged": final_hours,
    })

    # Update the reviewed user's profile stats
    _update_user_review_stats(cosmos, reviewed_uid)

    # Award credits to the reviewed user
    _award_credits_for_review(cosmos, reviewed_uid, final_hours, review.rating)

    return _enrich_review(review_doc, cosmos)


def _update_user_review_stats(cosmos, uid: str):
    """Update a user's average rating and review count in their profile."""
    reviews = cosmos.get_reviews_for_user(uid, limit=1000)
    if not reviews:
        return

    ratings = [r.get("rating", 0) for r in reviews]
    avg_rating = sum(ratings) / len(ratings) if ratings else 0.0
    review_count = len(ratings)

    cosmos.update_profile(uid, {
        "average_rating": round(avg_rating, 2),
        "review_count": review_count,
    })

    # Re-index profile in Azure Search
    try:
        from app.azure_search import get_azure_search_service
        from app.embeddings import get_embedding_service
        profile = cosmos.get_profile(uid)
        if profile:
            embedding_svc = get_embedding_service()
            offer_vec = embedding_svc.encode(profile.get("skills_to_offer", "") or "")
            need_vec = embedding_svc.encode(profile.get("services_needed", "") or "")
            search_svc = get_azure_search_service()
            search_svc.upsert_profile(
                username=profile.get("uid", uid),
                offer_vec=offer_vec,
                need_vec=need_vec,
                payload=profile,
            )
    except Exception:
        pass  # Non-fatal: search index will catch up


def _award_credits_for_review(cosmos, uid: str, hours: float, rating: int):
    """Award swap credits based on a review received."""
    rating_factor = rating / 3.0
    credits = max(1, round(hours * rating_factor))

    profile = cosmos.get_profile(uid)
    if profile:
        current_credits = profile.get("swap_credits", 0) or 0
        cosmos.update_profile(uid, {"swap_credits": current_credits + credits})


@router.get("/user/{uid}", response_model=ReviewListResponse)
def get_user_reviews(
    uid: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Get reviews received by a user."""
    cosmos = get_cosmos_service()

    all_reviews = cosmos.get_reviews_for_user(uid, limit=1000)
    total = len(all_reviews)

    ratings = [r.get("rating", 0) for r in all_reviews]
    avg_rating = sum(ratings) / len(ratings) if ratings else 0.0

    paginated = all_reviews[offset:offset + limit]
    reviews = [_enrich_review(r, cosmos) for r in paginated]

    return ReviewListResponse(
        reviews=reviews,
        total=total,
        average_rating=round(avg_rating, 2),
    )


@router.get("/given/{uid}", response_model=ReviewListResponse)
def get_reviews_given(
    uid: str,
    limit: int = Query(20, ge=1, le=100),
    offset: int = Query(0, ge=0),
):
    """Get reviews given by a user."""
    cosmos = get_cosmos_service()

    all_reviews = cosmos.get_reviews_by_reviewer(uid, limit=1000)
    total = len(all_reviews)

    ratings = [r.get("rating", 0) for r in all_reviews]
    avg_rating = sum(ratings) / len(ratings) if ratings else 0.0

    paginated = all_reviews[offset:offset + limit]
    reviews = [_enrich_review(r, cosmos) for r in paginated]

    return ReviewListResponse(
        reviews=reviews,
        total=total,
        average_rating=round(avg_rating, 2),
    )


@router.get("/swap/{swap_request_id}")
def get_swap_reviews(
    swap_request_id: str,
    uid: str = Query(..., description="UID of the requesting user"),
):
    """Get all reviews for a specific swap."""
    cosmos = get_cosmos_service()

    swap_data = cosmos.get_swap_request_by_id(swap_request_id)
    if not swap_data:
        raise HTTPException(status_code=404, detail="Swap request not found")

    if uid not in [swap_data.get("requester_uid"), swap_data.get("recipient_uid")]:
        raise HTTPException(status_code=403, detail="You can only view reviews for swaps you participated in")

    review_docs = cosmos.get_reviews_for_swap(swap_request_id)
    reviews = [_enrich_review(r, cosmos) for r in review_docs]

    user_has_reviewed = any(r.reviewer_uid == uid for r in reviews)

    return {
        "swap_request_id": swap_request_id,
        "reviews": reviews,
        "user_has_reviewed": user_has_reviewed,
        "can_review": swap_data.get("status") == "completed" and not user_has_reviewed,
    }
