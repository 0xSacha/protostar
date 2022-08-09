# Declare this file as a StarkNet contract.
%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.alloc import (
    alloc,
)


from contracts.interfaces.IIntegrationManager import IIntegrationManager

struct integration:
    member contract : felt
    member selector : felt
end

@storage_var
func vaultFactory() -> (res: felt):
end


## External Position

@storage_var
func externalPositionAvailableLength() -> (res: felt):
end

@storage_var
func idToExternalPositionAvailable(id: felt) -> (res: felt):
end

@storage_var
func isExternalPositionAvailable(externalPositionAddress: felt) -> (res: felt):
end

## Integration

@storage_var
func integrationAvailableLength() -> (res: felt):
end

@storage_var
func idToIntegrationAvailable(id: felt) -> (res: integration):
end

@storage_var
func isIntegrationAvailable(_integration: integration) -> (res: felt):
end

@storage_var
func integrationContract(_integration: integration) -> (res: felt):
end

@storage_var
func integrationRequiredLevel(_integration: integration) -> (res: felt):
end


@storage_var
func isContractIntergrated(_contract: felt) -> (res: felt):
end



## Asset

@storage_var
func assetAvailableLength() -> (res: felt):
end

@storage_var
func idToAssetAvailable(id: felt) -> (res: felt):
end

@storage_var
func isAssetAvailable(assetAddress: felt) -> (res: felt):
end


## Shares

@storage_var
func shareAvailableLength() -> (res: felt):
end

@storage_var
func idToShareAvailable(id: felt) -> (res: felt):
end

@storage_var
func isShareAvailable(assetAddress: felt) -> (res: felt):
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

#
# Getters
#

@view
func checkIsShareAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_asset: felt) -> (res: felt): 
    let (res) = isAssetAvailable.read(_asset)
    return (res=res)
end

@view
func checkIsAssetAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_asset: felt) -> (res: felt): 
    let (res) = isAssetAvailable.read(_asset)
    return (res=res)
end

@view
func checkIsExternalPositionAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_externalPosition: felt) -> (res: felt): 
    let (res) = isExternalPositionAvailable.read(_externalPosition)
    return (res=res)
end

@view
func checkIsIntegrationAvailable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector:felt) -> (res: felt): 
    let (res) = isIntegrationAvailable.read(integration(_contract, _selector))
    return (res=res)
end

@view
func getIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector:felt) -> (res: felt): 
    let (res) = integrationContract.read(integration(_contract, _selector))
    return (res=res)
end

@view
func getIntegrationRequiredLevel{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt, _selector:felt) -> (res: felt): 
    let (res) = integrationRequiredLevel.read(integration(_contract, _selector))
    return (res=res)
end

@view
func checkIsContractIntegrated{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(_contract: felt) -> (res: felt): 
    let (res) = isContractIntergrated.read(_contract)
    return (res=res)
end



@view
func getAvailableAssets{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableAssets_len: felt, availableAssets:felt*): 
    alloc_locals
    let (availableAssets_len:felt) = assetAvailableLength.read()
    let (local availableAssets : felt*) = alloc()
    __completeAssetTab(availableAssets_len, availableAssets, 0)
    return(availableAssets_len, availableAssets)
end

func __completeAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_availableAssets_len:felt, _availableAssets:felt*, index:felt) -> ():
    if _availableAssets_len == 0:
        return ()
    end
    let (asset_:felt) = idToAssetAvailable.read(index)
    assert [_availableAssets + index] = asset_

    let new_index_:felt = index + 1
    let newAvailableAssets_len:felt = _availableAssets_len -1

    return __completeAssetTab(
        _availableAssets_len=newAvailableAssets_len,
        _availableAssets= _availableAssets,
        index=new_index_,
    )
end

@view
func getAvailableExternalPositions{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableExternalPositions_len: felt, availableExternalPositions:felt*): 
    alloc_locals
    let (availableExternalPositions_len:felt) = externalPositionAvailableLength.read()
    let (local availableExternalPositions : felt*) = alloc()
    __completeExternalPositionTab(availableExternalPositions_len, availableExternalPositions, 0)
    return(availableExternalPositions_len, availableExternalPositions)
end

func __completeExternalPositionTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_availableExternalPositions_len:felt, _availableExternalPositions:felt*, index:felt) -> ():
    if _availableExternalPositions_len == 0:
        return ()
    end
    let (externalPosition_:felt) = idToExternalPositionAvailable.read(index)
    assert [_availableExternalPositions + index] = externalPosition_

    let new_index_:felt = index + 1
    let newAvailableExternalPositions_len:felt = _availableExternalPositions_len -1

    return __completeExternalPositionTab(
        _availableExternalPositions_len=newAvailableExternalPositions_len,
        _availableExternalPositions= _availableExternalPositions,
        index=new_index_,
    )
end

@view
func getAvailableIntegrations{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableIntegrations_len:felt, availableIntegrations: integration*): 
    alloc_locals
    let (availableIntegrations_len:felt) = integrationAvailableLength.read()
    let (local availableIntegrations : integration*) = alloc()
    __completeIntegrationTab(availableIntegrations_len, availableIntegrations, 0)
    return(availableIntegrations_len, availableIntegrations)
end

func __completeIntegrationTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_availableIntegrations_len:felt, _availableIntegrations:integration*, index:felt) -> ():
    if _availableIntegrations_len == 0:
        return ()
    end

    let (integration_:integration) = idToIntegrationAvailable.read(index)
    assert [_availableIntegrations + index*2] = integration_

    let new_index_:felt = index + 1
    let newAvailableIntegrations_len:felt = _availableIntegrations_len -1

    return __completeIntegrationTab(
        _availableIntegrations_len=newAvailableIntegrations_len,
        _availableIntegrations= _availableIntegrations,
        index=new_index_,
    )
end


@view
func getAvailableShares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (availableShares_len: felt, availableShares:felt*): 
    alloc_locals
    let (availableShares_len:felt) = shareAvailableLength.read()
    let (local availableShares : felt*) = alloc()
    __completeShareTab(availableShares_len, availableShares)
    return(availableShares_len, availableShares)
end

func __completeShareTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(_availableShares_len:felt, _availableShares:felt*) -> ():
    if _availableShares_len == 0:
        return ()
    end
    let (share_:felt) = idToShareAvailable.read(_availableShares_len - 1)
    assert _availableShares[_availableShares_len] = share_

    return __completeShareTab(
        _availableShares_len=_availableShares_len - 1,
        _availableShares= _availableShares,
    )
end

#
# Setters
#

@external
func setAvailableAsset{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _asset: felt):
    onlyVaultFactory()
    let (isAssetAvailable_:felt) = isAssetAvailable.read(_asset)
    if isAssetAvailable_ == 1:
    return()
    else:
    isAssetAvailable.write(_asset, 1)
    let (currentAssetAvailableLength_:felt) = assetAvailableLength.read()
    idToAssetAvailable.write(currentAssetAvailableLength_, _asset)
    assetAvailableLength.write(currentAssetAvailableLength_ + 1)
    return ()
    end
end

@external
func setAvailableShare{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _share: felt):
    onlyVaultFactory()
    let (isShareAvailable_:felt) = isShareAvailable.read(_share)
    if isShareAvailable_ == 1:
    return()
    else:
    isShareAvailable.write(_share, 1)
    let (currentShareAvailableLength_:felt) = shareAvailableLength.read()
    idToShareAvailable.write(currentShareAvailableLength_, _share)
    shareAvailableLength.write(currentShareAvailableLength_ + 1)
    return ()
    end
end

@external
func setAvailableExternalPosition{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _externalPosition: felt):
    onlyVaultFactory()
    let (isExternalPositionAvailable_:felt) = isExternalPositionAvailable.read(_externalPosition)
    if isExternalPositionAvailable_ == 1:
    return()
    else:
    isExternalPositionAvailable.write(_externalPosition, 1)
    let (currentExternalPositionAvailableLength_:felt) = externalPositionAvailableLength.read()
    idToExternalPositionAvailable.write(currentExternalPositionAvailableLength_, _externalPosition)
    externalPositionAvailableLength.write(currentExternalPositionAvailableLength_ + 1)
    return ()
    end
end

@external
func setAvailableIntegration{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _contract: felt, _selector: felt, _integration: felt, _level: felt):
    onlyVaultFactory()
    let (isIntegrationAvailable_:felt) = isIntegrationAvailable.read(integration(_contract, _selector))
    if isIntegrationAvailable_ == 1:
    return()
    else:
    isContractIntergrated.write(_contract, 1)
    isIntegrationAvailable.write(integration(_contract, _selector), 1)
    integrationContract.write(integration(_contract, _selector), _integration)
    let (currentIntegrationAvailableLength_:felt) = integrationAvailableLength.read()
    idToIntegrationAvailable.write(currentIntegrationAvailableLength_, integration(_contract, _selector))
    integrationAvailableLength.write(currentIntegrationAvailableLength_ + 1)
    integrationRequiredLevel.write(integration(_contract, _selector), _level)
    return ()
    end
end
