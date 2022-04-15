from typing import List, Optional


class ReportedException(BaseException):
    """
    The exception used for catching unexpected errors thrown from test cases and as a base class.
    """

    def __str__(self) -> str:
        return str(super().__repr__())


class StandardReportedException(ReportedException):
    """
    The exception commonly used to display errors encountered during test execution.
    """

    def __init__(
        self,
        error_message: Optional[str] = None,
        error_type: Optional[str] = None,
        code: Optional[int] = None,
        details: Optional[str] = None,
    ) -> None:
        super().__init__(error_message)
        self.error_type = error_type
        self.error_message = error_message
        self.code = code
        self.details = details

    def __str__(self) -> str:
        result: List[str] = []

        if self.error_type:
            result.append(f"[type] {self.error_type}")

        if self.error_message:
            result.append(f"[message] {self.error_message}")

        if self.code:
            result.append(f"[code] {str(self.code)}")

        if self.details:
            result.append("[details]:\n")
            result.append(self.details)

        return "\n".join(result)


class RevertableException(BaseException):
    """
    This exception is caught by `except_revert` logic.
    """

    error_type: Optional[str]
    error_message: Optional[str]
    original_exception: Optional[BaseException]

    def __init__(
        self,
        exception: Optional[BaseException] = None,
        error_type: Optional[str] = None,
        error_message: Optional[str] = None,
    ) -> None:
        super().__init__(error_message)
        self.error_type = error_type
        self.error_message = error_message
        self.original_exception = exception

    def __str__(self) -> str:
        result: List[str] = []
        if self.error_type is not None:
            result.append(f"[error_type] {self.error_type}")

        if self.error_type is not None:
            result.append(f"[error_message] {self.error_message}")
        return "\n".join(result)

    def __eq__(self, other: "RevertableException") -> bool:
        return (self.error_type is None or self.error_type == other.error_type) and (
            self.error_message is None
            or self.error_message
            in (other.error_message or "")  # TODO: __eq__ -> match
        )


class ExpectedRevertMismatchException(ReportedException):
    def __init__(
        self,
        expected: RevertableException,
        received: RevertableException,
    ):
        self._expected = expected
        self._received = received
        super().__init__()

    def __str__(self) -> str:
        result: List[str] = []

        if self._expected:
            result.append("EXPECTED:")
            result.append(
                str(self._expected),
            )
        else:
            result.append("Expected any error")

        if self._received:
            result.append("INSTEAD GOT:")
            result.append(
                str(self._received),
            )
        else:
            result.append("instead got nothing")

        return "\n".join(result)