%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import Uint256
from contracts.Account_Lib import AccountCallArray

struct AssetInfo:
    member address : felt
    member amount : Uint256
    member valueInDeno : Uint256
end

struct ShareWithdraw:
    member address : felt
    member id : Uint256
end

@contract_interface
namespace IFuccount:

    # Setters
    func activater(
        _fundName: felt,
        _fundSymbol: felt,
        _fundLevel: felt,
        _denominationAsset: felt,
        _managerAccount:felt,
        _shareAmount:Uint256,
        _sharePrice:Uint256,
    ):
    end    

    func close():
    end  

    func set_public_key(new_public_key: felt):
    end  

    

    # Account getters

    func get_public_key() -> (res: felt):
    end

    func get_nonce() -> (res: felt):
    end

    func is_valid_signature(
        hash: felt,
        signature_len: felt,
        signature: felt*
    ) -> (is_valid: felt):
    end

    func supportsInterface(interfaceId: felt) -> (success: felt):
    end

    # Fund getters

    func getManagerAccount() -> (res : felt):
    end

    func getDenominationAsset() -> (res : felt):
    end

    func getAssetBalance(_asset: felt) -> (res: Uint256):
    end

    func getNotNulAssets() -> (notNulAssets_len:felt, notNulAssets: AssetInfo*):
    end

    func getNotNulPositions() -> (notNulPositions_len:felt, notNulPositions: felt*):
    end

    func getSharePrice() -> (price : Uint256):
    end

    func calculLiquidGav() -> (gav : Uint256):
    end

    func calculNotLiquidGav() -> (gav : Uint256):
    end

    func calculGav() -> (gav : Uint256):
    end

    func previewReedem(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    shares_len : felt,
    shares : ShareWithdraw*,
) -> (assetCallerAmount_len: felt,assetCallerAmount:Uint256*, assetManagerAmount_len: felt,assetManagerAmount:Uint256*,assetStackingVaultAmount_len: felt, assetStackingVaultAmount:Uint256*, assetDaoTreasuryAmount_len: felt,assetDaoTreasuryAmount:Uint256*, shareCallerAmount_len: felt, shareCallerAmount:Uint256*, shareManagerAmount_len: felt, shareManagerAmount:Uint256*, shareStackingVaultAmount_len: felt, shareStackingVaultAmount:Uint256*, shareDaoTreasuryAmount_len: felt, shareDaoTreasuryAmount:Uint256*):
    end

    func previewDeposit(_amount: Uint256) -> (shareAmount: Uint256, fundAmount: Uint256, managerAmount: Uint256, treasuryAmount: Uint256, stackingVaultAmount: Uint256):
    end

    # ERC1155-like getters

    func getName() -> (res : felt):
    end

    func getSymbol() -> (res : felt):
    end


    func totalId() -> (res : Uint256):
    end

    func sharesTotalSupply() -> (res : Uint256):
    end

    func balanceOf(account: felt, id: Uint256) -> (balance: Uint256):
    end

    func balanceOfBatch(
        accounts_len: felt,
        accounts: felt*,
        ids_len: felt,
        ids: Uint256*
    ) -> (balances_len: felt, balances: Uint256*):
    end

    func isApprovedForAll(account: felt, operator: felt) -> (isApproved: felt):
    end

    func ownerShares(account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    end

    func getSharePricePurchased(tokenId : Uint256) -> (res : Uint256):
    end

    func getMintedTimesTamp(tokenId : Uint256) -> (res : felt):
    end

    ## Business 

    #Account

    func __execute__(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
    end


    #Fund

    func deposit(_amount: Uint256):
    end 

    func reedem(
    id : Uint256,
    amount : Uint256,
    assets_len : felt,
    assets : felt*,
    shares_len : felt,
    shares : ShareWithdraw*,
    ):
    end 

    #Shares

    func setApprovalForAll(operator: felt, approved: felt):
    end  

    func safeTransferFrom(
        from_: felt,
        to: felt,
        id: Uint256,
        amount: Uint256,
    ):
    end  

    func safeBatchTransferFrom(
        from_: felt,
        to: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*,
    ):
    end  

    func burn(from_: felt, id: Uint256, amount: Uint256):
    end  

    func burnBatch(
        from_: felt,
        ids_len: felt,
        ids: Uint256*,
        amounts_len: felt,
        amounts: Uint256*
    ):
    end  

end
