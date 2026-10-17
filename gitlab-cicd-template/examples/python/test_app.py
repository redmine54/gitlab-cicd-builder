import pytest

from app import normalize_customer_name


def test_normalize_customer_name():
    assert normalize_customer_name("  Northwind   Labs ") == "Northwind Labs"


def test_rejects_blank_name():
    with pytest.raises(ValueError):
        normalize_customer_name("  ")
