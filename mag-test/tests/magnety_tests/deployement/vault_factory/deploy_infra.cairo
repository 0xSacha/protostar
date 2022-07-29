%lang starknet

from starkware.starknet.common.syscalls import get_contract_address

from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.access.ownable import Ownable

from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge)


@contract_interface
namespace IVaultFactory:
    func getOwner() -> (res : felt):
    end
end

@external
func __setup__():
    %{ context.VF_address = deploy_contract("./contracts/VaultFactory.cairo",[111]).contract_address %}
    
    %{ context.mock_fuccount = deploy_contract("./contracts/Fuccount_mock.cairo",[8338,context.VF_address]).contract_address %}
    return ()
end


@external
func test_something():
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}

    # ...

    return ()
end

@external
func test_ctor_basic{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.contract_a_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    assert res = 111
    return ()
end


@external
func test_ctor_basic_fail{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    local contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[1]).contract_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    %{ expect_revert() %}
    assert_eq(res,111)
    return ()
end

@external
func test_ctor_basic_using_revert{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    local contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[0]).contract_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    %{ expect_revert() %}
    assert_not_eq(res,0)
    return ()
end
