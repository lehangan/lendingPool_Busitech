// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

 
// StableToken
contract StableToken is Ownable, ERC20 {
    string private constant _symbol = "USD";                 // TODO: Give your token a symbol (all caps!)
    string private constant _name = "myUSD";                   // TODO: Give your token a name
    bool public callmint ;


    constructor() ERC20(_name, _symbol) {
        callmint = true;
    }

    // Function _mint: Create more of your tokens.
    // You can change the inputs, or the scope of your function, as needed.
    // Do not remove the AdminOnly modifier!
    function mint(uint amount, address user) 
        public 
        onlyOwner
    {
        /******* TODO: Implement this function *******/
        require( callmint == true , "Have been disable mint");
        _mint(user , amount);
    }

    // Function _disable_mint: Disable future minting of your token.
    // You can change the inputs, or the scope of your function, as needed.
    // Do not remove the AdminOnly modifier!
    function disable_mint()
        public
        onlyOwner
    {
        /******* TODO: Implement this function *******/
        callmint = false;
    }

}