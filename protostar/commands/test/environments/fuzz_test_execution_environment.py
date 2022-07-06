from protostar.commands.test.environments.test_execution_environment import (
    TestExecutionEnvironment,
)
from protostar.commands.test.starkware.test_execution_state import TestExecutionState
from protostar.utils.data_transformer_facade import DataTransformerFacade


def is_fuzz_test(function_name: str, state: TestExecutionState) -> bool:
    abi = state.contract.abi
    params = DataTransformerFacade.get_function_parameters(abi, function_name)
    return bool(params)


class FuzzTestExecutionEnvironment(TestExecutionEnvironment):
    pass
