from pathlib import Path
from typing import cast
from unittest.mock import MagicMock

import pytest

from protostar.commands.test.test_command import TestCommand
from tests.integration.conftest import assert_cairo_test_cases


@pytest.mark.asyncio
async def test_deploy_contract(mocker):
    protostar_directory_mock = mocker.MagicMock()
    cast(MagicMock, protostar_directory_mock.add_protostar_cairo_dir).return_value = [
        Path() / "tests" / "integration" / "data"
    ]
    testing_summary = await TestCommand(
        project=mocker.MagicMock(),
        protostar_directory=protostar_directory_mock,
    ).test(targets=[f"{Path(__file__).parent}/deploy_contract_test.cairo"])

    assert_cairo_test_cases(
        testing_summary,
        expected_passed_test_cases_names=[
            "test_deploy_contract",
            "test_deploy_contract_simplified",
            "test_deploy_contract_with_constructor",
            "test_deploy_contract_with_constructor_steps",
            "test_deploy_contract_pranked",
            "test_deploy_the_same_contract_twice",
            "test_deploy_using_syscall",
            "test_syscall_after_deploy",
            "test_utilizes_cairo_path",
            "test_data_transformation",
            "test_passing_constructor_data_as_list",
        ],
        expected_failed_test_cases_names=[],
    )
