%lang starknet

from contracts.ERC1155Shares import ERC1155Shares

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.bool import TRUE, FALSE
from starkware.starknet.common.syscalls import (
    get_caller_address,
    get_contract_address,
    get_block_timestamp,
    get_block_number
)

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow

from contracts.interfaces.IFuccount import IFuccount


from openzeppelin.security.safemath.library import SafeUint256
#
# Events
#


@event
func fundFroze(vault_address: felt):
end

@event
func depositToDisputeFund(
    vault_address : felt,
    caller_address : felt,
    token_id : felt,
    amount_to_deposit: Uint256
    ):
end

@event
func withdrawFromDisputeFund(
    vault_address : felt,
    caller_address : felt,
    token_id : felt,
    amount_to_deposit: Uint256
    ):
end

@event
func depositToSecurityFund(
    vault_address : felt,
    caller_address : felt,
    token_id : felt,
    amount_to_deposit: Uint256
    ):
end

@event
func withdrawFromSecurityFund(
    vault_address : felt,
    caller_address : felt,
    token_id : felt,
    amount_to_deposit: Uint256
    ):
end

@event
func fundResultBan (vault_address : felt):
end

@event
func fundResultLegit (vault_address : felt):
end


@storage_var
func is_fund_disputed(vault : felt) -> (bool : felt):
end


#
# Storage Var
#

@storage_var
func vault_factory() -> (res : felt):
end

@storage_var
func ERC1155_balances (vault_address : felt, user_address : felt, token_id: Uint256) -> (balance : Uint256):
end

@storage_var
func report_fund_balance(vault_address : felt) -> (balance : Uint256):
end

@storage_var
func security_fund_balance(vault_address : felt) -> (balance : Uint256):
end


#
# Constructor
#


@constructor
func constructor{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(_vault_factory: felt):
    # Owner address must be the DAO contract
    vault_factory.write(_vault_factory)
    return ()
end


#
# View
#
@view
func balanceOf{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(account: felt, id: Uint256, vault_address : felt) -> (balance: Uint256):
    let (balances) = ERC1155_balances.read(vault_address,account,id)
    return (balances)
end

@view
func isGuaranteeWithdrawable{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        _fund: felt)-> (isGuaranteeWithdrawable_:felt):
        let (timestampRequest_:felt) = IVaultFactory.getCloseFundRequest.read(_fund)
        if timestampRequest == 0:
            return(0)
        end
        let (currentTimesTamp_) = get_block_timestamp()
        let (vaultFactory_) = vault_factory.read()
        let (exitTimestamp_:felt) = IVaultFactory.getExitTimestamp()
        if is_le(currentTimesTamp_ , exitTimestamp_ + timestampRequest_) == 1:
            return(0)
        else:
            return (1)
        end
end


#
# External
#


@external
func deposit_to_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address : felt,token_id : felt, amount_to_deposit: Uint256) -> ():
    
    let (caller_addr) = get_caller_address()
    let (vault_status) = is_fund_disputed.read(vault_address)
    if vault_status == TRUE:
        return()
    end
    let (balance_user) = ERC1155_balances.read(vault_address,caller_addr,token_id)
    let (balance_report) = report_fund_balance.read(vault_address)
    let(contract_address) = get_contract_address()
    IFuccount.safeTransferFrom(caller_addr,contract_address,token_id,amount_to_deposit,0,0)
    ### Balance user is UINT256, to change everywhere
    ERC1155_balances.write(vault_address,caller_addr,token_id,amount_to_deposit + balance_user)
    depositToDisputeFund.emit(vault_address,caller_addr,token_id,amount_to_deposit)
    report_fund_balance.write(vault_address, balance_report + amount_to_deposit)

    let (balance_complains_user) = report_fund_balance.read(vault_address)
    let (percent) = uint256_percent(IFuccount.sharesTotalSupply(),balance_complains_user) 
    if is_le(5,percent) == 1:
        is_fund_disputed.write(vault_address,1)
        fundFroze.emit(vault_address)
    end
    return()
end

@external
func withdraw_to_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address : felt, token_id : felt,amount_to_withdraw : Uint256) -> ():
    let (caller_addr) = get_caller_address()
    let (vault_status) = is_fund_disputed.read(vault_address)
    if vault_status == TRUE:
        return()
    end

    let (balance_user) = ERC1155_balances.read(vault_address,caller_addr,token_id)
    let (dispute_fund) = report_fund.read(vault_address)
    let(contract_address) = get_contract_address()
    IFuccount.safeTransferFrom(contract_address,caller_addr,token_id,amount_to_withdraw,0,0)
    ERC1155_balances.write(vault_address,caller_addr,token_id, balance_user - amount_to_withdraw)
    withdrawFromDisputeFund.emit(vault_address,caller_addr,token_id,amount_to_deposit)
    report_fund_balance.write(caller_addr,token_id, dispute_fund - amount_to_withdraw)
    return()
end

func asset_manager_deposit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address : felt, token_id : Uint256, amount:Uint256):
    let (asset_man) = IFuccount.getManagerAccount(vault_address)
    let (caller_addr) = get_caller_address()
    with_attr error_message("Only asset Manager can call this function"):
        assert asset_man = caller_addr
    end
    let (vault_status) = is_fund_disputed.read(vault_address)
    if vault_status == TRUE:
        return()
    end
    let (balance_user) = ERC1155_balances.read(vault_address,caller_addr,token_id)
    let (security_balance) = security_fund_balance.read(vault_address)
    let(contract_address) = get_contract_address()
    IFuccount.safeTransferFrom(caller_addr,contract_address,token_id,amount_to_deposit,0,0)
    ERC1155_balances.write(vault_address,caller_addr,token_id,amount_to_deposit + balance_user)
    depositToSecurityFund.emit(vault_address,caller_addr,token_id,amount_to_deposit)
    security_fund_balance.write(vault_address, security_balance + amount_to_deposit)
    return()
end

@external
func withdraw_asset_manager_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(vault_address : felt, token_id : felt,amount_to_withdraw : Uint256) -> ():
    let (asset_man) = IFuccount.getManagerAccount(vault_address)
    let (caller_addr) = get_caller_address()
    with_attr error_message("Only asset Manager can call this function"):
        assert asset_man = caller_addr
    end
    let (balance_user) = ERC1155_balances.read(vault_address,caller_addr,token_id)
    let(contract_address) = get_contract_address()
    let (isGuaranteeWithdrawable_) = isGuaranteeWithdrawable(vault_address)
    if isGuaranteeWithdrawable_ == 0:
        let (vault_factory_) = vault_factory.read()
        ## uint256 - uin256 Not Possible  
        let theorical_balance = balance_user - amount_to_withdraw
        let (sharesTotalSupply_) = IFuccount.sharesTotalSupply()
        ## uint256_percent(IFuccount.sharesTotalSupply(),theorical_balance) forbidden
        ##Percent suckkk, not precise enought 
        let (percent) = uint256_percent(sharesTotalSupply_,theorical_balance) 
        let (guaranteeRatio) = IVaultFactory.getManagerGuaanteeRatio(vault_factory_, caller_addr)
        with_attr error_message("You can't withdraw more than the guarantee ratio in this fund"):
        assert is_le(guaranteeRatio,percent) = 1
        end
    end
    
    IFuccount.safeTransferFrom(contract_address,caller_addr,token_id,amount_to_withdraw,0,0)
    ERC1155_balances.write(vault_address,caller_addr,token_id, balance_user - amount_to_withdraw)
    withdrawFromSecurityFund.emit(vault_address,caller_addr,token_id,amount_to_deposit)
    security_balance.write(caller_addr,token_id, balance_user - amount_to_withdraw)
    return()
end

func resultDispute {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(bool : felt, vault_address : felt):
    let (dispute_fund) = is_fund_disputed(vault_address)
    let (contract_address) = get_contract_address()
    with_attr error_message("Fund is not in dispute"):
       assert dispute_fund = TRUE
    end
    if bool == TRUE:
        let (asset_manager) = IFuccount.getManagerAccount(vault_address)
        let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = ownerShares(vault_address,asset_manager)
        IFuccount.burnBatch(contract_address, assetId_len, assetId, assetAmount_len, assetAmount)
        fundResultBan.emit(vault_address)
        return ()
    else:
        let (asset_manager) = IFuccount.getManagerAccount(vault_address)
        let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = ownerShares(vault_address,contract_address)
        let (assetId_lenAM:felt, assetIdAM:Uint256*, assetAmountAM_len:felt,assetAmountAM:Uint256*) = ownerShares(vault_address,asset_manager)
        let (assetIdWAM_len, assetIdWAM, assetAmountWAM_len, assetAmountWAM) = get_all_shares_from_dispute_fund(assetIdAll_len, assetIdAll, assetAmountAll_len,assetAmountAll, assetIdAM_len, assetIdAM, assetAmountAM_len,assetAmountAM,assetIdWAM_len, assetIdWAM, assetAmountWAM_len,assetAmountWAM)
        IFuccount.burnBatch(contract_address, assetIdWAM_len, assetIdWAM, assetIdWAM_len, assetAmountWAM)
        fundResultLegit.emit(vault_address)
        return ()

    end
    return()
end

#AM = Asset Manager
#WAM = Without Asset Manager
func get_all_shares_from_dispute_fund(assetIdAll_len:felt, assetIdAll:Uint256*, assetAmountAll_len:felt,assetAmountAll:Uint256*, assetIdAM_len:felt, assetIdAM:Uint256*, assetAmountAM_len:felt,assetAmountAM:Uint256*,assetIdWAM_len:felt, assetIdWAM:Uint256*, assetAmountWAM_len:felt,assetAmountWAM:Uint256*) -> (assetIdWAM_len : felt, assetAmountWAM : Uint256*, assetAmountWAM_len : felt, assetAmountWAM : Uint256*):
    alloc_locals
    if assetIdAll_len == 0:
        return (assetIdWAM,assetIdWAM_len)
    end
    if assetIdAM_len == 0:
        assert [assetIdWAM] = [assetIdAll]
        assert [assetAmountAM] = [assetAmountAll]
        return get_all_shares_from_dispute_fund(assetIdAll_len = assetIdAll_len - 1, assetIdAll = assetIdAll + assetIdAll.SIZE, assetAmountAll_len = assetAmountAll_len - 1, assetAmountAll = assetAmountAll + assetAmountAll.SIZE, assetIdAM_len, assetIdAM, assetAmountAM_len,assetAmountAM,assetIdWAM_len = assetIdWAM_len + 1 , assetIdWAM = assetIdWAM + assetIdWAM.SIZE, assetAmountWAM_len = assetAmountWAM_len + 1,assetAmountWAM = assetAmountWAM + assetAmountWAM.SIZE, vault_address)
    end
    let current_id = [assetIdAll]
    let current_ammount = [assetAmountAll]
    let current_idAM = [assetIdAM]
    let current_ammountAM = [assetAmountAM]
    if current_idAM == current_id:
        if current_ammountAM == current_ammount:
            return get_all_shares_from_dispute_fund(assetIdAll_len = assetIdAll_len - 1, assetIdAll = assetIdAll + assetIdAll.SIZE, assetAmountAll_len = assetAmountAll_len - 1, assetAmountAll = assetAmountAll + assetAmountAll.SIZE, assetIdAM_len, assetIdAM, assetAmountAM_len,assetAmountAM,assetIdWAM_len = assetIdWAM_len  , assetIdWAM = assetIdWAM, assetAmountWAM_len = assetAmountWAM_len,assetAmountWAM = assetAmountWAM , vault_address)
        end
    end
    return get_all_shares_from_dispute_fund(assetIdAll_len = assetIdAll_len , assetIdAll = assetIdAll , assetAmountAll_len = assetAmountAll_len , assetAmountAll = assetAmountAll , assetIdAM_len = assetIdAM_len - 1, assetIdAM = assetIdAM + assetIdAM.SIZE, assetAmountAM_len = assetAmountAll_len - 1,assetAmountAM = assetAmountAM + assetAmountAM.SIZE ,assetIdWAM_len = assetIdWAM_len , assetIdWAM = assetIdWAM , assetAmountWAM_len = assetAmountWAM_len ,assetAmountWAM = assetAmountWAM , vault_address)
end

func ownerShares{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }( vault_address : felt, account: felt) -> (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*):
    alloc_locals
    let (totalId_:Uint256) = IFuccount.totalId(vault_address)
    let (local assetId : Uint256*) = alloc()
    let (local assetAmount : Uint256*) = alloc()
    let (tabSize_:felt) = completeMultiAssetTab(totalId_, 0, assetId, 0, assetAmount, account,vault_address)    
    return (tabSize_, assetId, tabSize_, assetAmount)
end

func completeMultiAssetTab{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(totalId:Uint256, assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*, account:felt, vault_address : felt) -> (tabSize:felt):
    alloc_locals
    if totalId.low == 0:
        return (tabSize=assetId_len)
    end
    let (newTotalId_) =  uint256_sub( totalId, Uint256(1,0))
    let (balance_) = ERC1155_balances.read(vault_address,account, newTotalId_)
    let (isZero_) = __is_zero(balance_.low)
    if isZero_ == 0:
        # assert assetId[assetId_len*Uint256.SIZE] = newTotalId_
        # assert assetAmount[assetId_len*Uint256.SIZE] = balance_
        assert assetId[assetId_len] = newTotalId_
        assert assetAmount[assetId_len] = balance_
         return completeMultiAssetTab(
        totalId= newTotalId_,
        assetId_len=assetId_len+1,
        assetId= assetId ,
        assetAmount_len=assetAmount_len+1,
        assetAmount=assetAmount ,
        account=account,
        vault_address=vault_address
        )
    end
    return completeMultiAssetTab(
        totalId=newTotalId_,
        assetId_len= assetId_len,
        assetId=assetId,
        assetAmount_len=assetAmount_len,
        assetAmount=assetAmount,
        account=account,
        vault_address=vault_address
        )
end

func __sumTab{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    _percents_len : felt, _percents : felt*) -> (res:felt):
    alloc_locals
    if _percents_len == 0:
        return (0)
    end
    let newPercents_len:felt = _percents_len - 1
    let newPercents:felt* = _percents + 1
    let (_previousElem:felt) = __calculTab100(newPercents_len, newPercents)
    let res:felt = [_percents] + _previousElem
    return (res=res)
end
