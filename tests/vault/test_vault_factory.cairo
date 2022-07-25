%lang starknet

from starkware.starknet.common.syscalls import get_contract_address

from starkware.cairo.common.cairo_builtins import HashBuiltin

from openzeppelin.access.ownable import Ownable

@contract_interface
namespace IVaultFactory:
    func getOwner() -> (res : felt):
    end
end


@external
func test_ctor{syscall_ptr : felt*,pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals
    local contract_address : felt
    # We deploy contract and put its address into a local variable. Second argument is calldata array
    %{ ids.contract_address = deploy_contract("./contracts/VaultFactory.cairo",[111]).contract_address %}
    let (res) = IVaultFactory.getOwner(contract_address)
    assert res = 111
    return ()
end
