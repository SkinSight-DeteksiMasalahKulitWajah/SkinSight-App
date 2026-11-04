from typing import Generator, Optional
from fastapi import Header, HTTPException, status


async def get_current_user_token(authorization: Optional[str] = Header(None)) -> Optional[str]:
    """Extract Bearer token from request authorization header."""
    if not authorization:
        return None

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header otorisasi tidak valid.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return token
