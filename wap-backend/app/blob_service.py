"""Azure Blob Storage service for file uploads."""

from __future__ import annotations

import uuid
from typing import Optional

from azure.storage.blob import BlobServiceClient, ContentSettings

from app.config import settings


class BlobService:
    """Manages file uploads to Azure Blob Storage."""

    def __init__(self) -> None:
        conn_str = settings.azure_storage_connection_string
        if not conn_str:
            raise RuntimeError("AZURE_STORAGE_CONNECTION_STRING is not set.")
        self._client = BlobServiceClient.from_connection_string(conn_str)
        self._container_name = settings.azure_storage_container
        # Ensure container exists
        try:
            self._client.create_container(self._container_name, public_access="blob")
        except Exception:
            pass  # Container already exists

    def upload_profile_photo(
        self, uid: str, file_bytes: bytes, content_type: str
    ) -> str:
        """Upload a profile photo and return its public URL."""
        ext = _ext_from_content_type(content_type)
        blob_name = f"profiles/{uid}/{uuid.uuid4().hex}{ext}"
        container_client = self._client.get_container_client(self._container_name)
        container_client.upload_blob(
            name=blob_name,
            data=file_bytes,
            overwrite=True,
            content_settings=ContentSettings(content_type=content_type),
        )
        return f"{self._client.url}{self._container_name}/{blob_name}"

    def delete_profile_photo(self, uid: str) -> None:
        """Delete all profile photos for a user."""
        container_client = self._client.get_container_client(self._container_name)
        blobs = container_client.list_blobs(name_starts_with=f"profiles/{uid}/")
        for blob in blobs:
            container_client.delete_blob(blob.name)


def _ext_from_content_type(content_type: str) -> str:
    mapping = {
        "image/jpeg": ".jpg",
        "image/png": ".png",
        "image/gif": ".gif",
        "image/webp": ".webp",
    }
    return mapping.get(content_type, ".jpg")


_blob_service: Optional[BlobService] = None


def get_blob_service() -> BlobService:
    global _blob_service
    if _blob_service is None:
        _blob_service = BlobService()
    return _blob_service
