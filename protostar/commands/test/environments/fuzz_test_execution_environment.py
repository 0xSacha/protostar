import asyncio
import functools
import inspect
from typing import Optional, List, Callable, Awaitable, Any

from hypothesis import settings, seed, Verbosity, given
from hypothesis.database import InMemoryExampleDatabase
from hypothesis.reporting import with_reporter
from hypothesis.strategies import data, DataObject

from protostar.commands.test.environments.test_execution_environment import (
    TestExecutionEnvironment,
    TestCaseCheatcodeFactory,
)
from protostar.commands.test.fuzzing.strategy_selector import StrategySelector
from protostar.commands.test.starkware.execution_resources_summary import (
    ExecutionResourcesSummary,
)
from protostar.commands.test.starkware.test_execution_state import TestExecutionState
from protostar.commands.test.test_context import TestContextHintLocal
from protostar.commands.test.testing_seed import current_testing_seed
from protostar.utils.data_transformer_facade import DataTransformerFacade


def is_fuzz_test(function_name: str, state: TestExecutionState) -> bool:
    abi = state.contract.abi
    params = DataTransformerFacade.get_function_parameters(abi, function_name)
    return bool(params)


class FuzzTestExecutionEnvironment(TestExecutionEnvironment):
    def __init__(self, state: TestExecutionState):
        super().__init__(state)
        self.database = InMemoryExampleDatabase()

    async def invoke(self, function_name: str) -> Optional[ExecutionResourcesSummary]:
        abi = self.state.contract.abi
        parameters = DataTransformerFacade.get_function_parameters(abi, function_name)
        assert (
            parameters
        ), f"{self.__class__.__name__} expects at least one function parameter."

        self.set_cheatcodes(
            TestCaseCheatcodeFactory(
                state=self.state,
                expect_revert_context=self._expect_revert_context,
                finish_hook=self._finish_hook,
            )
        )

        self.set_custom_hint_locals([TestContextHintLocal(self.state.context)])

        execution_resources: List[ExecutionResourcesSummary] = []

        with with_reporter(protostar_reporter):
            strategy_selector = StrategySelector(parameters)

            @seed(current_testing_seed())
            @settings(database=self.database, deadline=None)
            @given(data_object=data())
            async def test(data_object: DataObject):
                inputs = {}
                for param in strategy_selector.parameter_names:
                    search_strategy = strategy_selector.search_strategies[param]
                    inputs[param] = data_object.draw(search_strategy, label=param)

                run_ers = await self.invoke_test_case(function_name, **inputs)
                if run_ers is not None:
                    execution_resources.append(run_ers)

            loop = asyncio.get_running_loop()

            test.hypothesis.inner_test = wrap_in_sync(test.hypothesis.inner_test)

            await loop.run_in_executor(None, test)

        return ExecutionResourcesSummary.sum(execution_resources)


def wrap_in_sync(func: Callable[..., Awaitable[Any]]):
    """
    Return a sync wrapper around an async function executing it in separate event loop.

    Separate event loop is used, because Hypothesis engine is running in current executor
    and is effectively blocking it.

    Partially borrowed from pytest-asyncio.
    """

    @functools.wraps(func)
    def inner(*args, **kwargs):
        coro = func(*args, **kwargs)
        assert inspect.isawaitable(coro)

        loop = asyncio.new_event_loop()
        task = asyncio.ensure_future(coro, loop=loop)
        try:
            loop.run_until_complete(task)
        except BaseException:
            # run_until_complete doesn't get the result from exceptions
            # that are not subclasses of `Exception`.
            # Consume all exceptions to prevent asyncio's warning from logging.
            if task.done() and not task.cancelled():
                task.exception()
            raise

    return inner


def protostar_reporter(value):
    # TODO(mkaput): Route logs to common Protostar logging infra.
    print(value)
