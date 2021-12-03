// SPDX-License-Identifier: MIT
// This contract is drived from OpenZeppelin Contracts.

pragma solidity ^0.8.0;

import './ERC165.sol';
import './IERC165.sol';
import './IERC1155.sol';
import './IERC1155Receiver.sol';
import './IERC1155MetadataURI.sol';
import './Address.sol';
import './Context.sol';
import './Pausable.sol';
import './AccessControl.sol';
import './ERC1155Holder.sol';
import './Counters.sol';




/**
 * @dev Implementation of of the basic standard multi-token.
 * with adds-on features of pausing, burning, & minting tokens.
 * changes introduced to mint functions to fit QuestCrypto properties.
 * See ERC1155.sol, ERC1155Supply.sol, ERC1155PresetPresetMinterPauser.sol.
 */
 
contract PropertyToken is Context, ERC165, IERC1155, IERC1155MetadataURI, ERC1155Holder, Pausable, AccessControl {
    using Address for address;
    using Counters for Counters.Counter;
    Counters.Counter propertyIds;
  

    // Mapping from token ID to accounts and its balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    
    //Mapping from token ID to supply per token
    mapping(uint256 => uint256) private _totalSupply;
    
    //Mapping token Id to token price
    mapping(uint256=> uint256) private _tokensValue;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;


    
    //snapshot of tokens minted in each property
    struct Token{
        uint256 rightIdMinted;
        uint256 price;
    }
    
    
    //store propert info drived from javascript
    struct Property{
        bytes parentHash;
        address propertyAddress;
        Token[] tokens;
    }
    
    //Mapping property Id to data stored of each property
    mapping(uint256=> Property) public properties;

    //mapping(address=>mapping(uint256=>uint256)) _rightsOwner;
    
    uint256  private propertyId;
    
    address private rightsHolder = address(this);
    
    event PropertyAdded(uint256 propertyId, address owner, bytes MerkleTree);
    
    
    //solely responsible of minting and pausing tokens
    bytes32 public constant TREASURY_ROLE = keccak256("TREASURY_ROLE");
    
    uint256 public constant title = 1;
    uint256 public constant EQUITY_RIGHT = 2;
    uint256 public constant POSSESSION_RIGHT = 3;
    uint256 public constant MGMT_RIGHT = 4;
    uint256 public constant RENT_RIGHT = 5;
    uint256 public constant OCCUPANCY_RIGHT = 6;

    /**
     * @dev See {_setURI}.
     * 
     * @param uri_ is json that represent the  physical property as a whole "https://game.example/api/item/{id}.json"
     * @param treasury is the address responsible for minting & pausing tokens
     * 
     * DEFAULT_ADMIN_ROLE is HOA who deploys the contract and have absolute authority to grant & revoke roles
     */
    constructor(string memory uri_, address treasury, bytes memory _parentHash, address _propertyAddress) {
        _setURI(uri_);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TREASURY_ROLE, treasury);
    
        propertyIds.increment();
        propertyId= propertyIds.current();
        properties[propertyId].parentHash = _parentHash;
        properties[propertyId].propertyAddress = _propertyAddress;
        
        emit PropertyAdded(propertyId, _propertyAddress, _parentHash);
        
        _mint(rightsHolder, 1, 1, 0, "");
        properties[propertyId].tokens.push(Token(1, 0));
    }
    
    /**
     * @dev Pauses all token transfers.
     *
     * See {Pausable-_pause}.
     *
     * Requirements:
     *
     * - the caller must have the `TREASURY_ROLE`.
     */
    function pause() public {
        require(hasRole(TREASURY_ROLE, _msgSender()), "Quest: not allowed to pause");
        _pause();
    }

    /**
     * @dev Unpauses all token transfers.
     *
     * See {Pausable-_unpause}.
     *
     * Requirements:
     *
     * - the caller must have the `TREASURY_ROLE`.
     */
    function unpause() public {
        require(hasRole(TREASURY_ROLE, _msgSender()), "Quest: not allowed to unpause");
        _unpause();
    }
    

    /**
     * @dev See {IERC165-supportsInterface & IAccessControl}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165, ERC1155Receiver, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            interfaceId == type(ERC1155Receiver).interfaceId ||
            interfaceId == type(AccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view override returns (string memory) {
        return _uri;
    }
    
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view returns (uint256) {
        return _totalSupply[id];
    }
    
    /**
     * @dev Total amount of tokens in with a given id.
     */
    function tokensPrice(uint256 id) public view returns (uint256) {
        return _tokensValue[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view returns (bool) {
        return PropertyToken.totalSupply(id) > 0;
    }

    function getPropertyId() public view returns(uint256)  {
        return propertyId;
    }
    
    function getRightsOwner() public view returns(address) {
        return rightsHolder;
    }
    
    function mint_rights(uint256 id, uint256 price) public onlyRole(TREASURY_ROLE) {
        _mint(rightsHolder, id, 1, price, '');
        properties[propertyId].tokens.push(Token({rightIdMinted: id, price: price}));
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "Quest: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "Quest: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    function transferRights(address to, uint256 id, uint256 amount, uint256 price, bytes memory data) public {
        PropertyToken.safeTransferFrom(rightsHolder, to, id, amount, price, data);
       
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 price, 
        bytes memory data
    ) public virtual override whenNotPaused {
        require(
            from == address(this) || isApprovedForAll(from, _msgSender()),
            "Quest: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, price, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory prices,
        bytes memory data
    ) public virtual override whenNotPaused {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "Quest: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, prices, data);
    }
    

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 price,
        bytes memory data
    ) internal virtual whenNotPaused {
        require(to != address(0), "Quest: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), _asSingletonArray(price),data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Quest: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount, price);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, price, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory prices,
        bytes memory data
    ) internal virtual whenNotPaused {
        require(ids.length == amounts.length && ids.length == prices.length, "Quest: ids & amounts & values length mismatch");
        require(to != address(0), "Quest: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, prices, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];
    
    

            uint256 fromBalance = _balances[id][from];
        
            require(fromBalance >= amount, "Quest: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
              
            }
            _balances[id][to] += amount;
           
        }

        emit TransferBatch(operator, from, to, ids, amounts, prices);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, prices, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        uint256 price,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "Quest: mint to the zero address");
        require(!exists(id), "Quest: token already minted");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), _asSingletonArray(price), data);

        _balances[id][to] += amount;
        _tokensValue[id] += price;
        emit TransferSingle(operator, address(0), to, id, amount, price);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, price, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory prices,
        bytes memory data
    ) internal virtual whenNotPaused {
        require(to != address(0), "Quest: mint to the zero address");
        require(ids.length == amounts.length && ids.length  == prices.length, "Quest: ids & amounts & values length mismatch");
        require(hasRole(TREASURY_ROLE, _msgSender()), "Quest: not authorized to mint");


        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, prices, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
            _tokensValue[i] += prices[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts, prices);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, prices, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount,
        uint256 price
    ) internal virtual whenNotPaused {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), _asSingletonArray(price), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "Quest: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount, price);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory prices
    ) internal virtual whenNotPaused {
        require(from != address(0), "Quest: burn from the zero address");
        require(ids.length == amounts.length  && ids.length == prices.length, "Quest: ids & amounts & values length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, prices, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];


            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts, prices);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "Quest: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory prices,
        bytes memory data
    ) internal virtual {
        require(!paused(), "Quet: no transfer while paused");
        operator= msg.sender;
        data= data;
        
        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
                _tokensValue[ids[i]] += prices[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
                _tokensValue[ids[i]] += prices[i];
            }
        }
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        uint256 price,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, price, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("Quest: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Quest: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        uint256[] memory prices,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, prices, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("Quest: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("Quest: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}