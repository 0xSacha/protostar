from typing import Optional

from protostar.protostar_exception import ProtostarException


class NoProtostarProjectFoundException(ProtostarException):
    pass


class VersionNotSupportedException(ProtostarException):
    pass


class InvalidProtostarTOMLException(ProtostarException):
    def __init__(self, section_name: str, attribute_name: Optional[str] = None):
        self.section_name = section_name
        self.attribute_name = attribute_name
        super().__init__(section_name)

    def __str__(self) -> str:
        msg = (
            f"Couldn't load [protostar.{self.section_name}]::{self.attribute_name}"
            if self.attribute_name
            else f"Couldn't load [protostar.{self.section_name}]"
        )
        return "\n".join(
            [
                "Invalid 'protostar.toml' configuration.",
                msg,
            ]
        )
