%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256
from starkware.starknet.common.syscalls import get_caller_address, get_contract_address
from starkware.cairo.common.alloc import (
    alloc,
)
struct MaxMin:
    member max: Uint256
    member min: Uint256
end

struct integration:
    member contract : felt
    member selector : felt
end

# Define a storage variable.
@storage_var
func vaultFactory() -> (vaultFactoryAddress : felt):
end

@storage_var
func maxminAmount(vault: felt) -> (res: MaxMin):
end

@storage_var
func timeLock(vault: felt) -> (res: felt):
end

@storage_var
func isPublic(vault: felt) -> (res : felt):
end

@storage_var
func idToAllowedDepositor(vault: felt, id:felt) -> (res : felt):
end

@storage_var
func allowedDepositorLength(vault: felt) -> (res : felt):
end

@storage_var
func isAllowedDepositor(vault: felt, depositor:felt) -> (res : felt):
end




#
# Modifiers
#

func onlyVaultFactory{pedersen_ptr : HashBuiltin*, syscall_ptr : felt*, range_check_ptr}():
    let (vaultFactory_) = vaultFactory.read()
    let (caller_) = get_caller_address()
    with_attr error_message("onlyVaultFactory: only callable by the vaultFactory"):
        assert (vaultFactory_ - caller_) = 0
    end
    return ()
end

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        _vaultFactory: felt,
    ):
    vaultFactory.write(_vaultFactory)
    return ()
end




# Getters
@view
func getMaxminAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
        max: Uint256, min: Uint256):
    let (res) = maxminAmount.read(_vault)
    return (max=res.max, min=res.min)
end

@view
func getTimelock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
        res:felt):
    let (res) = timeLock.read(_vault)
    return (res=res)
end

@view
func checkIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt) -> (
        res:felt):
    let (res) = isPublic.read(_vault)
    return (res=res)
end


@view
func checkIsAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault: felt, _depositor: felt,
        ) -> (res: felt): 
    let (res) = isAllowedDepositor.read(_vault, _depositor)
    return (res=res)
end

@view
func getAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_vault:felt) -> (allowedDepositor_len: felt, allowedDepositor:felt*): 
    alloc_locals
    let (allowedDepositor_len:felt) = allowedDepositorLength.read(_vault)
    let (local allowedDepositor : felt*) = alloc()
    __completeAllowedDepositor(_vault, allowedDepositor_len, allowedDepositor, 0)
    return(allowedDepositor_len, allowedDepositor)
end

func __completeAllowedDepositor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_vault:felt, _allowedDepositor_len:felt, _allowedDepositor:felt*, index:felt) -> ():
    if _allowedDepositor_len == 0:
        return ()
    end
    let (depositor_:felt) = idToAllowedDepositor.read(_vault, index)
    assert [_allowedDepositor + index] = depositor_

    let new_index_:felt = index + 1
    let newAllowedDepositor_len:felt = _allowedDepositor_len -1

    return __completeAllowedDepositor(
        _vault = _vault,
        _allowedDepositor_len=newAllowedDepositor_len,
        _allowedDepositor= _allowedDepositor,
        index=new_index_,
    )
end



# Setters 
@external
func setMaxminAmount{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _max: Uint256, _min:Uint256):
    onlyVaultFactory()
    maxminAmount.write(_vault, MaxMin(_max, _min))
    return ()
end

@external
func setAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _depositor: felt):
    onlyVaultFactory()
    let (isAllowedDepositor_:felt) = isAllowedDepositor.read(_vault, _depositor)
    if isAllowedDepositor_ == 1:
    return()
    else:
    isAllowedDepositor.write(_vault, _depositor, 1)
    let (currentAllowedDepositorLength_:felt) = allowedDepositorLength.read(_vault)
    idToAllowedDepositor.write(_vault, currentAllowedDepositorLength_, _depositor)
    allowedDepositorLength.write(_vault, currentAllowedDepositorLength_ + 1)
    return ()
    end
end

@external
func setTimelock{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _block_timestamp: felt):
    onlyVaultFactory()
    timeLock.write(_vault, _block_timestamp)
    return ()
end

@external
func setIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _vault: felt, _isPublic: felt):
    onlyVaultFactory()
    isPublic.write(_vault, _isPublic)
    return ()
end


