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

from starkware.cairo.common.uint256 import (
    Uint256,
    uint256_sub,
    uint256_check,
    uint256_le,
    uint256_eq,
    uint256_add,
    uint256_mul,
    uint256_unsigned_div_rem,
)

from starkware.cairo.common.cairo_builtins import HashBuiltin

from contracts.utils.utils import felt_to_uint256, uint256_div, uint256_percent, uint256_pow

from contracts.interfaces.IFuccount import IFuccount
from contracts.interfaces.IVaultFactory import IVaultFactory

from openzeppelin.security.safemath.library import SafeUint256
from starkware.cairo.common.math_cmp import is_le, is_not_zero



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
        let (VF_) = vault_factory.read()
        let (timestampRequest_:felt) = IVaultFactory.getCloseFundRequest(VF_, _fund)
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
func withdraw_to_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt, token_id : Uint256,amount_to_withdraw : Uint256) -> ():
    
    let (is_guarantee_withdrawable) = isGuaranteeWithdrawable()

    let (caller_addr) = get_caller_address()
    let (balance_user) = ERC1155_balances.read(fund,caller_addr,token_id)
    let (dispute_fund_balance_) = report_fund_balance.read(fund)
    let(contract_address) = get_contract_address()
    let (new_dispute_fund_balance) = SafeUint256.sub_le(dispute_fund_balance_, amount_to_withdraw)
    let (new_user_balancer) = SafeUint256.sub_le(balance_user, amount_to_withdraw)
    IFuccount.safeTransferFrom(contract_address,caller_addr,token_id,amount_to_withdraw)

    ERC1155_balances.write(fund,caller_addr,token_id, new_user_balancer)
    report_fund_balance.write(caller_addr, new_dispute_fund_balance)

     withdrawFromDisputeFund.emit(fund,caller_addr,token_id,amount_to_withdraw)
    return()
end

func asset_manager_deposit {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt, token_id : Uint256, amount:Uint256):
    let (asset_man) = IFuccount.getManagerAccount(fund)
    let (caller_addr) = get_caller_address()

    with_attr error_message("Only asset Manager can call this function"):
        assert asset_man = caller_addr
    end

    let (vault_status) = is_fund_disputed.read(fund)
    if vault_status == TRUE:
        return()
    end

    let (balance_user) = ERC1155_balances.read(fund,caller_addr,token_id)
    let (new_balancer_user) = SafeUint256.add(balance_user, amount)

    let (security_balance) = security_fund_balance.read(fund)
    let (new_security_balance) = SafeUint256.add(security_balance, amount)
    

    let(contract_address) = get_contract_address()

    IFuccount.safeTransferFrom(caller_addr,contract_address,token_id,amount)
    ERC1155_balances.write(fund,caller_addr,token_id,new_balancer_user)
    security_fund_balance.write(fund,caller_addr,new_balancer_user)

    depositToSecurityFund.emit(fund,caller_addr,token_id,amount)
    return()
end

@external
func withdraw_asset_manager_dispute_fund {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund : felt, token_id : felt,amount_to_withdraw : Uint256) -> ():
    
    let (asset_man) = IFuccount.getManagerAccount(fund)
    let(contract_address) = get_contract_address()
    let (caller_addr) = get_caller_address()
    with_attr error_message("Only asset Manager can call this function"):
        assert asset_man = caller_addr
    end

    let (balance_user) = ERC1155_balances.read(fund,caller_addr,token_id)
    let (new_balance_user) = SafeUint256.sub_le(balance_user, amount_to_withdraw)
    let (security_balance) = security_fund_balance.read()
    let (new_security_balance) = SafeUint256.sub_le(security_balance, amount_to_withdraw)

    
    IFuccount.safeTransferFrom(contract_address,caller_addr,token_id,amount_to_withdraw)

    ERC1155_balances.write(fund,caller_addr,token_id, new_balance_user)
    security_balance.write(caller_addr,new_security_balance)

    let (isGuaranteeWithdrawable_) = isGuaranteeWithdrawable(fund)
    if is_guarantee_withdrawable == 0:
        _assert_enought_guarantee(fund)
    end

    withdrawFromSecurityFund.emit(fund,caller_addr,token_id,amount_to_withdraw)
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
        let (assetId_len:felt, assetId:Uint256*, assetAmount_len:felt,assetAmount:Uint256*) = IFuccount.ownerShares(vault_address,contract_address)
        let (assetId_lenAM:felt, assetIdAM:Uint256*, assetAmountAM_len:felt,assetAmountAM:Uint256*) = ownerShares(vault_address,asset_manager)
        let (assetIdWAM_len, assetIdWAM, assetAmountWAM_len, assetAmountWAM) = get_all_shares_from_dispute_fund(assetId_len, assetId, assetAmount_len,assetAmount, assetAmount, assetIdAM, assetAmountAM_len,assetAmountAM,assetIdWAM_len, assetIdWAM, assetAmountWAM_len,assetAmountWAM)
        IFuccount.burnBatch(contract_address, assetIdWAM_len, assetIdWAM, assetIdWAM_len, assetAmountWAM)
        fundResultLegit.emit(vault_address)
        return ()

    end
    return()
end

#AM = Asset Manager
#WAM = Without Asset Manager
func get_all_shares_from_dispute_fund(assetIdAll_len:felt, assetIdAll:Uint256*, assetAmountAll_len:felt,assetAmountAll:Uint256*, assetIdAM_len:felt, assetIdAM:Uint256*, assetAmountAM_len:felt,assetAmountAM:Uint256*) -> (assetIdWAM_len:felt, assetIdWAM:Uint256*, assetAmountWAM_len:felt, assetAmountWAM:Uint256*):
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
    let (newTotalId_) =  SafeUint256.sub_le( totalId, Uint256(1,0))
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


func _assert_enought_guarantee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(fund: felt):
    alloc_locals
   let (shareSupply_) = IFuccount.get_shares_total_supply(fund)
   let (vault_factory_) = vault_factory.read()
   let (securityFundBalance_)  = getSecurityFundBalance(fund)
   let (guaranteeRatio_) = IVaultFactory.getGuaranteeRatio(vault_factory_)
   let (minGuarantee_) =  uint256_percent(shareSupply_, Uint256(guaranteeRatio_,0))
   let (isEnoughtGuarantee_) = uint256_le(minGuarantee_, securityFundBalance_)
   with_attr error_message("_assert_enought_guarantee: Asser manager need to provide more guarantee "):
        assert_not_zero(isEnoughtGuarantee_)
    end
   return()
end

