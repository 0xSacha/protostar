from pathlib import Path
from typing import Any

import pytest
from pytest_mock import MockerFixture

from protostar.utils.config.project import (
    NoProtostarProjectFoundException,
    Project,
    ProjectConfig,
    VersionNotSupportedException,
)
from protostar.utils.protostar_directory import VersionManager

current_directory = Path(__file__).parent


def make_mock_project(mocker, contracts, libs_path, pkg_root=None) -> Project:
    version_manager: Any = VersionManager(mocker.MagicMock())
    type(version_manager).protostar_version = mocker.PropertyMock(
        return_value=VersionManager.parse("0.1.0")
    )
    pkg = Project(version_manager, pkg_root)
    mock_config = ProjectConfig(
        contracts=contracts,
        libs_path=libs_path,
    )
    mocker.patch.object(pkg, attribute="load_config").return_value = mock_config
    mocker.patch.object(pkg, attribute="_project_config", new=mock_config)
    return pkg


@pytest.fixture(name="version_manager")
def fixture_version_manager(mocker: MockerFixture) -> VersionManager:
    version_manager: Any = VersionManager(mocker.MagicMock())
    type(version_manager).protostar_version = mocker.PropertyMock(
        return_value=VersionManager.parse("0.1.0")
    )
    return version_manager


def test_parsing_project_info(version_manager: VersionManager):
    proj = Project(
        version_manager, project_root=Path(current_directory, "examples", "standard")
    )
    config = proj.load_config()
    assert config.libs_path == "./lib"


def test_loading_argument(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "command_config"),
    )
    assert proj.load_argument("build", "disable-hint-validation") is True


def test_loading_nested_argument(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "nested"),
    )
    assert proj.load_argument("deploy.testnet", "network") == "foo"


def test_loading_argument_from_profile_section(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "profile"),
    )
    assert proj.load_argument("shared_command_configs", "no_color", profile_name="ci")


def test_loading_argument_kebab_case(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "kebab_case"),
    )
    assert proj.load_argument("shared_command_configs", "no_color", profile_name="ci")
    assert proj.load_argument("shared_command_configs", "no-color", profile_name="ci")


def test_loading_argument_from_not_defined_section(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "nested"),
    )
    assert proj.load_argument("foo.bar", "baz") is None


def test_loading_not_defined_argument(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "command_config"),
    )
    assert proj.load_argument("build", "foo") is None


def test_loading_argument_when_config_file_does_not_exist(
    version_manager: VersionManager, tmpdir
):
    proj = Project(
        version_manager,
        project_root=Path(tmpdir),
    )
    assert proj.load_argument("build", "disable-hint-validation") is None


def test_config_file_is_versioned(version_manager: VersionManager):
    proj = Project(
        version_manager, project_root=Path(current_directory, "examples", "standard")
    )
    protostar_config = proj.load_protostar_config()
    assert protostar_config.protostar_version == "0.1.0"


def test_handling_not_supported_version(version_manager: VersionManager):
    proj = Project(
        version_manager,
        project_root=Path(current_directory, "examples", "unsupported_config"),
    )
    with pytest.raises(VersionNotSupportedException):
        proj.load_config()


def test_no_project_found(version_manager: VersionManager, tmpdir):
    proj = Project(version_manager, Path(tmpdir))
    with pytest.raises(NoProtostarProjectFoundException):
        proj.load_config()


def test_libs_path(version_manager: VersionManager):
    project = Project(version_manager, Path(current_directory, "examples", "standard"))
    assert project.libs_path == project.project_root / "lib"
