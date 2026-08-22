from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse


class AriseException(Exception):
    def __init__(self, code: str, message: str, status_code: int = 400):
        self.code = code
        self.message = message
        self.status_code = status_code
        super().__init__(message)


class NotFoundError(AriseException):
    def __init__(self, resource: str, identifier: str | int):
        super().__init__(
            code=f"{resource.upper()}_NOT_FOUND",
            message=f"{resource.capitalize()} '{identifier}' not found.",
            status_code=404,
        )


class UnauthorizedError(AriseException):
    def __init__(self, message: str = "Authentication required."):
        super().__init__(code="UNAUTHORIZED", message=message, status_code=401)


class ForbiddenError(AriseException):
    def __init__(self, message: str = "You do not have permission to perform this action."):
        super().__init__(code="FORBIDDEN", message=message, status_code=403)


class ConflictError(AriseException):
    def __init__(self, message: str):
        super().__init__(code="CONFLICT", message=message, status_code=409)


class ValidationError(AriseException):
    def __init__(self, message: str):
        super().__init__(code="VALIDATION_ERROR", message=message, status_code=422)


async def arise_exception_handler(request: Request, exc: AriseException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": exc.code, "message": exc.message}},
    )


async def http_exception_handler(request: Request, exc: HTTPException) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content={"error": {"code": "HTTP_ERROR", "message": exc.detail}},
    )
