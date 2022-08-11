
%lang starknet

from starkware.starknet.common.syscalls import get_contract_address
from starkware.cairo.common.alloc import (
    alloc,
)
from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.interfaces.IERC20 import IERC20
from contracts.interfaces.IVotingEscrow import IVotingEscrow



from starkware.cairo.common.uint256 import Uint256


from protostar.asserts import (
    assert_eq, assert_not_eq, assert_signed_lt, assert_signed_le, assert_signed_gt,
    assert_unsigned_lt, assert_unsigned_le, assert_unsigned_gt, assert_signed_ge,
    assert_unsigned_ge)



#USER
const ADMIN = 'magnety-admin'
const USER_1 = 'user-1'
const WEEK = 86400 * 7
const YEAR = 86400 * 365
const MAXTIME = 4 * 365 * 86400

struct Point:
    member bias : felt
    member slope : felt
    member ts : felt
    member blk: felt
end

struct LockedBalance:
    member amount : Uint256
    member end_ts : felt
end
@view
func __setup__{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
    alloc_locals

    tempvar mg_contract
    tempvar ve_contract

    %{ 
    context.MG = deploy_contract("./contracts/mock/ERC20.cairo",[400,401, 18, 10000000000000000000, 0, ids.ADMIN, ids.ADMIN]).contract_address 
    ids.mg_contract = context.MG 
    context.VE = deploy_contract("./contracts/VotingEscrow.cairo",[ids.mg_contract, 11, 22, ids.ADMIN]).contract_address 
    ids.btc_contract = context.BTC
     %}
    return()
end



@external
func test_deposit{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}():
alloc_locals

    let (mg_contract) = mg_instance.deployed()
    let (ve_contract) = ve_instance.deployed()
    %{ stop_prank = start_prank(ids.ADMIN, ids.mg_contract) %}
     IVotingEscrow.create_lock(ve_contract,Uint256(1000000000000000000,0), YEAR)
    %{ stop_prank() %}

    

    return ()
end



namespace mg_instance:
    func deployed() -> (mg_instance : felt):
        tempvar mg_instance
        %{ ids.mg_instance = context.MG %}
        return (mg_instance)
    end
end

namespace ve_instance:
    func deployed() -> (ve_instance : felt):
        tempvar ve_instance
        %{ ids.ve_instance = context.VE %}
        return (ve_instance)
    end
end


