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
func isPublic(vault: felt) -> (res : felt):
end

@storage_var
func idToAllowedDepositor(vault: felt, id:felt) -> (res : felt):
end

@storage_var
func allowedDepositorToId(vault: felt, depositor:felt) -> (res : felt):
end

@storage_var
func allowedDepositorLength(vault: felt) -> (res : felt):
end

@storage_var
func isAllowedDepositor(vault: felt, depositor:felt) -> (res : felt):
end



@storage_var
func idToAllowedAssetToReedem(vault: felt, id:felt) -> (res : felt):
end

@storage_var
func allowedAssetToReedemLength(vault: felt) -> (res : felt):
end

@storage_var
func isAllowedAssetToReedem(vault: felt, depositor:felt) -> (res : felt):
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


@view
func checkIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt) -> (
        res:felt):
    let (res) = isPublic.read(_fund)
    return (res=res)
end


@view
func checkIsAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt, _depositor: felt,
        ) -> (res: felt): 
    let (res) = isAllowedDepositor.read(_fund, _depositor)
    return (res=res)
end

@view
func checkIsAllowedAssetToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund: felt, _asset: felt,
        ) -> (res: felt): 
    let (res) = isAllowedAssetToReedem.read(_fund, _asset)
    return (res=res)
end

@view
func getAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund:felt) -> (allowedDepositor_len: felt, allowedDepositor:felt*): 
    alloc_locals
    let (allowedDepositor_len:felt) = allowedDepositorLength.read(_fund)
    let (local allowedDepositor : felt*) = alloc()
    _completeAllowedDepositor(_fund, allowedDepositor_len, allowedDepositor, 0)
    return(allowedDepositor_len, allowedDepositor)
end

func _completeAllowedDepositor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_fund:felt, _allowedDepositor_len:felt, _allowedDepositor:felt*, index:felt) -> ():
    if _allowedDepositor_len == 0:
        return ()
    end
    let (depositor_:felt) = idToAllowedDepositor.read(_fund, index)
    assert [_allowedDepositor + index] = depositor_

    let new_index_:felt = index + 1
    let newAllowedDepositor_len:felt = _allowedDepositor_len -1

    return _completeAllowedDepositor(
        _fund = _fund,
        _allowedDepositor_len=newAllowedDepositor_len,
        _allowedDepositor= _allowedDepositor,
        index=new_index_,
    )
end

@view
func getAllowedAssetToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_fund:felt) -> (allowedAssetToReedem_len: felt, allowedAssetToReedem:felt*): 
    alloc_locals
    let (allowedAssetToReedem_len:felt) = allowedAssetToReedemLength.read(_fund)
    let (local allowedAssetToReedem : felt*) = alloc()
    _completeAllowedAssetToReedem(_fund, allowedAssetToReedem_len, allowedAssetToReedem, 0)
    return(allowedAssetToReedem_len, allowedAssetToReedem)
end

func _completeAllowedAssetToReedem{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_fund:felt, _allowedAssetToReedem_len:felt, _allowedAssetToReedem:felt*, index:felt) -> ():
    if _allowedAssetToReedem_len == 0:
        return ()
    end
    let (asset_:felt) = idToAllowedAssetToReedem.read(_fund, index)
    assert [_allowedDepositor + index] = depositor_
    let new_index_:felt = index + 1
    let newAllowedDepositor_len:felt = _allowedDepositor_len -1

    return __completeAllowedDepositor(
        _fund = _fund,
        _allowedDepositor_len=newAllowedDepositor_len,
        _allowedDepositor= _allowedDepositor,
        index=new_index_,
    )
end



# Setters 

@external
func setAllowedDepositor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _fund: felt, _depositor: felt):
    onlyVaultFactory()
    let (isAllowedDepositor_:felt) = isAllowedDepositor.read(_fund, _depositor)
    if isAllowedDepositor_ == 1:
    return()
    else:
    isAllowedDepositor.write(_fund, _depositor, 1)
    let (currentAllowedDepositorLength_:felt) = allowedDepositorLength.read(_fund)
    idToAllowedDepositor.write(_fund, currentAllowedDepositorLength_, _depositor)
    allowedDepositorToId.write(_fund, _depositor, currentAllowedDepositorLength_)
    allowedDepositorLength.write(_fund, currentAllowedDepositorLength_ + 1)
    return ()
    end
end

@external
func setAllowedAssetToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _fund: felt, _asset_len: felt, _asset: felt*):
    onlyVaultFactory()
    allowedAssetToReedemLength.write(_fund, _asset_len)
    _setAllowedAssetToReedem(_fund, _asset_len, _asset)
    let (denominationAsset_:felt) = IFuccount.getDenominationAsset(_fund)
    let (isDenominationAssetAllowedToReedem:felt) = isAllowedAssetToReedem(_fund, denominationAsset_)
    with_attr error_message("setAllowedAssetToReedem: must contain the fund's denomination asset"):
        assert isDenominationAssetAllowedToReedem = 1
    end 
    return ()
    end
end




@external
func setIsPublic{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _fund: felt, _isPublic: felt):
    onlyVaultFactory()
    isPublic.write(_fund, _isPublic)
    return ()
end



func _setAllowedAssetToReedem{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _fund: felt, _asset_len: felt, _asset: felt*):
    if _asset_len == 0:
    return()
    end
    isAllowedAssetToReedem.write(_fund, _asset[_asset_len - 1], 1)
    idToAllowedAssetToReedem.write(_fund, _asset_len - 1, _asset[_asset_len - 1])
    return _setAllowedAssetToReedem(_fund, _asset_len - 1, _asset)
end