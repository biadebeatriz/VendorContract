// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./MentoraWellPlayedToken.sol";

//TODO: TRIGGER PRICE P.O.

// Learn more about the ERC20 implementation 
// on OpenZeppelin docs: https://docs.openzeppelin.com/contracts/4.x/api/access#Ownable
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./Price.sol";

contract Vendor is Ownable, PriceConsumerMaticDollar, ReentrancyGuard, AccessControl{

//EVENTOS

//CONTRATO DO TOKEN
    MentoraWellPlayedToken MWPToken;

// PRICE PERBACTH
    int256  public PriceBatch1 = 80*10**15;
    int256  public PriceBatch2 = 90*10**15;
    int256  public PriceBatch3 = 95*10**15;
    int256  public PricePO =100*10**15;
//TOTAL SOLD

    uint256 public totalSold;

//int de index das orders
    uint index;

//TOTAL SOLD PER BACTH
    uint256 public totalSoldWL;
    uint256 public totalSoldBatch2;
    uint256 public totalSoldBatch3;
    uint256 public totalSoldPO;
//Supply per Batch
    uint256 public maxSupplyWL = 2090000*10**18;
    uint256 public maxSupplyBatch2 = 4180000*10**18;
    uint256 public maxSupplyBatch3 = 6270000*10**18;
    uint256 public maxSupplyPO = 8360000*10**18;



// Buy Method
    bytes32 public constant MATIC = keccak256("MATIC");
    bytes32 public constant PIX = keccak256("PIX");

//ENUM BACTH
    bytes32 public constant WL = keccak256("WL");
    bytes32 public constant BATCH2 =keccak256("BATCH2");
    bytes32 public constant BATCH3 = keccak256("BATCH3");
    bytes32 public constant PO = keccak256("PO");


//Flags
    bool public isP3;
    bool public isP2;
    bool public isPO;

//Informações da ordem
    struct Order {
        address account;
        uint256 tokens;
        bytes32 method;
        bytes32 batch;
    }

//Total MWP per address
    mapping (address => uint256) public totalValue;
//index de ordem
    mapping( uint => Order ) public Orders;

//Orders per address
    mapping(address => uint[]) public accountOrdens;

//WhiteList Address
    mapping(address => bool) public WhiteList;

//ROLES
    bytes32 public constant WITHDRAWROLE = keccak256("WITHDRAWROLE");
    bytes32 public constant BUYPIXROLE = keccak256("BUYPIXROLE");
    bytes32 public constant BUYORDERROLE = keccak256("BUYORDERROLE");
    bytes32 public constant SETERWHITELIST = keccak256("SETERWHITELIST");

    event WriteOrder(uint indexed index , address account, uint indexed tokens,string method, string batch);
    event FailWithdraw(uint256 indexed value, address sender);
    event ClainUserFailIndex(address account, uint256[] indexed orders, uint256 value);
    event InsufficientTokens(uint indexed vendorBalance, uint indexed totalValue);
    event writeWhiteList(address indexed account);
    event Claim(address indexed account, uint tokens);
//Constructor, cria interface token, seta roles
    constructor(address mwpAddress){
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _grantRole(WITHDRAWROLE, msg.sender);
    _grantRole(BUYPIXROLE, msg.sender);
    _grantRole(BUYORDERROLE, msg.sender);
    _grantRole(SETERWHITELIST, msg.sender);
    MWPToken = MentoraWellPlayedToken(mwpAddress);
    }

    modifier whiteListOnly(address _account){
        require(WhiteList[_account]==true, "Your Not in WhiteList");
        _;
    }

    function setWhiteList(address _account) public onlyRole(SETERWHITELIST){
        WhiteList[_account] = true;
        emit writeWhiteList(_account);
  }


// MWP per MATIC dependendo do bacth
    function tokenPerMatic(bytes32 batch) public view returns (int256){
    //Value in Dolar for 1 Matic
        int256 dol = getPriceMaticperDolar();
        int256 dolConv = dol *10**18;
        if(batch == WL){
            return dolConv/PriceBatch1;
        }
        else if(batch == BATCH2){
            return dolConv/PriceBatch2;
        }
        else if(batch == BATCH3){
            return dolConv/PriceBatch3;
        }
        else{
            return dolConv/PricePO;
        }
    }

//pricefortokens
    function Tokens(uint256 amount, bytes32 batch) public view returns(uint256){
    //Price * amount
        if (batch == WL){
            return amount * SafeCast.toUint256(tokenPerMatic(WL))/10**18;
        }
        else if(batch == BATCH2){
            return amount * SafeCast.toUint256(tokenPerMatic(BATCH2))/10**18;
        }
        else if(batch == BATCH3){
            return amount * SafeCast.toUint256(tokenPerMatic(BATCH3))/10**18;
        }
        else{
            return amount * SafeCast.toUint256(tokenPerMatic(PO))/10**18;
        }
    }
//AQUI ELE CALCULA A QUANTIDADE DE TOKENS
//Escreve Sold per Batch, order,  
    function writeOrder(address _account, uint256 _value, bytes32 _method, bytes32 _batch) public{
        uint _tokens = Tokens(_value, _batch);
        if(_batch == PIX){
            _tokens = _value;
        }
        Orders[index].account = _account;
        Orders[index].tokens = _tokens;
        Orders[index].method = _method;
        Orders[index].batch = _batch;
        //totalsold for account
        totalValue[_account] +=  _tokens;
        totalSold += _tokens;
        accountOrdens[_account].push(index);
        index++;
        //index da compra per account
        accountOrdens[_account].push(index);
        if(_batch == WL){
            totalSoldWL+= _tokens;
        }
        else if(_batch == BATCH2){
            totalSoldBatch2 += _tokens;
        }
        else if (_batch == BATCH3){
            totalSoldBatch3 += _tokens;
        }
        else if(_batch == PO){
            totalSoldPO += _tokens;
        }
        string memory _batchS = convertBatch(_batch);
        string memory _methodS = convertMethod(_method);
        emit WriteOrder(index-1,_account,_tokens,_batchS, _methodS);
    }

    function WTListOpen() public view returns(bool){
        if(totalSoldWL < maxSupplyWL){
            return true;
        }
        else{
            return false;
        }
    }

//Devolve qual bacth esta (nao leva em consideração WL)
    function Batch() public view returns(bytes32){
    //Checa todas as flags
        if(totalSoldBatch2 < maxSupplyBatch2){
            return BATCH2;
        }
        else if(totalSoldBatch3 < maxSupplyBatch3){
            return BATCH3;
        }
        else if(totalSoldBatch3 > maxSupplyBatch3){
            return PO;
        }
        else if(isPO){
            return PO;
        }
        else if(isP2){
            return BATCH2;
        }
        else if(isP3){
            return BATCH3;
        }
        else{
            return PO;
        }
    }

    function BuyTokens() public payable {
        if(WTListOpen() && WhiteList[msg.sender] == true){
            BuyTokensWL(msg.sender, msg.value, MATIC);
        }
        else{
            bytes32 batch = Batch();
            if(batch == BATCH2){
                BuyTokensBATCH2(msg.sender, msg.value, MATIC);
            }
            else if(batch == BATCH3){
                BuyTokensBATCH3(msg.sender, msg.value, MATIC);
            }
            else if(batch == PO){
                writeOrder(msg.sender, msg.value, MATIC, PO);
            }
        }
    }

    function BuyTokensBATCH2(address _account, uint256 _value, bytes32 _method) private{
        uint remains = maxSupplyBatch2 - totalSoldBatch2;
        if(msg.value > remains){
            uint256 nextBatch = _value - remains;
            writeOrder(_account, remains, _method, BATCH2);
            BuyTokensBATCH3(_account, nextBatch, _method);         
        }
        else{
            writeOrder(_account, _value, _method, BATCH2);
        }
    }

    function BuyTokensBATCH3(address _account, uint256 _value, bytes32 _method) private{
        uint remains = maxSupplyBatch3 - totalSoldBatch3;
        if(msg.value > remains){
            uint256 nextBatch = _value - remains;
            writeOrder(_account, remains, _method, BATCH3);
            writeOrder(_account, nextBatch,_method, PO);           
        }
        else{
            writeOrder(_account, _value, _method, BATCH3);
        }

    }
// Tanto para PIX e MATIC
    function BuyTokensWL(address _account, uint256 _value, bytes32 _method) public {
        //O que falta para o lote acabar
        uint remains = maxSupplyWL - totalSoldWL;
        //se o valor for maior
        if(_value > remains){
            uint256 nextBatch = _value - remains;
            writeOrder(_account, remains, _method, WL);
            BuyTokensBATCH2(_account, nextBatch, _method);
        }
        else{
            writeOrder(_account, _value, _method, WL);
        }
    }

    function BuyPix(address _account, uint256 _value) public onlyRole(BUYPIXROLE){

        if(WTListOpen() && WhiteList[_account]==true){
            BuyTokensWL(_account, _value, PIX);
        }
        else{
            bytes32 batch = Batch();
            if(batch == BATCH2){
                BuyTokensBATCH2(_account, _value, PIX);
            }
            else if(batch == BATCH3){
                BuyTokensBATCH3(_account, _value, PIX);
            }
            else if(batch == PO){
                writeOrder(_account, _value, MATIC, PIX);
            }
        }
    }

    function convertBatch(bytes32 _batch) public pure returns(string memory){
        if(_batch == WL){
            return("WL");
        }
        else if(_batch == BATCH2){
            return("BATCH2");
        }
        else if(_batch == BATCH3){
            return("BATCH3");
        }
        else if(_batch == PO){
            return("PO");
        }
        else{
            return("NO EXIST THIS BATCH");
        }
    }

    function convertMethod(bytes32 _method) public pure returns(string memory){
        if(_method == PIX){
            return("PIX");
        }
        if(_method == MATIC){
            return("MATIC");
        }
        else{
            return("NO EXIS THIS METHOD");
        }
    }

    function getTotalValue(address _account) public view returns (uint256) {
        return totalValue[_account];
    }
    function getAccountOrdens(address _account) public view returns (uint256[] memory){
        return accountOrdens[_account];
    }

    function getBalanceMPWContract() public view returns(uint256){
        uint256 vendorBalance = MWPToken.balanceOf(address(this));
        return vendorBalance;
    }


    function getOrdem(uint _index) public view returns (address,uint256, string memory,string memory){
      address account = Orders[_index].account;
      uint256 ammount = Orders[index].tokens;
      bytes32 _method = Orders[_index].method;
      bytes32 _batch = Orders[_index].batch;
      string memory batch = convertBatch(_batch);
      string memory method = convertMethod(_method);
      return (account, ammount, method, batch);
    }

    function isAddressInWhiteList(address account) public view returns (bool){
        return WhiteList[account];
    }

    function claim() public nonReentrant{
        uint256[] memory _orders = getAccountOrdens(msg.sender);
        // Check saldo MPW do contrato
        uint256 vendorBalance = MWPToken.balanceOf(address(this));
        //Checa saldo do usuario
        uint256 amountTokens = getTotalValue(msg.sender);
        //Se na for suficiente emit um evento
        if(vendorBalance >= vendorBalance){
            emit InsufficientTokens(vendorBalance,amountTokens);
        }
        require(vendorBalance >= vendorBalance, "Vendor contract has not enough tokens in its balance");        
        totalValue[msg.sender] = 0;
        (bool sent) = MWPToken.transfer(msg.sender, amountTokens);
        //Caso falhe lançar um evento
        if(sent == false){
            emit ClainUserFailIndex(msg.sender, _orders, amountTokens);
        }
        require(sent, "Failed to transfer token to user");
        emit Claim(msg.sender, amountTokens);
    }
    function withdraw() public onlyOwner onlyRole(WITHDRAWROLE){
        uint256 ownerBalance = address(this).balance;
        require(ownerBalance > 0, "Owner has not balance to withdraw");
        (bool sent,) = msg.sender.call{value: address(this).balance}("");
        if(sent == false){
            emit FailWithdraw(ownerBalance, msg.sender);
        }
        require(sent, "Failed to send user balance back to the owner");
  }


}