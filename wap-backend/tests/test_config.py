"""Tests for app configuration / settings."""
import os

from app.config import Settings


def _fresh_settings(**overrides):
    """Create a fresh Settings instance (ignores the cached singleton)."""
    return Settings(**overrides)


def test_default_entra_audience():
    s = _fresh_settings()
    assert s.azure_entra_audience == "api://swap-api/access_as_user"


def test_default_cosmos_database_name():
    s = _fresh_settings()
    assert s.cosmos_database_name == "swap-db"


def test_default_embedding_deployment():
    s = _fresh_settings()
    assert s.azure_embedding_deployment == "text-embedding-3-large"


def test_vector_dim():
    s = _fresh_settings()
    assert s.vector_dim == 1536


def test_redis_defaults():
    s = _fresh_settings()
    assert s.redis_ttl == 3600
    assert s.redis_port == 6379


def test_app_name():
    s = _fresh_settings()
    assert s.app_name == "$wap"


def test_email_enabled_default():
    s = _fresh_settings()
    # EMAIL_ENABLED=false is set in conftest module-level
    assert s.email_enabled is False


def test_redis_disabled_in_tests():
    s = _fresh_settings()
    assert s.redis_enabled is False


def test_entra_settings_from_env():
    s = _fresh_settings()
    assert s.azure_entra_tenant_name == "testciam"
    assert s.azure_entra_tenant_id == "test-tenant-id"
    assert s.azure_entra_client_id == "test-client-id"


def test_cosmos_connection_string_from_env():
    s = _fresh_settings()
    assert s.cosmos_connection_string is not None
    assert "documents.azure.com" in s.cosmos_connection_string


def test_debug_true_in_tests():
    s = _fresh_settings()
    assert s.debug is True


def test_azure_search_settings():
    s = _fresh_settings()
    assert s.azure_search_endpoint == "https://test.search.windows.net"
    assert s.azure_search_index == "swap-users"


def test_azure_openai_settings():
    s = _fresh_settings()
    assert s.azure_openai_endpoint == "https://test.openai.azure.com/"
    assert s.azure_openai_api_version == "2024-02-01"


def test_app_url_default():
    s = _fresh_settings()
    assert isinstance(s.app_url, str)


def test_app_insights_not_configured_by_default():
    """App Insights connection string absent unless explicitly set."""
    s = _fresh_settings()
    assert s.applicationinsights_connection_string is None
