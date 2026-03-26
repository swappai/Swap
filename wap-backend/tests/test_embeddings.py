"""Test embedding service."""

import math
from unittest.mock import MagicMock, patch

import pytest


def _make_mock_embedding(dim=1536):
    """Return a normalized fake embedding vector."""
    val = 1.0 / math.sqrt(dim)
    return [val] * dim


def _mock_openai_response(embeddings):
    """Create a mock OpenAI embeddings response."""
    response = MagicMock()
    response.data = [MagicMock(embedding=emb) for emb in embeddings]
    return response


@patch("app.embeddings.AzureOpenAI")
def test_embedding_service_initialization(mock_openai_cls):
    """Test that embedding service initializes correctly."""
    from app.embeddings import EmbeddingService
    service = EmbeddingService()
    assert service.dimension == 1536


@patch("app.embeddings.AzureOpenAI")
def test_encode_single_text(mock_openai_cls):
    """Test encoding a single text."""
    fake_emb = _make_mock_embedding()
    mock_client = MagicMock()
    mock_client.embeddings.create.return_value = _mock_openai_response([fake_emb])
    mock_openai_cls.return_value = mock_client

    from app.embeddings import EmbeddingService
    service = EmbeddingService()
    embedding = service.encode("Python programming and web development")

    assert isinstance(embedding, list)
    assert len(embedding) == 1536
    assert all(isinstance(x, float) for x in embedding)


@patch("app.embeddings.AzureOpenAI")
def test_encode_batch(mock_openai_cls):
    """Test encoding multiple texts."""
    fake_embs = [_make_mock_embedding() for _ in range(3)]
    mock_client = MagicMock()
    mock_client.embeddings.create.return_value = _mock_openai_response(fake_embs)
    mock_openai_cls.return_value = mock_client

    from app.embeddings import EmbeddingService
    service = EmbeddingService()
    texts = ["Python programming", "Guitar lessons", "Web development"]
    embeddings = service.encode_batch(texts)

    assert isinstance(embeddings, list)
    assert len(embeddings) == 3
    assert all(len(emb) == 1536 for emb in embeddings)


@patch("app.embeddings.AzureOpenAI")
def test_embedding_normalization(mock_openai_cls):
    """Test that embeddings are normalized."""
    fake_emb = _make_mock_embedding()
    mock_client = MagicMock()
    mock_client.embeddings.create.return_value = _mock_openai_response([fake_emb])
    mock_openai_cls.return_value = mock_client

    from app.embeddings import EmbeddingService
    service = EmbeddingService()
    embedding = service.encode("Test text for normalization")

    norm = math.sqrt(sum(x * x for x in embedding))
    assert abs(norm - 1.0) < 0.01


@patch("app.embeddings.AzureOpenAI")
def test_similar_texts_have_similar_embeddings(mock_openai_cls):
    """Test that the service calls the API for each encode."""
    fake_emb = _make_mock_embedding()
    mock_client = MagicMock()
    mock_client.embeddings.create.return_value = _mock_openai_response([fake_emb])
    mock_openai_cls.return_value = mock_client

    from app.embeddings import EmbeddingService
    service = EmbeddingService()

    service.encode("Python programming and coding")
    service.encode("Python development and software engineering")
    service.encode("Guitar music and jazz")

    assert mock_client.embeddings.create.call_count == 3
