def normalize_customer_name(name: str) -> str:
    normalized = " ".join(name.split())
    if not normalized:
        raise ValueError("customer name must not be blank")
    return normalized


if __name__ == "__main__":
    print(normalize_customer_name("  Northwind   Labs "))
