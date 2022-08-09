%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import Uint256

struct VaultAction:
    member BurnShares: felt
    member MintShares: felt
    member AddTrackedAsset: felt
    member RemoveTrackedAsset: felt
    member TransferShares: felt
    member WithdrawAssetTo: felt
    member ExecuteCall: felt
    member AddTrackedExternalPosition: felt
    member RemoveTrackedExternalPosition: felt
end

@contract_interface
namespace IVault:
    # Vault actionn only call this with the right vaultAction to perform

    func receiveValidatedVaultAction(_action : felt, _actionData_len : felt, _actionData : felt*):
    end

    # set comptroller only callable by fund deployer 
    func initializer(_fundName : felt, _fundSymbol : felt, _assetManager : felt, _denominationAsset : felt, _positionLimitAmount: Uint256):
    end   

    # Vault getters

    func getAssetManager() -> (res : felt):
    end

    func getDenominationAsset() -> (res : felt):
    end

    func checkIsActivated() -> (res : felt):
    end

    func isTrackedAsset(_asset : felt) -> (isTrackedAsset_ : felt):
    end

    func getTrackedAssets() -> (trackedAssets__len : felt, trackedAssets_ : felt*):
    end

    func isTrackedExternalPosition(_externalPosition : felt) -> (isTrackedExternalPosition_ : felt):
    end

    func getTrackedExternalPositions() -> (trackedExternalPositions__len : felt, trackedExternalPositions_ : felt*):
    end

    func getPositionsLimit() -> (positionLimit_ : Uint256):
    end

    func getAssetBalance(_asset : felt) -> (assetBalance_ : Uint256):
    end

    func getcomptroller() -> (comptrollerAd : felt):
    end

    # NFT getters

    func getName() -> (name : felt):
    end

    func getSymbol() -> (symbol : felt):
    end

    func getTotalSupply() -> (totalSupply : Uint256):
    end

    func getSharesTotalSupply() -> (sharesTotalSupply : Uint256):
    end

    func getSharesBalance(token_id : Uint256) -> (sharesBalance : Uint256):
    end

    func getBalanceOf(owner : felt) -> (balance : Uint256):
    end

    func getOwnerOf(tokenId : Uint256) -> (owner : felt):
    end

    func getSharePricePurchased(tokenId : Uint256) -> (sharePricePurchased : Uint256):
    end

    func getMintedBlockTimesTamp(tokenId : Uint256) -> (mintedBlock : felt):
    end
end
