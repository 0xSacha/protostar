%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import (
    alloc,
)
struct ShareInfo:
    member contract: felt
    member tokenId: Uint256
end

# Define a storage variable.
@storage_var
func shareAmount() -> (res: felt):
end

@storage_var
func userShareAmount(user:felt) -> (res: felt):
end

@storage_var
func idToShareInfo(user:felt ,id: felt) -> (res: ShareInfo):
end

@storage_var
func shareInfoToId(share:ShareInfo) -> (id: felt):
end

# Getters
@view
func getShareAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        amount:felt):
    let (amount) = shareAmount.read()
    return (amount)
end

@view
func getUserShareAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_user: felt) -> (
        amount:felt):
    let (amount) = userShareAmount.read(_user)
    return (amount)
end



# Setters 
@external
func setNewMint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _caller:felt, _contract: felt, _tokenId:Uint256):
    let (currentShareAmount:felt) = shareAmount.read()
    shareAmount.write(currentShareAmount + 1)
    let (currentCallerShareAmount_:felt) = userShareAmount.read(_caller)
    idToShareInfo.write(_caller, currentCallerShareAmount_, ShareInfo(_contract, _tokenId))
    shareInfoToId.write(ShareInfo(_contract, _tokenId), currentCallerShareAmount_)
    userShareAmount.write(_caller, currentCallerShareAmount_ + 1)
    return ()
end

@external
func setNewBurn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _caller:felt, _contract: felt, _tokenId:Uint256):
    let (currentShareAmount:felt) = shareAmount.read()
    shareAmount.write(currentShareAmount - 1)

    let (currentCallerShareAmount_:felt) = userShareAmount.read(_caller)
    let (ShareInfoLast:ShareInfo) = idToShareInfo.read(_caller, currentCallerShareAmount_ - 1)
    idToShareInfo.write(_caller, currentCallerShareAmount_ - 1, ShareInfo(0,Uint256(0,0)))
    
    let (shareId_:felt) = shareInfoToId.read(ShareInfo(_contract, _tokenId)) 
    idToShareInfo.write(_caller, shareId_, ShareInfoLast)
    shareInfoToId.write(ShareInfoLast, shareId_)
    shareInfoToId.write(ShareInfo(_contract, _tokenId), 0)

    userShareAmount.write(_caller, currentCallerShareAmount_ - 1)
    return ()
end
