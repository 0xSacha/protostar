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
    %{ context.VF = deploy_contract("./contracts/VaultFactory.cairo",[111]).contract_address %}
    %{ context.FU = deploy_contract("./contracts/Fuccount_mock.cairo",[8338,context.VF_address]).contract_address %}
    %{ context.PM = deploy_contract("./contracts/PolicyManager.cairo",[context.VF_address]).contract_address %}
    %{ context.IM = deploy_contract("./contracts/IntegrationManager.cairo",[context.VF_address]).contract_address %}
    %{ context.FM = deploy_contract("./contracts/FeeManager.cairo",[context.VF_address]).contract_address %}
    %{ context.OR = deploy_contract("./contracts/mock/EmpiricOracle.cairo",[context.VF_address]).contract_address %}
    %{ context.ETH = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 1000000000000000000, 0, 100, 1000]).contract_address %}
    %{ context.BTC = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 1000000000000000000, 0, 100, 1000]).contract_address %}
    %{ context.DAI = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 6, 1000000, 0, 100, 1000]).contract_address %}
    %{ context.VI = deploy_contract("./contracts/mock/ValueInterpreter.cairo",[context.VF_address, context.ETH]).contract_address %}


    %{ context.mock_fuccount = deploy_contract("./contracts/mock/EmpiricOracle.cairo",[context.VF_address]).contract_address %}
    %{ context.mock_fuccount = deploy_contract("./contracts/mock/EmpiricOracle.cairo",[context.VF_address]).contract_address %}
    %{ context.mock_fuccount = deploy_contract("./contracts/mock/EmpiricOracle.cairo",[context.VF_address]).contract_address %}

    %{ context.mock_fuccount = deploy_contract("./contracts/IntegrationManager.cairo",[context.VF_address]).contract_address %}

    return ()
end


@external
func test_something():
    tempvar contract_address
    %{ ids.contract_address = context.VF_address %}

    # ...

    return ()
end

@external
func test_ctor_basic{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    tempvar contract_address
    %{ ids.contract_address = context.VF_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    assert res = 111
    return ()
end


# @external
# func test_ctor_basic_fail{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     local contract_address : felt
#     # We deploy contract and put its address into a local variable. Second argument is calldata array
#     %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[1]).contract_address %}
#     let (res) = IVaultFactory.getOwner(contract_address)
#     %{ expect_revert() %}
#     assert_eq(res,111)
#     return ()
# end

# @external
# func test_ctor_basic_using_revert{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
#     alloc_locals
#     local contract_address : felt
#     # We deploy contract and put its address into a local variable. Second argument is calldata array
#     %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[0]).contract_address %}
#     let (res) = IVaultFactory.getOwner(contract_address)
#     %{ expect_revert() %}
#     assert_not_eq(res,0)
#     return ()
# end
