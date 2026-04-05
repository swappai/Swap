"""Notification endpoints."""

from typing import List
from fastapi import APIRouter, HTTPException, Query

from app.cosmos_db import get_cosmos_service

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("")
def get_notifications(
    uid: str = Query(..., description="UID of the user"),
    limit: int = Query(50, ge=1, le=100),
):
    """Get notifications for a user."""
    cosmos = get_cosmos_service()
    items = cosmos.get_notifications(uid, limit=limit)
    return {"notifications": items}


@router.get("/unread-count")
def get_unread_count(uid: str = Query(..., description="UID of the user")):
    """Get unread notification count."""
    cosmos = get_cosmos_service()
    count = cosmos.get_unread_notification_count(uid)
    return {"unread_count": count}


@router.patch("/{notification_id}/read")
def mark_read(
    notification_id: str,
    uid: str = Query(..., description="UID of the user"),
):
    """Mark a notification as read."""
    cosmos = get_cosmos_service()
    cosmos.mark_notification_read(notification_id, uid)
    return {"message": "Marked as read"}


@router.patch("/read-all")
def mark_all_read(uid: str = Query(..., description="UID of the user")):
    """Mark all notifications as read."""
    cosmos = get_cosmos_service()
    count = cosmos.mark_all_notifications_read(uid)
    return {"message": f"Marked {count} notifications as read"}
