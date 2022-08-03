%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

from starkware.cairo.common.uint256 import Uint256
from contracts.Fund import AssetInfo


@contract_interface
namespace IFuccount:

    # Setters
    func activater(
        _fundName: felt,
        _fundSymbol: felt,
        _uri: felt,
        _denominationAsset: felt,
        _managerAccount:felt,
        _shareAmount:Uint256,
        _sharePrice:Uint256,
        data_len:felt,
        data:felt*,
    ):
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

    func getNotNulPositions() -> (notNulPositions_len:felt, notNulPositition: felt*):
    end

    func getSharePrice() -> (price : Uint256):
    end

    func calculLiquidGav() -> (gav : Uint256):
    end

    func calculNotLiquidGav() -> (gav : Uint256):
    end

    func calculGav() -> (gav : Uint256):
    end

    # ERC1155 getters

    func getName() -> (res : felt):
    end

    func getSymbol() -> (res : felt):
    end

    func getTotalId() -> (res : Uint256):
    end

    func getSharesTotalSupply() -> (res : Uint256):
    end

    func getBalanceOf(account: felt, id: Uint256) -> (balance: Uint256):
    end

    func getBalanceOfBatch(
        accounts_len: felt,
        accounts: felt*,
        ids_len: felt,
        ids: Uint256*
    ) -> (balances_len: felt, balances: Uint256*):
    end

    func getIsApprovedForAll(account: felt, operator: felt) -> (isApproved: felt):
    end

    func ownerShares(account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    end

    func getSharePricePurchased(tokenId : Uint256) -> (res : Uint256):
    end

    func getMintedTimesTamp(tokenId : Uint256) -> (res : felt):
    end
end






    ## Business 

    func __execute__(
            call_array_len: felt,
            call_array: AccountCallArray*,
            calldata_len: felt,
            calldata: felt*,
            nonce: felt
        ) -> (response_len: felt, response: felt*):
    end
    



    