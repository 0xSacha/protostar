import pytest
from starkware.cairo.lang.compiler.ast.cairo_types import TypeFelt
from starkware.starknet.compiler.compile import compile_starknet_codes

from protostar.utils import DataTransformerFacade
from protostar.utils.data_transformer_facade import AbiItemNotFoundException


def test_get_function_parameters():
    code = """
%lang starknet

@external
func test_no_args():
    return ()
end

@external
func test_fuzz{syscall_ptr : felt*, range_check_ptr}(a, b : felt):
    return ()
end
"""
    abi = compile_starknet_codes([(code, "")]).abi

    assert not DataTransformerFacade.get_function_parameters(abi, "test_no_args")

    # Order is important here.
    parameters = DataTransformerFacade.get_function_parameters(abi, "test_fuzz")
    assert list(parameters.items()) == [
        ("a", TypeFelt()),
        ("b", TypeFelt()),
    ]


def test_get_function_parameters_raises_when_function_not_found():
    with pytest.raises(AbiItemNotFoundException):
        DataTransformerFacade.get_function_parameters([], "foobar")


def test_get_function_parameters_raises_when_asked_for_struct():
    with pytest.raises(AbiItemNotFoundException):
        DataTransformerFacade.get_function_parameters(
            [{"name": "foobar", "type": "struct"}], "foobar"
        )
